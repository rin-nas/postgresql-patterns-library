/*
Процедура для обработки строк в больших таблицах (тысячи и миллионы строк) с контролируемым временем блокировки строк на запись.
Принцип работы -- выполняет CTE DML запрос в цикле. В завершении каждого цикла изменения фиксируются (либо откатываются для целей тестирования, это настраивается).
Автоматически адаптируется под нагрузку на БД. На реплику данные передаются постепенно небольшими порциями, а не одним огромным куском.
В процессе обработки показывает в psql консоли:
   * количество модифицированных и обработанных записей в таблице
   * сколько времени прошло, сколько примерно времени осталось до завершения, прогресс выполнения в процентах
Процедура не предназначена для выполнения в транзакции.
*/
create or replace procedure loop_execute(
    --обязательные параметры:
    table_name  regclass, -- название основной таблицы (дополненное схемой, при необходимости), из которой данные порциями в цикле будут читаться и модифицироваться
    query       text, -- CTE запрос с SELECT, INSERT/UPDATE/DELETE и SELECT запросами для модификации записей
    --необязательные параметры:
    batch_rows  int     default 1, -- сколько записей будем модифицировать за 1 цикл (значение автоматически подстраивается под time_max), рекомендуется 1
    time_max    numeric default 1, -- пороговое максимальное время выполнения 1-го запроса, в секундах, рекомендуется 1
    is_rollback boolean default false, -- откатывать запрос после каждого выполнения в цикле (для целей тестирования)
    cycles_max  integer default null, -- максимальное количество циклов (для целей тестирования)
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
    ident_regexp constant text not null default '([a-z_]+|"([^"]|"")+")'; -- регулярное выражение для захвата названия SQL идентификатора (таблицы, колонки и др.)
    alias_regexp constant text not null default format('(\s+(AS\s+)?%s)?', ident_regexp); -- регулярное выражение для захвата названия SQL необязательного псевдонима (таблицы, колонки и др.)
    query_count constant text default 'SELECT COUNT(*) FROM %1$s WHERE %2$I > $1 AND %2$I <= $2'; -- SQL запрос для получения processed_rows
    last_subquery_exception_hint constant text not null default e'Last subquery must be:\nSELECT MAX(%I) AS stop_id, COUNT(*) AS affected_rows FROM m';

    --статистика
    total_time_start timestamp not null default clock_timestamp();
    total_time_elapsed numeric not null default 0; -- длительность выполнения всех запросов, в секундах
    total_table_rows int not null default 0; -- сколько всего записей в таблице
    total_affected_rows int not null default 0; -- сколько всего записей модифицировал пользовательский запрос в таблице
    total_processed_rows int not null default 0; -- сколько всего записей просмотрел пользовательский запрос в таблице
    estimated_time interval; -- оценочное время, сколько осталось работать
    rows_per_second numeric default 0;
    queries_per_second numeric default 0;
    cycles int not null default 0; -- счётчик для цикла
    is_calc_estimated_time boolean not null default false;

    -- свойства таблицы table_name:
    uniq_column_name_quoted text; -- название primary/unique колонки (квотированнное)
    uniq_column_name text; -- название primary/unique колонки
    uniq_column_type text; -- тип primary/unique колонки

    -- для пользовательского запроса query, выполняемого в цикле:
    start_id_bigint bigint not null default 0;
    start_id_text text not null default '';
    stop_id_bigint bigint default 0;
    stop_id_text text default '';
    affected_rows bigint not null default 0; --сколько записей модифицировал пользовательский запрос
    processed_rows bigint not null default 0; --сколько записей просмотрел пользовательский запрос
    query_time_start timestamp;
    query_time_elapsed numeric not null default 0; -- длительность выполнения одного запроса, в секундах
BEGIN

    -- 1) проверка входящих параметров
    IF table_name IS NULL OR
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
           null::numeric as time_elapsed INTO result;

    -- 2) проверка наличия not null уникального ключа
    SELECT pg_attribute.attname,
           format_type(pg_attribute.atttypid, pg_attribute.atttypmod)
    INTO uniq_column_name, uniq_column_type
    FROM pg_index, pg_class, pg_attribute, pg_namespace
    WHERE pg_class.oid = table_name
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

    -- 3) проверка необходимых частей в пользовательском запросе (защита от дурака)
    uniq_column_name_quoted := regexp_replace(quote_ident(uniq_column_name), quote_regexp, '\\\1', 'g');

    IF query !~* format('\m%s\M\s*>\s*\$1\M', uniq_column_name_quoted) THEN
        RAISE EXCEPTION 'Entry "% > $1" is not found in your CTE query!', quote_ident(uniq_column_name)
            USING HINT = format('Add "%I > $1" to WHERE clause of SELECT subquery.', uniq_column_name);
    ELSIF query !~* format('\morder\s+by\s+%s\M(?!\s+desc\M)', uniq_column_name_quoted) THEN
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
    RAISE NOTICE 'Calculating total rows for table % ...', table_name;
    EXECUTE format('SELECT COUNT(*) FROM %1$s', table_name) INTO total_table_rows;

    query_time_elapsed := round(extract('epoch' from clock_timestamp() - query_time_start)::numeric, 2);
    total_time_elapsed := round(extract('epoch' from clock_timestamp() - total_time_start)::numeric, 2);

    result.table_rows   := total_table_rows;
    result.time_elapsed := total_time_elapsed;

    RAISE NOTICE 'Done. % total rows found for % sec', total_table_rows, query_time_elapsed;
    RAISE NOTICE ' '; -- just new line

    LOOP
        EXIT WHEN cycles >= cycles_max;
        cycles := cycles + 1;

        query_time_start := clock_timestamp();

        IF uniq_column_type IN ('integer', 'bigint') THEN
            start_id_bigint := stop_id_bigint;
            EXECUTE query USING start_id_bigint, batch_rows INTO STRICT stop_id_bigint, affected_rows;
            IF start_id_bigint >= stop_id_bigint THEN
                ROLLBACK AND CHAIN;
                RAISE EXCEPTION 'Infinity cycle has been found (start_id=% >= stop_id=%)! There are mistake in your CTE query.',
                                start_id_bigint, stop_id_bigint
                    USING HINT = format(last_subquery_exception_hint, uniq_column_name);
            END IF;
            EXECUTE format(query_count, table_name, uniq_column_name) USING start_id_bigint, stop_id_bigint INTO processed_rows;
        ELSIF uniq_column_type ~* '\m(varying|character|text|char|varchar)\M' THEN
            start_id_text := stop_id_text;
            EXECUTE query USING start_id_text, batch_rows INTO STRICT stop_id_text, affected_rows;
            IF start_id_text >= stop_id_text THEN
                ROLLBACK AND CHAIN;
                RAISE EXCEPTION 'Infinity cycle has been found (start_id=% >= stop_id=%)! There are mistake in your CTE query.',
                                quote_literal(start_id_text), quote_literal(stop_id_text)
                    USING HINT = format(last_subquery_exception_hint, uniq_column_name);
            END IF;
            EXECUTE format(query_count, table_name, uniq_column_name) USING start_id_text, stop_id_text INTO processed_rows;
        ELSE
            RAISE EXCEPTION 'Column %.% has unsupported type % ', table_name, uniq_column_name, uniq_column_type
                USING HINT = 'You can add support by modify procedure :-)';
        END IF;

        IF is_rollback THEN
            ROLLBACK AND CHAIN;
        ELSE
            COMMIT AND CHAIN; -- https://www.postgresql.org/docs/12/plpgsql-transactions.html
        END IF;

        query_time_elapsed := round(extract('epoch' from clock_timestamp() - query_time_start)::numeric, 2);
        total_time_elapsed := round(extract('epoch' from clock_timestamp() - total_time_start)::numeric, 2);

        total_affected_rows  := total_affected_rows  + affected_rows;
        total_processed_rows := total_processed_rows + processed_rows;

        result.time_elapsed   := total_time_elapsed;
        result.affected_rows  := total_affected_rows;
        result.processed_rows := total_processed_rows;

        is_calc_estimated_time := not is_calc_estimated_time and (cycles > 16 or query_time_elapsed > time_max);
        IF is_calc_estimated_time THEN
            estimated_time := ((total_table_rows * total_time_elapsed / total_processed_rows - total_time_elapsed)::int::text || 's')::interval;
        END IF;

        --RAISE NOTICE 'Query %, affected % rows, processed % rows (% > %) for % sec %',
        RAISE NOTICE 'Query %: affected % rows, processed % rows, elapsed % sec%',
            cycles, affected_rows, processed_rows,
            --uniq_column_name, quote_literal(case when uniq_column_type in ('integer', 'bigint') then start_id_bigint::text else start_id_text end),
            query_time_elapsed, case when is_rollback then ', ROLLBACK MODE!' else '' end;
        RAISE NOTICE 'Total: affected % rows, processed % rows', total_affected_rows, total_processed_rows;
        RAISE NOTICE 'Current datetime: %, elapsed time: %, estimated time: %, progress: % %%',
            clock_timestamp()::timestamp(0),
            (clock_timestamp() - total_time_start)::interval(0),
            COALESCE(estimated_time::text, '?'), round(total_processed_rows * 100.0 / total_table_rows, 2);
        RAISE NOTICE ' '; -- just new line

        EXIT WHEN affected_rows < batch_rows OR stop_id_bigint IS NULL OR stop_id_text IS NULL;

        IF query_time_elapsed <= time_max THEN
            batch_rows := batch_rows * 2;
        ELSIF batch_rows > 1 THEN
            batch_rows := (batch_rows / 2)::int;
        ELSE
            PERFORM pg_sleep(greatest(sqrt(query_time_elapsed * time_max) - time_max, 0)); --try to save DB from overload
        END IF;

    END LOOP;

    IF total_time_elapsed > 0 THEN
        rows_per_second    := (total_processed_rows / total_time_elapsed)::int;
        queries_per_second := round(cycles / total_time_elapsed, 2);
    END IF;

    RAISE NOTICE 'Done. % rows per second, % queries per second', rows_per_second, queries_per_second;

END
$procedure$;
