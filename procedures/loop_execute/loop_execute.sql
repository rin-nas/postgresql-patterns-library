--PostgreSQL 12+

drop table if exists loop_execute_error;

-- необязательная таблица для записи исключений
create unlogged table loop_execute_error (
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
    ),
    constraint loop_execute_error_uniq unique (table_name,
                                               exception_schema_name, exception_table_name, exception_column_name,
                                               exception_sqlstate, exception_constraint_name, exception_datatype_name,
                                               exception_message_text)
);

------------------------------------------------------------------------------------------------------------------------

create or replace procedure loop_execute(
    --обязательные параметры:
    table_name  regclass, -- название основной таблицы (дополненное схемой через точку, при необходимости),
                          -- из которой данные порциями в цикле будут читаться и модифицироваться
    query       text, -- CTE запрос с SELECT, INSERT/UPDATE/DELETE и SELECT запросами для модификации записей
    --необязательные параметры:
    is_disable_triggers boolean default false, -- That disables all triggers, include foreign keys. For the current database session only.
                                               -- Improves speed, saves from side effect. But superuser role required.
                                               -- Be careful to keep your database consistent!
    batch_rows  integer default 1, -- стартовое значение, сколько записей будем модифицировать за 1 цикл (рекомендуется 1)
                                   -- значение автоматически подстраивается под time_max
    time_max    numeric default 1, -- средняя длительность выполнения CTE запроса на каждой итерации цикла, в секундах, рекомендуется 1
                                   -- примерно столько времени CTE запрос может блокировать другие запросы на запись тех же ресурсов
                                   -- от значения этого параметра устанавливаются следующие ограничения:
                                   -- lock_timeout = time_max * 1000 / 10
                                   -- если происходит ошибка, связанная с этими ограничениями, batch_rows уменьшается и CTE запрос через некоторое время повторяется
                                   -- Without lock_timeout CTE migration could block other writes WHILE TRYING to grab a lock on the resource (table/record/index/etc.)
    is_rollback boolean default false, -- откатывать запрос после каждого выполнения в цикле (для целей тестирования)
    cycles_max  integer default null, -- максимальное количество циклов (для целей тестирования)
    total_table_rows integer default null, -- сколько всего записей в таблице (для вычисления прогресса выполнения)
                                           -- если null, то автоматически вычисляется приблизительное значение, но быстро
                                           -- если <= 0, то автоматически вычисляется точное значение, но медленно
    error_table_name regclass default null, -- если указано, то процедура не прерывает работу на первой ошибке,
                                            -- а сохраняет все ошибки в указанную таблицу
    --возвращаемые из процедуры параметры:
    inout result record default null
    /*
        result.table_rows     int     -- сколько всего записей в таблице
        result.affected_rows  int     -- сколько всего записей модифицировал пользовательский запрос в таблице
        result.processed_rows int     -- сколько всего записей просмотрел пользовательский запрос в таблице
        result.time_elapsed   numeric -- длительность выполнения, в секундах
    */
)
    language plpgsql
as
$procedure$
DECLARE
    --константы
    quote_regexp constant text not null default '([[\](){}.+*^$|\\?-])';  -- регулярное выражение для квотирования данных в регулярном выражении
    ident_regexp constant text not null default '([a-zA-Z_]+[a-zA-Z_\d]*|"([^"]|"")+")'; -- регулярное выражение для захвата названия SQL идентификатора (таблицы, колонки и др.)
    alias_regexp constant text not null default format('(\s+(AS\s+)?%s)?', ident_regexp); -- регулярное выражение для захвата названия SQL необязательного псевдонима (таблицы, колонки и др.)
    query_type_regexp constant text not null default '\m(?:(INSERT)\s+INTO|(UPDATE)(?:\s+ONLY)?|(DELETE)\s+FROM(?:\s+ONLY)?)\s+%s\M';
    count_query constant text not null default 'SELECT COUNT(*) FROM %1$s WHERE %2$I > $1 AND %2$I <= $2'; -- SQL запрос для получения processed_rows
    last_subquery_exception_hint constant text not null default e'Last subquery must be:\nSELECT MAX(%I) AS stop_id, COUNT(*) AS affected_rows FROM m';
    old_lock_timeout constant text not null default current_setting('lock_timeout');
    old_session_replication_role constant text not null default current_setting('session_replication_role');
    max_attempts constant smallint not null default 200;
    app_name constant text not null default regexp_replace(current_setting('application_name'), '\s*/\d+(?:\.\d+)?%', '');
    multiplier constant numeric not null default 2; --not integer!

    --статистика
    total_time_start timestamp not null default clock_timestamp();
    total_time_elapsed numeric not null default 0; -- длительность выполнения всех запросов, в секундах
    total_affected_rows int not null default 0; -- сколько всего записей модифицировал пользовательский запрос в таблице
    total_processed_rows int not null default 0; -- сколько всего записей просмотрел пользовательский запрос в таблице
    estimated_time interval; -- оценочное время, сколько осталось работать
    rows_per_second numeric default 0;
    queries_per_second numeric default 0;
    cycles int not null default 0; -- счётчик для цикла
    is_calc_estimated_time boolean not null default false;
    progress numeric not null default 0;
    app_name_new text not null default '';

    -- свойства таблицы table_name:
    table_name_quoted text; -- название таблицы (квотированнное) для использования в рег. выражении
    uniq_column_name_quoted text; -- название primary/unique колонки (квотированнное) для использования в рег. выражении
    uniq_column_name text; -- название primary/unique колонки
    uniq_column_type text; -- тип primary/unique колонки

    -- для пользовательского CTE запроса query, выполняемого в цикле:
    start_id_bigint bigint not null default 0;
    start_id_text text not null default '';
    stop_id_bigint bigint;
    stop_id_text text;
    offset_rows int not null default 0;
    affected_rows bigint not null default 0; --сколько записей модифицировал пользовательский запрос
    processed_rows bigint not null default 0; --сколько записей просмотрел пользовательский запрос
    query_time_start timestamp;
    query_time_elapsed numeric not null default 0; -- длительность выполнения одного запроса, в секундах
    query_type text; --тип запроса: INSERT/UPDATE/DELETE
    time_start timestamp;
    time_elapsed numeric not null default 0;
    delay numeric; --задержка в секундах при возникновении блокировок
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
        batch_rows IS NULL OR
        time_max IS NULL OR
        is_rollback IS NULL THEN
        RAISE EXCEPTION 'Procedure arguments must not have NULL values (except cycles_max)!';
    ELSIF batch_rows not between 1 AND 1024 THEN
        RAISE EXCEPTION 'Argument batch_rows must between 1 and 1024, but % given', batch_rows;
    ELSIF time_max not between 1 AND 10 THEN
        RAISE EXCEPTION 'Argument time_max must between 1 and 10, but % given', time_max;
    ELSIF cycles_max < 0 THEN
        RAISE EXCEPTION 'Argument cycles_max must be >= 0, but % given', cycles_max;
    END IF;

    SELECT null::int as table_rows,
           null::int as affected_rows,
           null::int as processed_rows,
           null::numeric as time_elapsed
      INTO result;

    -- 2) проверка наличия not null уникального ключа
    SELECT pg_attribute.attname,
           format_type(pg_attribute.atttypid, pg_attribute.atttypmod)
    INTO uniq_column_name, uniq_column_type
    FROM pg_index, pg_class, pg_attribute, pg_namespace
    WHERE pg_class.oid = loop_execute.table_name
      AND pg_index.indrelid = pg_class.oid
      AND pg_class.relnamespace = pg_namespace.oid
      AND pg_attribute.attrelid = pg_class.oid
      AND pg_attribute.attnum = any(pg_index.indkey)
      AND pg_attribute.attnotnull
      AND pg_index.indisunique
    ORDER BY pg_index.indisprimary DESC -- primary key in priority
    LIMIT 1;

    IF uniq_column_name IS NULL THEN
        RAISE EXCEPTION 'Table % must has a column with primary/unique not null index!', table_name;
    END IF;

    -- 3) проверка необходимых частей в пользовательском запросе (в т.ч. защита от дурака)
    table_name_quoted       := regexp_replace(table_name::text, quote_regexp, '\\\1', 'g');
    uniq_column_name_quoted := regexp_replace(quote_ident(uniq_column_name), quote_regexp, '\\\1', 'g');
    query_type              := (array_remove(regexp_match(query, format(query_type_regexp, table_name_quoted)), null))[1];

    IF query_type IS NULL THEN
        RAISE EXCEPTION 'Unknown CTE query type, expected INSERT/UPDATE/DELETE!'
             USING HINT = 'Does CTE query has an INSERT/UPDATE/DELETE subquery?';
    ELSIF query !~* format('\m%s\M\s*>\s*\$1\M', uniq_column_name_quoted) THEN
        RAISE EXCEPTION 'Entry "% > $1" is not found in your CTE query!', quote_ident(uniq_column_name)
            USING HINT = format('Add "%I > $1" to WHERE clause of SELECT subquery.', uniq_column_name);
    ELSIF query !~* format('\morder\s+by\s+(%s\.)?%s\M(?!\s+desc\M)', ident_regexp, uniq_column_name_quoted) THEN
        RAISE EXCEPTION 'Entry "ORDER BY %" is not found in your CTE query!', quote_ident(uniq_column_name)
            USING HINT = format('Add "ORDER BY %I ASC" to end of SELECT subquery.', uniq_column_name);
    ELSIF query !~* '\mlimit\s+\$2\M' THEN
        RAISE EXCEPTION 'Entry "LIMIT $2" is not found in your CTE query!'
            USING HINT = 'Add "LIMIT $2" to end of SELECT subquery.';
    ELSIF regexp_match(query,
                       format($regexp$
                                  \mSELECT \s+
                                      MAX\(%s\)    %2$s  \s*,\s*
                                      COUNT\(\*\)  %2$s  \s+
                                  FROM \s+ %1$s %2$s \s* (;\s*)? $
                              $regexp$, ident_regexp, alias_regexp), 'ix') is null THEN
        RAISE EXCEPTION 'Incorrect last subquery in your CTE query!'
            USING HINT = format(last_subquery_exception_hint, uniq_column_name);
    END IF;

    -- 4) подсчёт общего кол-ва записей
    query_time_start := clock_timestamp();
    IF total_table_rows IS NULL THEN
        RAISE NOTICE 'Calculating estimate total rows for table % ...', table_name;
        select t.reltuples::bigint into total_table_rows
        from pg_class as t
        where t.oid = loop_execute.table_name;
    END IF;

    IF total_table_rows <= 0 THEN
        RAISE NOTICE 'Calculating exact total rows for table % ...', table_name;
        EXECUTE format('SELECT COUNT(*) FROM %1$s', table_name) INTO total_table_rows;
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
    IF is_disable_triggers THEN
        SELECT r.rolsuper INTO is_superuser FROM pg_roles AS r WHERE r.rolname = CURRENT_USER;
        IF NOT is_superuser THEN
            RAISE EXCEPTION 'To disable triggers and foreign keys superuser role required!';
        END IF;
    END IF;

    LOOP
        EXIT WHEN cycles >= cycles_max;
        cycles := cycles + 1;

        PERFORM set_config('lock_timeout', ceil(time_max * 1000 / 10)::text, true);
        /*
        --statement_timeout does not work inside PLpgSQL:
        do $$ begin set local statement_timeout to '1s'; perform pg_sleep(2); end;$$;
        --statement_timeout works inside SQL:
        begin; set local statement_timeout to '1s'; select pg_sleep(2); commit;
        --TODO use dblink to workаround?
        */

        IF is_disable_triggers THEN
            set local session_replication_role = 'replica';
        END IF;

        query_time_start := clock_timestamp();
        time_start := clock_timestamp();
        FOR cur_attempt IN 1..max_attempts LOOP
            BEGIN -- subtransaction SAVEPOINT

                IF uniq_column_type IN ('integer', 'bigint') THEN
                    start_id_bigint := coalesce(stop_id_bigint, start_id_bigint);
                    EXECUTE query USING start_id_bigint, batch_rows, offset_rows INTO STRICT stop_id_bigint, affected_rows;
                    IF start_id_bigint >= stop_id_bigint THEN
                        ROLLBACK AND CHAIN;
                        RAISE EXCEPTION 'Infinity cycle has been found (start_id=% >= stop_id=%)! There are mistake in your CTE query.',
                                        start_id_bigint, stop_id_bigint
                            USING HINT = format(last_subquery_exception_hint, uniq_column_name);
                    END IF;
                    EXECUTE format(count_query, table_name, uniq_column_name) USING start_id_bigint, stop_id_bigint INTO processed_rows;
                ELSIF uniq_column_type ~* '\m(varying|character|text|char|varchar)\M' THEN
                    start_id_text := coalesce(stop_id_text, start_id_text);
                    EXECUTE query USING start_id_text, batch_rows, offset_rows INTO STRICT stop_id_text, affected_rows;
                    IF start_id_text >= stop_id_text THEN
                        ROLLBACK AND CHAIN;
                        RAISE EXCEPTION 'Infinity cycle has been found (start_id=% >= stop_id=%)! There are mistake in your CTE query.',
                                        quote_literal(start_id_text), quote_literal(stop_id_text)
                            USING HINT = format(last_subquery_exception_hint, uniq_column_name);
                    END IF;
                    EXECUTE format(count_query, table_name, uniq_column_name) USING start_id_text, stop_id_text INTO processed_rows;
                ELSE
                    RAISE EXCEPTION 'Column %.% has unsupported type % ', table_name, uniq_column_name, uniq_column_type
                        USING HINT = 'You can add support by modify procedure :-)';
                END IF;

                offset_rows := 0;
                EXIT; --запрос выполнился успешно, выходим из цикла FOR ... LOOP

            EXCEPTION -- subtransaction ROLLBACK TO SAVEPOINT
                WHEN lock_not_available THEN
                    IF cur_attempt < max_attempts THEN
                        batch_rows := ceil(batch_rows / multiplier);
                        time_elapsed := round(extract('epoch' from clock_timestamp() - time_start)::numeric, 2);
                        delay := round(greatest(sqrt(time_elapsed * time_max), time_max), 2);
                        delay := round(((random() * (delay - time_max)) + time_max)::numeric, 2);
                        RAISE WARNING 'Attempt % of % to execute CTE query failed due lock_timeout = %, next replay after % s',
                            cur_attempt, max_attempts, current_setting('lock_timeout'), delay;
                        PERFORM pg_sleep(delay);
                    ELSE
                        RAISE WARNING 'Attempt % of % to execute CTE query failed due lock_timeout = %',
                            cur_attempt, max_attempts, current_setting('lock_timeout');
                        RAISE; -- raise the original exception
                    END IF;
                WHEN others THEN
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

                    affected_rows := 0;
                    processed_rows := 0;

                    IF uniq_column_type IN ('integer', 'bigint') THEN
                        RAISE WARNING 'ERROR of EXECUTE SQL statement using: $1 := %, $2 := %', start_id_bigint, batch_rows;
                    ELSIF uniq_column_type ~* '\m(varying|character|text|char|varchar)\M' THEN
                        RAISE WARNING 'ERROR of EXECUTE SQL statement using: $1 := %, $2 := %', quote_literal(start_id_text), batch_rows;
                    END IF;

                    IF cur_attempt = max_attempts THEN
                        RAISE WARNING 'Attempt % of % reached!', cur_attempt, max_attempts;
                        RAISE; -- raise the original exception
                    ELSIF batch_rows > 1 THEN
                        --позиционируемся на проблемную запись
                        batch_rows := ceil(batch_rows / multiplier);
                    ELSIF error_table_name IS NULL THEN
                        EXIT; --выходим из цикла FOR ... LOOP
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
                            ON CONFLICT ON CONSTRAINT loop_execute_error_uniq
                            DO UPDATE SET repeat_error_count = t.repeat_error_count + 1
                            $$, ':error_table_name', error_table_name::text)
                            USING table_name::text,
                                uniq_column_name,
                                case when uniq_column_type ~* '\m(varying|character|text|char|varchar)\M' then stop_id_text end,
                                case when uniq_column_type IN ('integer', 'bigint') then stop_id_bigint end,
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

                        offset_rows := offset_rows + 1;
                    END IF;

            END; --subtransaction BEGIN/EXCEPTION/END

        END LOOP; --FOR LOOP
        query_time_elapsed := round(extract('epoch' from clock_timestamp() - query_time_start)::numeric, 2);

        IF is_rollback THEN
            ROLLBACK AND CHAIN;
        ELSE
            COMMIT AND CHAIN; -- https://www.postgresql.org/docs/12/plpgsql-transactions.html
        END IF;

        total_time_elapsed := round(extract('epoch' from clock_timestamp() - total_time_start)::numeric, 2);

        total_affected_rows  := total_affected_rows  + affected_rows;
        total_processed_rows := total_processed_rows + processed_rows;
        IF total_processed_rows > total_table_rows THEN
            --в случае приблизительного вычисления кол-ва строк в таблице корректируем значения
            total_table_rows := total_processed_rows;
            result.table_rows := total_table_rows;
        END IF;

        result.time_elapsed   := total_time_elapsed;
        result.affected_rows  := total_affected_rows;
        result.processed_rows := total_processed_rows;

        is_calc_estimated_time := not is_calc_estimated_time and (cycles > 10 or (query_time_elapsed > time_max and cycles > 4));
        IF is_calc_estimated_time THEN
            estimated_time := (ceil(total_table_rows * total_time_elapsed / total_processed_rows - total_time_elapsed)::text || 's')::interval;
        END IF;
        progress := round(total_processed_rows * 100.0 / total_table_rows, 2);

        --RAISE NOTICE 'Query %, affected % rows, processed % rows (% > %) for % sec %',
        RAISE NOTICE 'Query %: affected % rows, processed % rows, elapsed % sec%',
            cycles, affected_rows, processed_rows,
            --uniq_column_name, quote_literal(case when uniq_column_type in ('integer', 'bigint') then start_id_bigint::text else start_id_text end),
            query_time_elapsed, case when is_rollback then ', ROLLBACK MODE!' else '' end;
        RAISE NOTICE 'Total: affected % rows, processed % rows', total_affected_rows, total_processed_rows;
        RAISE NOTICE 'Current datetime: %, elapsed time: %, estimated time: %, progress: % %%',
            clock_timestamp()::timestamp(0),
            (clock_timestamp() - total_time_start)::interval(0),
            COALESCE(estimated_time::text, '?'),
            progress;
        RAISE NOTICE ' '; -- just new line

        app_name_new := concat(app_name, ' /', progress, '%');
        if octet_length(app_name_new) < 64 then
            PERFORM set_config('application_name', app_name_new, true);
        end if;

        EXIT WHEN affected_rows < batch_rows OR (stop_id_bigint IS NULL AND stop_id_text IS NULL);

        IF affected_rows = 0 THEN
            NULL;
        ELSIF query_time_elapsed <= time_max THEN
            batch_rows := case when query_time_elapsed = 0 then batch_rows * multiplier
                               else least(ceil(batch_rows * time_max / query_time_elapsed), batch_rows * multiplier)
                          end;
        ELSIF batch_rows > 1 THEN
            batch_rows := greatest(ceil(batch_rows * time_max / query_time_elapsed), ceil(batch_rows / multiplier));
        ELSE
            delay := round(greatest(sqrt(query_time_elapsed * time_max) - time_max, 0), 2);
            RAISE WARNING 'Try to save DB from overload, next replay after % s', delay;
            PERFORM pg_sleep(delay);
        END IF;

    END LOOP;

    IF total_time_elapsed > 0 THEN
        rows_per_second    := ceil(total_processed_rows / total_time_elapsed);
        queries_per_second := round(cycles / total_time_elapsed, 2);
    END IF;

    RAISE NOTICE 'Done. % rows per second, % queries per second', rows_per_second, queries_per_second;

    IF is_disable_triggers THEN
        PERFORM set_config('session_replication_role', old_session_replication_role, true);
    END IF;

    PERFORM set_config('lock_timeout', old_lock_timeout, true);

END
$procedure$;

comment on procedure loop_execute(
    --обязательные параметры:
    table_name  regclass,
    query       text,
    --необязательные параметры:
    is_disable_triggers boolean,
    batch_rows  integer,
    time_max    numeric,
    is_rollback boolean,
    cycles_max  integer,
    total_table_rows integer,
    exception_table_name regclass,
    --возвращаемые из процедуры параметры:
    inout result record
) is $$
Процедура для обработки строк в больших таблицах (тысячи и миллионы строк) с контролируемым временем блокировки строк на запись.
Принцип работы -- выполняет в цикле CTE DML запрос, который добавляет, обновляет или удаляет записи в таблице.
В завершении каждого цикла изменения фиксируются (либо откатываются для целей тестирования, это настраивается).
Автоматически адаптируется под нагрузку на БД. На реплику данные передаются постепенно небольшими порциями, а не одним огромным куском.
В процессе обработки показывает в psql консоли:
   * количество модифицированных и обработанных записей в таблице
   * сколько времени прошло, сколько примерно времени осталось до завершения, прогресс выполнения в процентах
Прогресс выполнения в процентах для работающего процесса отображается ещё в колонке pg_stat_activity.application_name!
Процедура не предназначена для выполнения в транзакции.
$$;
