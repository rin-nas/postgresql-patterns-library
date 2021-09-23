-- Выполняет DML запрос в цикле
-- Автоматически адаптируется под нагрузку БД
-- Показывает в psql консоли время выполнения - сколько прошло и сколько примерно осталось
create or replace procedure loop_execute(
    table_name regclass, -- название основной таблицы (дополненное схемой, при необходимости), из которой данные порциями в цикле будут читаться и модифицироваться
    query text, -- CTE запрос с SELECT, INSERT/UPDATE/DELETE и SELECT запросами для модификации записей
    is_rollback boolean default false, -- откатывать запрос после каждого выполнения в цикле (для целей тестирования)
    cycles_max integer default null -- максимальное количество циклов (для целей тестирования)
)
    language plpgsql
as
$procedure$
DECLARE
    --ограничения
    time_max constant numeric not null default 1; -- пороговое максимальное время выполнения 1-го запроса, в секундах (рекомендуется 1 секунда)
    batch_rows int not null default 1; -- сколько записей будем модифицировать за 1 цикл (значение автоматически подстраивается под time_max)

    --статистика
    total_time_start timestamp not null default clock_timestamp();
    total_time_elapsed numeric not null default 0; -- время выполнения всех запросов, в секундах
    query_time_start timestamp;
    query_time_elapsed numeric not null default 0; -- фактическое время выполнения 1-го запроса, в секундах
    estimated_time interval; -- оценочное время, сколько осталось работать
    rows_per_second numeric default 0;
    queries_per_second numeric default 0;
    cycles int not null default 0; -- счётчик для цикла
    total_affected_rows int not null default 0; -- сколько всего записей модифицировал пользовательский запрос
    total_processed_rows int not null default 0; -- сколько всего записей просмотрел пользовательский запрос

    -- в таблице table_name:
    total_rows int not null default 0; -- количество записей всего
    total_id int not null default 0; -- количество записей всего, где id не null
    total_distinct_id int not null default 0; -- количество уникальных записей всего, где id не null
    uniq_column_name_quoted text; -- название primary/unique колонки (квотированнное)
    uniq_column_name text; -- название primary/unique колонки
    uniq_column_type text; -- тип primary/unique колонки
    query_count text;

    -- для пользовательского запроса query, выполняемого в цикле:
    start_id_bigint bigint not null default 0;
    start_id_text text not null default '';
    stop_id_bigint bigint default 0;
    stop_id_text text default '';
    affected_rows bigint not null default 0; --сколько записей модифицировал пользовательский запрос
    processed_rows bigint not null default 0; --сколько записей просмотрел пользовательский запрос
BEGIN

    -- валидация 1
    IF table_name IS NULL OR query IS NULL THEN
        RAISE EXCEPTION 'Procedure arguments cannot has NULL values!';
    END IF;

    SELECT pg_attribute.attname,
           format_type(pg_attribute.atttypid, pg_attribute.atttypmod)
    INTO uniq_column_name, uniq_column_type
    FROM pg_index, pg_class, pg_attribute, pg_namespace
    WHERE pg_class.oid = table_name
      AND pg_index.indrelid = pg_class.oid
      AND pg_class.relnamespace = pg_namespace.oid
      AND pg_attribute.attrelid = pg_class.oid
      AND pg_attribute.attnum = any(pg_index.indkey)
      AND pg_index.indisunique
    ORDER BY pg_index.indisprimary DESC -- primary key in priority
    LIMIT 1;

    uniq_column_name_quoted := regexp_replace(quote_ident(uniq_column_name), '([[\](){}.+*^$|\\?-])', '\\\1', 'g');

    -- валидация 2
    IF uniq_column_name IS NULL THEN
        RAISE EXCEPTION 'Table % should has a some column with primary/unique index!', table_name;
    ELSIF query !~* format('\m%s\M\s*>\s*\$1\M', uniq_column_name_quoted) THEN
        RAISE EXCEPTION 'Entry "% > $1" is not found in your query!', quote_ident(uniq_column_name)
            USING HINT = format('Add "%I > $1" to WHERE clause of SELECT query.', uniq_column_name);
    ELSIF query !~* format('\morder\s+by\s+%s\M(?!\s+desc\M)', uniq_column_name_quoted) THEN
        RAISE EXCEPTION 'Entry "ORDER BY %" is not found in your query!', quote_ident(uniq_column_name)
            USING HINT = format('Add "ORDER BY %I ASC" to end of SELECT query.', uniq_column_name);
    ELSIF query !~* '\mlimit\M\s+\$2\M' THEN
        RAISE EXCEPTION 'Entry "LIMIT $2" is not found in your query!' USING HINT = 'Add "LIMIT $2" to end of SELECT query.';
    ELSIF cycles_max < 0 THEN
        RAISE EXCEPTION 'Argument cycles_max should be >= 0, but % given', cycles_max;
    END IF;

    query_time_start := clock_timestamp();
    RAISE NOTICE 'Calculating total rows, checking null and unique values for column %.% ...', table_name, uniq_column_name;
    EXECUTE format('SELECT COUNT(*), COUNT(%2$I), COUNT(DISTINCT %2$I) FROM %1$s', table_name, uniq_column_name)
        INTO total_rows, total_id, total_distinct_id;
    query_time_elapsed := round(extract('epoch' from clock_timestamp() - query_time_start)::numeric, 2);
    total_time_elapsed := round(extract('epoch' from clock_timestamp() - total_time_start)::numeric, 2);
    RAISE NOTICE 'Done. % total rows found for % sec', total_rows, query_time_elapsed;

    -- валидация 3
    IF total_rows != total_id THEN
        RAISE EXCEPTION 'Column %.% has % NULL values!', table_name, uniq_column_name, (total_rows - total_id)
            USING HINT = format('Remove all NULL values for %I column.', uniq_column_name);
    ELSIF total_id != total_distinct_id THEN --избыточная проверка
        RAISE EXCEPTION 'Column %.% has % duplicate values!', table_name, uniq_column_name, (total_id - total_distinct_id)
            USING HINT = format('Remove all duplicate values for %I column.', uniq_column_name);
    END IF;

    query_count := format('SELECT COUNT(*) FROM %1$s WHERE %2$s > $1 AND %2$s <= $2', table_name, uniq_column_name);

    LOOP
        EXIT WHEN cycles >= cycles_max;
        cycles := cycles + 1;

        query_time_start := clock_timestamp();

        IF uniq_column_type IN ('integer', 'bigint') THEN
            start_id_bigint := stop_id_bigint;
            EXECUTE query USING start_id_bigint, batch_rows INTO STRICT stop_id_bigint, affected_rows;
            EXECUTE query_count USING start_id_bigint, stop_id_bigint INTO processed_rows;
        ELSIF uniq_column_type ~* '\m(varying|character|text|char|varchar)\M' THEN
            start_id_text := stop_id_text;
            EXECUTE query USING start_id_text, batch_rows INTO STRICT stop_id_text, affected_rows;
            EXECUTE query_count USING start_id_text, stop_id_text INTO processed_rows;
        ELSE
            RAISE EXCEPTION 'Column %.% has unsupported type % ', table_name, uniq_column_name, uniq_column_type USING HINT = 'You can add support by modify procedure :-)';
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

        IF cycles > 16 THEN
            estimated_time := ((total_rows * total_time_elapsed / total_processed_rows - total_time_elapsed)::int::text || 's')::interval;
        END IF;

        --RAISE NOTICE 'Query %, affected % rows, processed % rows (% > %) for % sec %',
        RAISE NOTICE 'Query %: affected % rows, processed % rows, elapsed % sec%',
            cycles, affected_rows, processed_rows,
            --uniq_column_name, quote_literal(case when uniq_column_type in ('integer', 'bigint') then start_id_bigint::text else start_id_text end),
            query_time_elapsed, case when is_rollback then ', ROLLBACK MODE!' else '' end;
        RAISE NOTICE 'Total: affected % rows, processed % of % rows', total_affected_rows, total_processed_rows, total_rows;
        RAISE NOTICE 'Current datetime: %, elapsed time: %, estimated time: %, progress: % %%',
            clock_timestamp()::timestamp(0),
            (clock_timestamp() - total_time_start)::interval(0),
            COALESCE(estimated_time::text, '?'), round(total_processed_rows * 100.0 / total_rows, 2);
        RAISE NOTICE ''; -- just new line

        EXIT WHEN affected_rows < batch_rows OR stop_id_bigint IS NULL OR stop_id_text IS NULL;

        IF query_time_elapsed <= time_max THEN
            batch_rows := batch_rows * 2;
        ELSIF batch_rows > 1 THEN
            batch_rows := batch_rows / 2;
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

------------------------------------------------------------------------------------------------------------------------
--Примеры использования
------------------------------------------------------------------------------------------------------------------------

--обезличиваем email
call loop_execute(
    'v3_person_email',
    $$
        WITH s AS (
            SELECT id,
                   coalesce(depers.hash_email_username(email), 'id' || id || '@invalid.email') AS email
            FROM v3_person_email
            WHERE id > $1
              AND use_cpu(id, 1, 4)
              AND email IS NOT NULL AND TRIM(email) != ''
              AND NOT depers.is_email_ignore(email)
            ORDER BY id
            LIMIT $2
        ),
        m AS (
            UPDATE v3_person_email AS u
            SET email = s.email
            FROM s
            WHERE s.id = u.id
            RETURNING u.id
        )
        SELECT MAX(id)  AS next_start_id,
               COUNT(*) AS affected_rows
        FROM m;
    $$
);

-- удаляем невалидные email
call loop_execute(
    'v3_person_email',
    $$
        WITH s AS (
            SELECT id
            FROM v3_person_email
            WHERE id > $1
              AND use_cpu(id, 1, 4)
              AND email IS NOT NULL AND TRIM(email) != ''
              AND NOT(
                    octet_length(email) BETWEEN 6 AND 320
                    AND email = trim(email)
                    AND email LIKE '_%@_%.__%'
                    AND is_email(email)
                )
            ORDER BY id
            LIMIT $2
        ),
        m AS (
            DELETE FROM v3_person_email AS d
            WHERE id IN (SELECT id FROM s)
            RETURNING d.id
        )
        SELECT MAX(id)  AS next_start_id,
               COUNT(*) AS affected_rows
        FROM m;
    $$
);
