-- PostgreSQL 12+
-- see general description in end of file

drop table if exists public.loop_execute_error;

-- необязательная таблица для записи исключений
create unlogged table public.loop_execute_error (
    id integer generated always as identity primary key,
    table_name regclass not null,
    uniq_column_name text not null,
    uniq_column_value_text text,
    uniq_column_value_bigint bigint,
    repeat_error_count bigint not null default 1,

    exception_sqlstate text not null check (octet_length(exception_sqlstate) = 5),
    exception_constraint_name text not null,
    exception_datatype_name text not null,

    exception_schema_name text not null,
    exception_table_name text not null,
    exception_column_name text not null,

    exception_message_text text not null,

    exception_detail text not null,
    exception_hint text not null,
    exception_context text not null,

    created_at timestamp(0) with time zone default now() not null check(created_at <= now() + interval '10m'),
    check (
           (uniq_column_value_text is not null and uniq_column_value_bigint is null)
        or (uniq_column_value_text is null and uniq_column_value_bigint is not null)
    )
);

comment on table public.loop_execute_error is 'Журнал исключений (ошибок) процедуры loop_execute()';

comment on column public.loop_execute_error.id is 'ID строки';
comment on column public.loop_execute_error.table_name is 'Название таблицы';
comment on column public.loop_execute_error.uniq_column_name is 'Название primary/unique колонки';
comment on column public.loop_execute_error.uniq_column_value_text is 'Значение текстовой колонки';
comment on column public.loop_execute_error.uniq_column_value_bigint is 'Значение числовой колонки';
comment on column public.loop_execute_error.repeat_error_count is 'Количество одинаковых ошибок';

comment on column public.loop_execute_error.exception_sqlstate is 'Код исключения, возвращаемый SQLSTATE';
comment on column public.loop_execute_error.exception_constraint_name is 'Имя ограничения целостности, относящегося к исключению';
comment on column public.loop_execute_error.exception_datatype_name is 'Имя типа данных, относящегося к исключению';

comment on column public.loop_execute_error.exception_schema_name is 'Имя схемы, относящейся к исключению';
comment on column public.loop_execute_error.exception_table_name is 'Имя таблицы, относящейся к исключению';
comment on column public.loop_execute_error.exception_column_name is 'Имя столбца, относящегося к исключению';

comment on column public.loop_execute_error.exception_message_text is 'Текст основного сообщения исключения';

comment on column public.loop_execute_error.exception_detail is 'Текст детального сообщения исключения (если есть)';
comment on column public.loop_execute_error.exception_hint is 'Текст подсказки к исключению (если есть)';
comment on column public.loop_execute_error.exception_context is 'Строки текста, описывающие стек вызовов в момент исключения';

comment on column public.loop_execute_error.created_at is 'Дата и время создания';

create unique index loop_execute_error_uniq on public.loop_execute_error(
    table_name, exception_schema_name, exception_table_name, exception_column_name, exception_sqlstate,
    exception_constraint_name, exception_datatype_name, cast(md5(exception_message_text) as uuid), cast(md5(exception_context) as uuid)
);

------------------------------------------------------------------------------------------------------------------------

create or replace procedure public.loop_execute(
    -- обязательные параметры:
    table_name  regclass, -- название основной таблицы (дополненное схемой через точку, при необходимости),
                          -- из которой данные порциями в цикле будут читаться и модифицироваться
    query text, -- CTE запрос с SELECT, INSERT/UPDATE/DELETE и SELECT запросами для модификации записей
                /*
                На каждой итерации цикла в следующие метки-заменители подставляются значения:
                  в $1 значение колонки с PK или UK индексом
                  в $2 ограничение LIMIT
                  в $3 ограничение OFFSET
                  в $4 дата-время с временной зоной (необязательная метка-заменитель) на момент следующей итерации цикла
                  в $5 дата-время с временной зоной (необязательная метка-заменитель) на момент запуска процедуры loop_execute()
                */
    -- необязательные параметры:
    total_query text default 'approx', -- метод вычисления количества строк в срезе таблицы, строки которой будут обработаны (используется для вычисления прогресса выполнения)
                                       -- если 'approx', то для всей таблицы автоматически вычисляется приблизительное значение на основе статистики, но быстро
                                       -- если 'exact', то для всей таблицы автоматически вычисляется точное значение, но медленно
                                       -- в остальных случаях это м.б. SQL запрос типа 'select count(*) from ... where ...'
                                          -- не используйте в этом запросе "тяжёлые" вычисления!
                                          -- обычно срез делают по дате-времени, пример: 'and updated_at between '2023-05-15' and  now()'
                                          -- если кол-во обработанных и прогнозируемух строк не совпадёт, то ошибки не будет
    disable_triggers boolean default false, -- That disables all triggers, include foreign keys. For the current database session only.
                                            -- Improves speed, saves from side effect. But superuser role required.
                                            -- Be careful to keep your database consistent!
    batch_rows integer default 1, -- стартовое значение, сколько записей будем модифицировать за 1 цикл (рекомендуется 1)
                                  -- на каждой итерации цикла значение автоматически подстраивается под max_duration
    max_duration numeric default 1, -- средняя длительность выполнения CTE запроса на каждой итерации цикла, в секундах, рекомендуется 1
                                    -- примерно столько времени CTE запрос может блокировать другие запросы на запись тех же ресурсов
                                    -- от значения этого параметра устанавливаются следующие ограничения:
                                    -- lock_timeout = max_duration * 1000 / 10
                                    -- lock_timeout -- это сколько времени CTE запрос будет ждать захвата блокировки строк на запись, возможно, блокируя другие запросы, образуя очередь запросов
                                    -- если происходит ошибка lock_timeout, batch_rows уменьшается и CTE запрос через некоторое время повторяется
                                    -- without lock_timeout CTE migration could block other writes WHILE TRYING to grab a lock on the resource (table/record/index/etc.)
    is_rollback boolean default false, -- откатывать запрос после каждого выполнения в цикле (для целей тестирования)
    max_cycles  integer default null, -- максимальное количество циклов (для целей тестирования при обработке больших таблиц)
                                      -- если null, то без ограничений
    error_table_name regclass default null, -- если указано, то процедура при выполнении CTE запроса в цикле
                                            -- не прерывает работу на первой ошибке, а сохраняет все ошибки в указанную таблицу
    check_query_plan_rows integer default 1e5, -- если total_table_rows > check_query_plan_rows,
                                               -- то проверять, чтобы план выполнения CTE запроса использовал PK или UK индекс
                                               -- нельзя допустить, чтобы CTE запрос выполнялся очень долго
    -- возвращаемые из процедуры параметры:
    inout result record default null
    /*
        result.table_rows     int     -- сколько всего записей в срезе таблицы
        result.affected_rows  int     -- сколько всего записей модифицировал пользовательский запрос в таблице
        result.processed_rows int     -- сколько всего записей просмотрел пользовательский запрос в таблице
        result.time_elapsed   numeric -- длительность выполнения, в секундах
    */
)
    language plpgsql
    -- set search_path = '' -- пока закомментировал из-за ошибки https://stackoverflow.com/questions/59159091/invalid-transaction-termination
as
$procedure$
DECLARE
    -- константы
    quote_regexp constant text not null default '([[\](){}.+*^$|\\?-])';  -- регулярное выражение для квотирования данных в регулярном выражении
    ident_regexp constant text not null default '(\m[a-zA-Z_]+[a-zA-Z_\d]*\M|"(?:[^"]|"")+")'; -- регулярное выражение для захвата названия SQL идентификатора (таблицы, колонки и др.)
    alias_regexp constant text not null default format('(\s*(\m[Aa][Ss]\M\s*)?%s)?', ident_regexp); -- регулярное выражение для захвата названия SQL необязательного псевдонима (таблицы, колонки и др.)
    query_type_regexp /*constant*/ text not null default '\m(?:(INSERT)\s+INTO(?:\s+ONLY)?|(UPDATE)(?:\s+ONLY)?|(DELETE)\s+FROM(?:\s+ONLY)?)\M'; -- часть рег. выражения для определения типа запроса, оно будет дополнено названием таблицы
    count_query      constant text not null default 'SELECT COUNT(*)            FROM %1$s WHERE %2$I > $1 AND %2$I <= $2'; -- SQL запрос для получения processed_rows
    count_query_spec constant text not null default 'SELECT COUNT(*), MAX(%2$I) FROM %1$s WHERE %2$I > $1 AND %2$I < $2'; -- SQL запрос для получения processed_rows (для query_canceled)
    last_subquery_exception_hint constant text not null default e'Last subquery must be:\nSELECT MAX(%I) AS stop_id, COUNT(*) AS affected_rows FROM ...';
    lock_timeout text not null default ceil(max_duration * 1000 / 10)::text;
    old_lock_timeout constant text not null default current_setting('lock_timeout');
    old_session_replication_role constant text not null default current_setting('session_replication_role');
    max_attempts constant smallint not null default 100;
    app_name constant text not null default regexp_replace(current_setting('application_name'), '\s*/\d+(?:\.\d+)?%', '');
    multiplier constant numeric not null default 2; -- not integer!

    -- статистика
    total_time_start timestamptz not null default clock_timestamp();
    total_time_elapsed numeric not null default 0; -- длительность выполнения всех запросов, в секундах
    total_affected_rows int not null default 0; -- сколько всего записей модифицировал пользовательский запрос в таблице
    total_processed_rows int not null default 0; -- сколько всего записей просмотрел пользовательский запрос в таблице
    total_table_rows integer default 0; -- сколько всего записей в таблице (для вычисления прогресса выполнения)
    estimated_time interval; -- оценочное время, сколько осталось работать
    rows_per_second numeric default 0;
    queries_per_second numeric default 0;
    cycles int not null default 0; -- счётчик для цикла
    is_calc_estimated_time boolean not null default false;
    progress numeric not null default 0;
    app_name_new text not null default '';

    -- свойства таблицы table_name:
    table_name_regexp text; -- рег. выражение для названия таблицы (которое м.б. квотировано) с необязательной схемой
    uniq_column_name_regexp text; -- рег. выражении для названия primary/unique колонки (которое м.б. квотировано) с необязательной таблицей
    uniq_column_name text; -- название primary/unique колонки
    uniq_column_type text; -- тип primary/unique колонки
    uniq_index_names text[];  -- название индексов primary/unique колонок

    -- для пользовательского CTE запроса query, выполняемого в цикле:
    start_id_bigint bigint not null default 0;
    start_id_text text not null default '';
    stop_id_bigint bigint;
    stop_id_text text;
    offset_rows int not null default 0;
    affected_rows bigint not null default 0; -- сколько записей модифицировал пользовательский запрос
    processed_rows bigint not null default 0; -- сколько записей просмотрел пользовательский запрос
    query_time_start timestamptz;
    query_time_elapsed numeric not null default 0; -- длительность выполнения одного запроса, в секундах
    query_type text; -- тип запроса: INSERT/UPDATE/DELETE
    query_explain_nodes jsonb;
    query_explain_path jsonpath;
    has_bad_query_plan boolean not null default false;
    max_batch_rows integer not null default 0;
    attempts_time_start timestamptz;
    time_elapsed numeric not null default 0;
    delay numeric; -- задержка в секундах при возникновении блокировок
    is_superuser boolean not null default false;

    -- для исключений
    exception_sqlstate        text; -- код исключения, возвращаемый SQLSTATE
    exception_column_name     text; -- имя столбца, относящегося к исключению
    exception_constraint_name text; -- имя ограничения целостности, относящегося к исключению
    exception_datatype_name   text; -- имя типа данных, относящегося к исключению
    exception_message_text    text; -- текст основного сообщения исключения
    exception_table_name      text; -- имя таблицы, относящейся к исключению
    exception_schema_name     text; -- имя схемы, относящейся к исключению
    exception_detail          text; -- текст детального сообщения исключения (если есть)
    exception_hint            text; -- текст подсказки к исключению (если есть)
    exception_context         text; -- строки текста, описывающие стек вызовов в момент исключения (см. Подраздел 42.6.9)
BEGIN

    -- 1) проверка входящих параметров
    IF current_setting('server_version_num') < '120000' THEN
        RAISE EXCEPTION 'PostgreSQL 12+ required!';
    ELSIF table_name IS NULL OR
        query IS NULL OR
        total_query IS NULL OR
        batch_rows IS NULL OR
        max_duration IS NULL OR
        is_rollback IS NULL OR
        check_query_plan_rows IS NULL
    THEN
        RAISE EXCEPTION 'Procedure arguments must not have NULL values (except max_cycles)!';
    ELSIF batch_rows not between 1 AND 1024 THEN
        RAISE EXCEPTION 'Argument batch_rows must between 1 and 1024, but % given', batch_rows;
    ELSIF max_duration not between 1 AND 10 THEN
        RAISE EXCEPTION 'Argument max_duration must between 1 and 10, but % given', max_duration;
    ELSIF max_cycles < 0 THEN
        RAISE EXCEPTION 'Argument max_cycles must be >= 0, but % given', max_cycles;
    ELSIF check_query_plan_rows < 1000 THEN
        RAISE EXCEPTION 'Argument check_query_plan_rows must be >= 1000, but % given', check_query_plan_rows;
    END IF;

    SELECT null::int as table_rows,
           null::int as affected_rows,
           null::int as processed_rows,
           null::numeric as time_elapsed
      INTO result;

    -- 2) проверка наличия not null уникального ключа
    -- https://stackoverflow.com/questions/2204058/list-columns-with-indexes-in-postgresql
    WITH u AS (
        -- сначала получим первичный или уникальный индекс
        SELECT a.attname,
               z.col_type,
               i.relname,
               t.oid
        FROM
            pg_class AS t,
            pg_class AS i,
            pg_index AS ix,
            pg_attribute AS a,
            pg_namespace AS n,
            format_type(a.atttypid, a.atttypmod) as z(col_type)
        WHERE true
          AND t.oid = loop_execute.table_name
          AND ix.indisunique
          AND ix.indrelid = t.oid
          AND ix.indexrelid = i.oid
          AND cardinality(ix.indkey) = 1 -- one column in index
          AND t.relnamespace = n.oid
          AND a.attrelid = t.oid
          AND a.attnum = any(ix.indkey)
          AND a.attnotnull
        ORDER BY ix.indisprimary DESC -- primary key in priority
        LIMIT 1
    )
    -- select * from u; -- test
    -- колонка из первичного или уникального индекса может быть частью другого составного индекса, который м.б. неуникальным (да, это выглядит нелогично)!
    SELECT a.attname,
           z.col_type,
           array_agg(i.relname ORDER BY ix.indisprimary DESC)
    INTO uniq_column_name, uniq_column_type, uniq_index_names
    FROM
        pg_class AS t,
        pg_class AS i,
        pg_index AS ix,
        pg_attribute AS a,
        pg_namespace AS n,
        format_type(a.atttypid, a.atttypmod) as z(col_type),
        u
    WHERE true
      AND t.oid = u.oid
      AND a.attname = u.attname
      AND z.col_type = u.col_type
      AND ix.indrelid = t.oid
      AND ix.indexrelid = i.oid
      AND t.relnamespace = n.oid
      AND a.attrelid = t.oid
      AND a.attnum = any(ix.indkey)
      AND a.attnotnull
      AND array_position((ix.indkey)[:], a.attnum) = 1 --https://stackoverflow.com/questions/69649737/postgres-array-positionarray-element-sometimes-0-indexed
    GROUP BY
        a.attname,
        z.col_type
    LIMIT 1;

    IF uniq_index_names IS NULL THEN
        RAISE EXCEPTION 'Table % must has a column with primary/unique not null index!', table_name;
    END IF;

    IF uniq_column_type !~* '\m(integer|bigint|varying|character|text|char|varchar)\M' THEN
        RAISE EXCEPTION 'Column %.% has unsupported type %', table_name, uniq_column_name, uniq_column_type
             USING HINT = 'You can add support by modify procedure :-)';
    END IF;

    -- 3) проверка необходимых частей в CTE запросе, в т.ч. защита от дурака
    -- при преобразовании типа из regclass в text, функция quote_ident() вызывается автоматически
    select string_agg(t3.s, '\.' order by t1.o)
    into table_name_regexp
    from unnest(string_to_array(loop_execute.table_name::text, '.')) with ordinality as t1(s, o)
    cross join regexp_replace(t1.s, quote_regexp, '\\\1', 'g') as t2(s) -- квотируем
    cross join concat('(?:\m|(?="))', t2.s, '(?:\M|(?<="))') as t3(s);

    query_type_regexp := concat(query_type_regexp, '\s+', '(?:', ident_regexp, '\.)?', table_name_regexp);
    query_type        := upper((array_remove(
                             regexp_match(query, query_type_regexp, 'i'),
                             null
                         ))[1]);

    IF coalesce(query_type, '') not in ('INSERT', 'UPDATE', 'DELETE') THEN
        -- RAISE NOTICE 'query_type_regexp = %', query_type_regexp; -- debug
        RAISE EXCEPTION 'Unknown CTE query type or table % is not found in your CTE query!', table_name
             USING HINT = format('Check that CTE query has an INSERT/UPDATE/DELETE subquery with table name %I', table_name::text);
    END IF;

    uniq_column_name_regexp := concat('(?:', ident_regexp, '\.)?',
                                      '(?:\m|(?="))',
                                      regexp_replace(quote_ident(uniq_column_name), quote_regexp, '\\\1', 'g'), -- квотируем
                                      '(?:\M|(?<="))');
    IF query !~* format('%s\s*>\s*\$1\M', uniq_column_name_regexp) THEN
        RAISE EXCEPTION 'Entry "% > $1" is not found in your CTE query!', quote_ident(uniq_column_name)
            USING HINT = format('Add "%I > $1" to WHERE clause of SELECT subquery.', uniq_column_name);
    ELSIF query !~* format('\mORDER\s+BY\s*%s(?!\s*\mDESC\M)', uniq_column_name_regexp) THEN
        RAISE EXCEPTION 'Entry "ORDER BY %" is not found in your CTE query!', quote_ident(uniq_column_name)
            USING HINT = format('Add "ORDER BY %I ASC" to end of SELECT subquery.', uniq_column_name);
    ELSIF query !~* '\mLIMIT\s+\$2\M' THEN
        RAISE EXCEPTION 'Entry "LIMIT $2" is not found in your CTE query!'
            USING HINT = 'Add "LIMIT $2" to end of SELECT subquery.';
    ELSIF query !~* '\mOFFSET\s+\$3\M' THEN
        RAISE EXCEPTION 'Entry "OFFSET $3" is not found in your CTE query!'
            USING HINT = 'Add "OFFSET $3" to end of SELECT subquery.';
    ELSIF regexp_match(query,
                       format($regexp$
                                  \mSELECT \s+
                                      MAX   \s* \( \s* %1$s \s* \)  %2$s  \s*,\s*
                                      COUNT \s* \( \s* \*   \s* \)  %2$s  \s*
                                  \mFROM\M \s* %1$s %2$s \s* (;\s*)? $
                              $regexp$, ident_regexp, alias_regexp), 'ix') is null THEN
        RAISE EXCEPTION 'Incorrect last subquery in your CTE query!'
            USING HINT = format(last_subquery_exception_hint, uniq_column_name);
    END IF;

    -- 4) подсчёт общего кол-ва записей в срезе таблицы
    query_time_start := clock_timestamp();
    IF total_query not in ('approx', 'exact') THEN

        IF total_query !~* table_name_regexp THEN
            RAISE EXCEPTION 'Incorrect total query!'
                USING HINT = format('Does total query has table name %I ?', table_name::text);
        END IF;

        RAISE NOTICE 'Calculating total rows for table % from total query ...', table_name;
        EXECUTE total_query USING null, null, null, clock_timestamp(), total_time_start INTO STRICT total_table_rows;
    ELSE

        IF total_query = 'approx' THEN
            RAISE NOTICE 'Calculating approximate (estimate) total rows for table % ...', table_name;
            select t.reltuples::bigint into strict total_table_rows
            from pg_class as t
            where t.oid = loop_execute.table_name;
        END IF;

        IF total_table_rows <= 0 THEN
            RAISE NOTICE 'Calculating exact total rows for table % ...', table_name;
            EXECUTE format('SELECT COUNT(*) FROM %1$s', table_name) INTO STRICT total_table_rows;
        END IF;

    END IF;

    query_time_elapsed := round(extract('epoch' from clock_timestamp() - query_time_start)::numeric, 2);
    total_time_elapsed := round(extract('epoch' from clock_timestamp() - total_time_start)::numeric, 2);

    result.table_rows   := total_table_rows;
    result.time_elapsed := total_time_elapsed;

    RAISE NOTICE 'Done. % total rows found for % sec', total_table_rows, query_time_elapsed;
    RAISE NOTICE ' '; -- just new line

    IF total_table_rows = 0 THEN
        RETURN;
    END IF;

    -- 5) отключение триггеров и FK
    IF disable_triggers THEN
        SELECT r.rolsuper INTO is_superuser FROM pg_roles AS r WHERE r.rolname = CURRENT_USER;
        IF NOT is_superuser THEN
            RAISE EXCEPTION 'To disable triggers and foreign keys superuser role required!';
        END IF;
    END IF;

    -- 6) выполняем CTE запрос в цикле
    LOOP
        EXIT WHEN cycles >= max_cycles;
        cycles := cycles + 1;

        PERFORM set_config('lock_timeout', lock_timeout, true);
        /*
        -- statement_timeout does not work inside PLpgSQL:
        do $$ begin set local statement_timeout to '1s'; perform pg_sleep(2); end;$$;
        -- statement_timeout works inside SQL:
        begin; set local statement_timeout to '1s'; select pg_sleep(2); commit;
        -- TODO use dblink to workаround?
        */

        IF disable_triggers THEN
            set local session_replication_role = 'replica';
        END IF;

        -- проверяем, чтобы план выполнения CTE запроса использовал PK или UK индекс
        -- нельзя допустить, чтобы CTE запрос выполнялся очень долго
        LOOP
            EXIT WHEN total_table_rows <= check_query_plan_rows OR max_batch_rows >= batch_rows;

            IF uniq_column_type IN ('integer', 'bigint') THEN
                RAISE NOTICE 'CTE query execution plan check using: $1 := %, $2 := %, $3 := %', start_id_bigint, batch_rows, offset_rows;
                EXECUTE concat('EXPLAIN (FORMAT JSON) ', query)
                    USING start_id_bigint, batch_rows, offset_rows, clock_timestamp(), total_time_start INTO query_explain_nodes;
            ELSE
                RAISE NOTICE 'CTE query execution plan check using: $1 := %, $2 := %, $3 := %', quote_literal(start_id_text), batch_rows, offset_rows;
                EXECUTE concat('EXPLAIN (FORMAT JSON) ', query)
                    USING start_id_text, batch_rows, offset_rows, clock_timestamp(), total_time_start INTO query_explain_nodes;
            END IF;

            IF query_explain_path IS NULL THEN
                -- JSONPath syntax
                -- https://postgrespro.ru/docs/postgresql/14/functions-json#FUNCTIONS-SQLJSON-PATH
                -- https://habr.com/ru/company/postgrespro/blog/448612/
                query_explain_path := format($$  $.** ? (@."Relation Name" == "%s")
                                                      ? (@."Node Type" == "Index Scan" || @."Node Type" == "Index Only Scan")
                                                      ? (%s)
                                             $$,
                                             to_json(string_to_array(table_name::text, '.'))->>-1/*получаем только название таблицы без схемы*/,
                                             (select string_agg(concat('@."Index Name" == "', t.n, '"'), ' || ') from unnest(uniq_index_names) as t(n))
                                            )::jsonpath;
            END IF;

            IF query_explain_nodes @? query_explain_path THEN
                RAISE NOTICE 'CTE query execution plan is OK';
                max_batch_rows := batch_rows;
                EXIT; -- выходим из LOOP
            END IF;

            has_bad_query_plan := true;
            batch_rows := ceil(batch_rows / multiplier);

            IF batch_rows = 1 THEN
                RAISE WARNING 'CTE query explain nodes:';
                RAISE WARNING '%', query_explain_nodes;

                RAISE WARNING 'Target node is not found in explain for jsonpath:';
                RAISE WARNING '%', query_explain_path;

                RAISE EXCEPTION 'Bad CTE query execution plan detected!'
                     USING HINT = format('Try to run VACUUM ANALYZE %s', quote_ident(table_name::text));
            ELSE
                RAISE WARNING 'Bad CTE query execution plan detected!'
                   USING HINT = format('Try to run VACUUM ANALYZE %s', quote_ident(table_name::text));
            END IF;
        END LOOP;

        attempts_time_start := clock_timestamp();
        FOR cur_attempt IN 1..max_attempts LOOP
            BEGIN -- subtransaction SAVEPOINT

                query_time_start := clock_timestamp();
                affected_rows  := 0;
                processed_rows := 0;

                IF uniq_column_type IN ('integer', 'bigint') THEN
                    start_id_bigint := coalesce(stop_id_bigint, start_id_bigint);
                    EXECUTE query USING start_id_bigint, batch_rows, offset_rows, clock_timestamp(), total_time_start INTO STRICT stop_id_bigint, affected_rows;
                    IF start_id_bigint >= stop_id_bigint THEN
                        RAISE EXCEPTION 'Infinity cycle has been found (start_id=% >= stop_id=%)! There are mistake in your CTE query.',
                            start_id_bigint, stop_id_bigint
                            USING HINT = format(last_subquery_exception_hint, uniq_column_name);
                    ELSIF stop_id_bigint IS NOT NULL THEN
                        EXECUTE format(count_query, table_name, uniq_column_name) USING start_id_bigint, stop_id_bigint INTO processed_rows;
                    END IF;
                ELSE
                    start_id_text := coalesce(stop_id_text, start_id_text);
                    EXECUTE query USING start_id_text, batch_rows, offset_rows, clock_timestamp(), total_time_start INTO STRICT stop_id_text, affected_rows;
                    IF start_id_text >= stop_id_text THEN
                        RAISE EXCEPTION 'Infinity cycle has been found (start_id=% >= stop_id=%)! There are mistake in your CTE query.',
                            quote_literal(start_id_text), quote_literal(stop_id_text)
                            USING HINT = format(last_subquery_exception_hint, uniq_column_name);
                    ELSIF stop_id_text IS NOT NULL THEN
                        EXECUTE format(count_query, table_name, uniq_column_name) USING start_id_text, stop_id_text INTO processed_rows;
                    END IF;
                END IF;

                IF query_type = 'DELETE' THEN
                    processed_rows := affected_rows + processed_rows;
                END IF;

                offset_rows := 0;
                EXIT; -- запрос выполнился успешно, выходим из цикла FOR ... LOOP

            EXCEPTION -- subtransaction ROLLBACK TO SAVEPOINT
                WHEN lock_not_available /*55P03*/ THEN
                    IF cur_attempt < max_attempts THEN
                        batch_rows := ceil(batch_rows / multiplier);
                        time_elapsed := round(extract('epoch' from clock_timestamp() - attempts_time_start)::numeric, 2);
                        delay := round(greatest(sqrt(time_elapsed * max_duration), max_duration), 2);
                        delay := round(((random() * (delay - max_duration)) + max_duration)::numeric, 2);
                        RAISE WARNING 'Attempt % of % to execute CTE query failed due lock_timeout = %, next replay after % s',
                            cur_attempt, max_attempts, current_setting('lock_timeout'), delay;
                        PERFORM pg_sleep(delay);
                    ELSE
                        RAISE WARNING 'Attempt % of % to execute CTE query failed due lock_timeout = %',
                            cur_attempt, max_attempts, current_setting('lock_timeout');
                        RAISE; -- raise the original exception
                    END IF;
                WHEN query_canceled /*57014*/ THEN
                    GET STACKED DIAGNOSTICS
                        exception_sqlstate     := RETURNED_SQLSTATE,   -- text код исключения, возвращаемый SQLSTATE
                        exception_message_text := MESSAGE_TEXT,        -- text текст основного сообщения исключения
                        exception_detail       := PG_EXCEPTION_DETAIL, -- text текст детального сообщения исключения (если есть)
                        exception_hint         := PG_EXCEPTION_HINT;   -- text текст подсказки к исключению (если есть)

                    IF exception_message_text !~* '\m(query cancelled by timeout|scan_timeout)\M' THEN
                        RAISE; -- raise the original exception
                    END IF;

                    IF uniq_column_type IN ('integer', 'bigint') THEN
                        RAISE WARNING 'Catched ERROR % of execute CTE query using: $1 := %, $2 := %, $3 := %', exception_sqlstate, start_id_bigint, batch_rows, offset_rows;
                    ELSE
                        RAISE WARNING 'Catched ERROR % of execute CTE query using: $1 := %, $2 := %, $3 := %', exception_sqlstate, quote_literal(start_id_text), batch_rows, offset_rows;
                    END IF;

                    IF batch_rows > 1 THEN
                        batch_rows := ceil(batch_rows / multiplier);
                        CONTINUE;
                    ELSIF uniq_column_type IN ('integer', 'bigint') THEN
                        -- на этом id в raise_exception() было брошено исключение 'query_canceled'
                        stop_id_bigint := ((exception_detail::jsonb)->>'id')::bigint;
                        -- поэтому последний stop_id_bigint будет перед ним
                        EXECUTE format(count_query_spec, table_name, uniq_column_name)
                            USING start_id_bigint, stop_id_bigint INTO processed_rows, stop_id_bigint;
                        IF start_id_bigint >= stop_id_bigint THEN
                            RAISE EXCEPTION 'Infinity cycle has been found (start_id=% >= stop_id=%)!',
                                start_id_bigint, stop_id_bigint
                                USING HINT = format(last_subquery_exception_hint, uniq_column_name);
                        END IF;
                    ELSE
                        stop_id_text := ((exception_detail::jsonb)->>'id')::text;
                        EXECUTE format(count_query_spec, table_name, uniq_column_name)
                            USING start_id_text, stop_id_text INTO processed_rows, stop_id_text;
                        IF start_id_text >= stop_id_text THEN
                            RAISE EXCEPTION 'Infinity cycle has been found (start_id=% >= stop_id=%)!',
                                quote_literal(start_id_text), quote_literal(stop_id_text)
                                USING HINT = format(last_subquery_exception_hint, uniq_column_name);
                        END IF;
                    END IF;

                    affected_rows := 0;
                    EXIT; -- считаем, что часть запроса выполнилась успешно, выходим из цикла FOR ... LOOP

                -- ошибки ограничения уникальности, максимальной длины полей и другие
                WHEN others /*все типы ошибок, кроме QUERY_CANCELED и ASSERT_FAILURE*/ THEN
                    GET STACKED DIAGNOSTICS
                        exception_sqlstate        := RETURNED_SQLSTATE,	-- text	код исключения, возвращаемый SQLSTATE
                        exception_column_name     := COLUMN_NAME,       -- text имя столбца, относящегося к исключению
                        exception_constraint_name := CONSTRAINT_NAME,   -- text имя ограничения целостности, относящегося к исключению
                        exception_datatype_name   := PG_DATATYPE_NAME,  -- text имя типа данных, относящегося к исключению
                        exception_message_text    := MESSAGE_TEXT,      -- text текст основного сообщения исключения
                        exception_table_name      := TABLE_NAME,        -- text имя таблицы, относящейся к исключению
                        exception_schema_name     := SCHEMA_NAME,       -- text имя схемы, относящейся к исключению
                        exception_detail          := PG_EXCEPTION_DETAIL,  -- text текст детального сообщения исключения (если есть)
                        exception_hint            := PG_EXCEPTION_HINT,    -- text текст подсказки к исключению (если есть)
                        exception_context         := PG_EXCEPTION_CONTEXT; -- text строки текста, описывающие стек вызовов в момент исключения (см. Подраздел 42.6.9)

                    IF uniq_column_type IN ('integer', 'bigint') THEN
                        RAISE WARNING 'Catched ERROR % of execute CTE query using: $1 := %, $2 := %, $3 := %', exception_sqlstate, start_id_bigint, batch_rows, offset_rows;
                    ELSE
                        RAISE WARNING 'Catched ERROR % of execute CTE query using: $1 := %, $2 := %, $3 := %', exception_sqlstate, quote_literal(start_id_text), batch_rows, offset_rows;
                    END IF;

                    IF exception_sqlstate ~ '^42' /*Класс 42 — Ошибка синтаксиса или нарушение правила доступа*/ THEN
                        RAISE; -- raise the original exception
                    END IF;

                    IF cur_attempt = max_attempts THEN
                        RAISE WARNING 'Attempt % of % reached!', cur_attempt, max_attempts;
                        RAISE; -- raise the original exception
                    ELSIF batch_rows > 1 THEN
                        -- позиционируемся на проблемную запись
                        batch_rows := ceil(batch_rows / multiplier);
                    ELSIF error_table_name IS NULL THEN
                        EXIT; -- выходим из цикла FOR ... LOOP
                    ELSE
                        EXECUTE replace($$
                            INSERT INTO :error_table_name as t (
                                table_name, uniq_column_name, uniq_column_value_text, uniq_column_value_bigint,
                                exception_sqlstate,
                                exception_column_name,
                                exception_constraint_name,
                                exception_datatype_name,
                                exception_message_text,
                                exception_table_name,
                                exception_schema_name,
                                exception_detail,
                                exception_hint,
                                exception_context
                            ) SELECT $1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14
                            ON CONFLICT (
                                -- see unique index "loop_execute_error_uniq"
                                table_name, exception_schema_name, exception_table_name, exception_column_name, exception_sqlstate,
                                exception_constraint_name, exception_datatype_name, cast(md5(exception_message_text) as uuid), cast(md5(exception_context) as uuid)
                            )
                            DO UPDATE SET repeat_error_count = t.repeat_error_count + 1
                            $$, ':error_table_name', error_table_name::text)
                            USING table_name::text,
                                uniq_column_name,
                                case when uniq_column_type ~* '\m(varying|character|text|char|varchar)\M' then start_id_text end,
                                case when uniq_column_type IN ('integer', 'bigint') then start_id_bigint end,
                                exception_sqlstate,
                                exception_column_name,
                                exception_constraint_name,
                                exception_datatype_name,
                                exception_message_text,
                                exception_table_name,
                                exception_schema_name,
                                exception_detail,
                                exception_hint,
                                exception_context;

                        COMMIT AND CHAIN;

                        /*
                           1) Уникальные индексы могут стать неуникальными из-за ошибок а самой БД
                           2) Если уникальные индексы вычисляются как хеш (например md5), то в хешах возможны коллизии.
                           3) Могут сработать ограничения таблицах, колонках или в функциях, которые использует SQL запрос.
                           Поэтому пытаемся пропустить проблемные записи и перейти к следующим.
                           Если параметр error_table_name передан, то ошибки будут записаны в служебную таблицу
                        */
                        offset_rows := offset_rows + 1;
                    END IF;

            END; -- subtransaction BEGIN/EXCEPTION/END

        END LOOP; -- FOR LOOP

        IF is_rollback THEN
            ROLLBACK AND CHAIN;
        ELSE
            COMMIT AND CHAIN; -- https://www.postgresql.org/docs/12/plpgsql-transactions.html
        END IF;

        query_time_elapsed := round(extract('epoch' from clock_timestamp() - query_time_start)::numeric, 2);
        total_time_elapsed := round(extract('epoch' from clock_timestamp() - total_time_start)::numeric, 2);

        total_affected_rows  := total_affected_rows  + affected_rows;
        total_processed_rows := total_processed_rows + processed_rows;

        IF total_processed_rows > total_table_rows THEN
            -- корректируем значения в случае приблизительного вычисления кол-ва строк в таблице
            total_table_rows  := total_processed_rows;
            result.table_rows := total_table_rows;
        END IF;

        result.time_elapsed   := total_time_elapsed;
        result.affected_rows  := total_affected_rows;
        result.processed_rows := total_processed_rows;

        is_calc_estimated_time := not is_calc_estimated_time and (cycles > 10 or (query_time_elapsed > max_duration and cycles > 4));
        IF is_calc_estimated_time THEN
            estimated_time := (ceil(total_table_rows * total_time_elapsed / total_processed_rows - total_time_elapsed)::text || 's')::interval;
        END IF;
        progress := round(total_processed_rows * 100.0 / total_table_rows, 2);

        RAISE NOTICE 'Query %: affected % rows, processed % rows, elapsed % sec%',
            cycles, affected_rows, processed_rows,
            query_time_elapsed, case when is_rollback then ', ROLLBACK MODE!' else '' end;

        RAISE NOTICE 'Using: $1 := %, $2 := %, $3 := %', case when uniq_column_type in ('integer', 'bigint') then start_id_bigint::text
                                                                    else quote_literal(start_id_text)
                                                               end, batch_rows, offset_rows;

        RAISE NOTICE 'Total: affected % rows, processed % rows', total_affected_rows, total_processed_rows;
        RAISE NOTICE 'Current datetime: %, elapsed time: %, estimated time: %, progress: % %%',
            clock_timestamp()::timestamptz(0),
            (clock_timestamp() - total_time_start)::interval(0),
            COALESCE(estimated_time::text, '?'),
            progress;
        RAISE NOTICE ' '; -- just new line

        app_name_new := concat(app_name, ' /', progress, '%');
        if octet_length(app_name_new) < 64 then
            PERFORM set_config('application_name', app_name_new, true);
        end if;

        EXIT WHEN processed_rows = 0;

        IF query_time_elapsed <= max_duration THEN
            -- увеличиваем значение
            batch_rows := case when query_time_elapsed = 0 then batch_rows * multiplier -- protect division by zero below
                               else least(ceil(batch_rows * max_duration / query_time_elapsed), batch_rows * multiplier)
                          end;
            if has_bad_query_plan and batch_rows > max_batch_rows then
                batch_rows := max_batch_rows;
            end if;
        ELSIF batch_rows > 1 THEN
            -- уменьшаем значение
            batch_rows := greatest(ceil(batch_rows * max_duration / query_time_elapsed), ceil(batch_rows / multiplier));
        ELSIF affected_rows > 0 THEN
            delay := round(greatest(sqrt(query_time_elapsed * max_duration) - max_duration, 0), 2);
            RAISE WARNING 'Try to save DB from overload, next replay after % s', delay;
            PERFORM pg_sleep(delay);
        END IF;

    END LOOP;

    IF total_time_elapsed > 0 THEN
        rows_per_second    := ceil(total_processed_rows / total_time_elapsed);
        queries_per_second := round(cycles / total_time_elapsed, 2);
    END IF;

    RAISE NOTICE 'Done. % rows per second, % queries per second', rows_per_second, queries_per_second;

    IF disable_triggers THEN
        PERFORM set_config('session_replication_role', old_session_replication_role, true);
    END IF;

    PERFORM set_config('lock_timeout', old_lock_timeout, true);

END
$procedure$;

comment on procedure public.loop_execute(
    -- обязательные параметры:
    table_name  regclass,
    query       text,
    -- необязательные параметры:
    total_query text,
    disable_triggers boolean,
    batch_rows  integer,
    max_duration    numeric,
    is_rollback boolean,
    max_cycles  integer,
    exception_table_name regclass,
    check_query_plan_rows integer,
    -- возвращаемые из процедуры параметры:
    inout result record
) is $$
Safely modifies millions of rows in a table.

Update or delete rows incrementally in batches with multiple separate transactions.
This maximizes your table availability since you only need to keep locks for a short period of time. Also allows dead rows to be reused.
There is a progress of execution in percent and a prediction of the end work time!

Процедура для обработки строк в больших таблицах (тысячи и миллионы строк) с контролируемым временем блокировки строк на запись.
Принцип работы — выполняет в цикле CTE DML запрос, который добавляет, обновляет или удаляет записи в таблице.
В завершении каждого цикла изменения фиксируются (либо откатываются для целей тестирования, это настраивается).
Автоматически адаптируется под нагрузку на БД. На реплику данные передаются постепенно небольшими порциями, а не одним огромным куском.
В процессе обработки показывает в psql консоли:
   * количество модифицированных и обработанных записей в таблице
   * сколько времени прошло, сколько примерно времени осталось до завершения, прогресс выполнения в процентах
Прогресс выполнения в процентах для работающего процесса отображается ещё в колонке pg_stat_activity.application_name!
Процедура не предназначена для выполнения в транзакции, т.к. сама делает много маленьких транзакций.
$$;
