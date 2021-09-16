-- Выполняет DML запрос в цикле
-- Автоматически адаптируется под нагрузку БД
-- Показывает в psql консоли время выполнения - сколько прошло и сколько примерно осталось
create or replace procedure loop_execute(
    table_name regclass, -- название основной таблицы (дополненное схемой, при необходимости), из которой будут читаться порциями данные для последующей модификации записей
    query text, --CTE запрос с SELECT, INSERT/UPDATE/DELETE и SELECT запросами для модификации записей
    cpu_num smallint default 1, -- для распараллеливания скрипта для выполнения через {JiraTaskId}_do.sh: номер текущего ядра процессора
    cpu_max smallint default 1  -- для распараллеливания скрипта для выполнения через {JiraTaskId}_do.sh: максимальное количество ядер процессора
)
    language plpgsql
as
$procedure$
DECLARE
    total_time_start timestamp not null default clock_timestamp();
    total_time_elapsed numeric not null default 0; -- время выполнения всех запросов, в секундах
    query_time_start timestamp;
    query_time_elapsed numeric not null default 0; -- фактическое время выполнения 1-го запроса, в секундах
    estimated_time interval; -- оценочное время, сколько осталось работать
    current_start_id bigint not null default 0;
    next_start_id bigint default 0;
    affected_rows bigint not null default 0;
    cycles int not null default 0; -- счётчик для цикла
    batch_rows int not null default 1; -- по сколько записей будем обновлять за 1 цикл
    processed_rows int not null default 0; -- счётчик, сколько записей обновили, увеличивается на каждой итерации цикла
    total_rows int not null default 0; -- количество записей всего
    total_id int not null default 0; -- количество записей всего, где id не null
    total_distinct_id int not null default 0; -- количество уникальных записей всего, где id не null
    time_max constant numeric not null default 1; -- пороговое максимальное время выполнения 1-го запроса, в секундах (рекомендуется 1 секунда)
BEGIN

    -- валидация 1
    IF table_name IS NULL OR query IS NULL OR cpu_num IS NULL OR cpu_max IS NULL THEN
        RAISE EXCEPTION 'Procedure arguments cannot has NULL values!';
    ELSIF NOT EXISTS(SELECT
                     FROM pg_index, pg_class, pg_attribute, pg_namespace
                     WHERE pg_class.oid = table_name
                       AND pg_index.indrelid = pg_class.oid
                       AND pg_class.relnamespace = pg_namespace.oid
                       AND pg_attribute.attrelid = pg_class.oid
                       AND pg_attribute.attnum = any(pg_index.indkey)
                       AND pg_index.indisunique
                       AND pg_attribute.attname = 'id'
                       AND format_type(pg_attribute.atttypid, pg_attribute.atttypmod) = 'integer') THEN
        RAISE EXCEPTION 'Table % should has a column "id" with type "integer" and primary/unique index!', table_name;
    ELSIF query !~* '\mid\M\s*>\s*\$1\M' THEN
        RAISE EXCEPTION 'Entry "id > $1" is not found in your query!' USING HINT = 'Add "id > $1" to WHERE clause of SELECT query.';
    ELSIF query !~* '\morder\s+by\s+id\M(?!\s+desc\M)' THEN
        RAISE EXCEPTION 'Entry "ORDER BY id" is not found in your query!' USING HINT = 'Add "ORDER BY id ASC" to end of SELECT query.';
    ELSIF query !~* '\mlimit\M\s+\$2\M' THEN
        RAISE EXCEPTION 'Entry "LIMIT $2" is not found in your query!' USING HINT = 'Add "LIMIT $2" to end of SELECT query.';
    ELSIF cpu_num NOT BETWEEN 1 AND 256 THEN
        RAISE EXCEPTION 'Argument cpu_num should be between 1 and 256, but % given!', cpu_num;
    ELSIF cpu_max NOT BETWEEN 1 AND 256 THEN
        RAISE EXCEPTION 'Argument cpu_max should be between 1 and 256, but % given!', cpu_max;
    ELSIF cpu_num > cpu_max THEN
        RAISE EXCEPTION 'Argument cpu_num should be <= cpu_max! Given cpu_num = %, cpu_max = %', cpu_num, cpu_max;
    END IF;

    query_time_start := clock_timestamp();
    RAISE NOTICE 'Calculating total rows and checking unique id values for table %s ...', table_name;
    EXECUTE 'SELECT COUNT(*), COUNT(id), COUNT(DISTINCT id) FROM ' || table_name INTO total_rows, total_id, total_distinct_id;
    query_time_elapsed := round(extract('epoch' from clock_timestamp() - query_time_start)::numeric, 2);
    RAISE NOTICE 'Done. % total rows found for % sec', total_rows, query_time_elapsed;

    -- валидация 2
    IF total_rows != total_id THEN
        RAISE EXCEPTION 'Table %: "id" column has % NULL values!', table_name, (total_rows - total_id) USING HINT = 'Remove all NULL values for "id" column.';
    ELSIF total_rows != total_distinct_id THEN
        RAISE EXCEPTION 'Table %: "id" column has % duplicate values!', table_name, (total_rows - total_distinct_id) USING HINT = 'Remove all duplicate values for "id" column.';
    END IF;

    LOOP
        cycles := cycles + 1;
        --EXIT WHEN cycles > 20; -- для отладки

        query_time_start := clock_timestamp();

        current_start_id := next_start_id;
        EXECUTE query USING current_start_id, batch_rows, cpu_num, cpu_max INTO STRICT next_start_id, affected_rows;
        COMMIT; -- https://www.postgresql.org/docs/12/plpgsql-transactions.html

        query_time_elapsed := round(extract('epoch' from clock_timestamp() - query_time_start)::numeric, 2);
        total_time_elapsed := round(extract('epoch' from clock_timestamp() - total_time_start)::numeric, 2);
        processed_rows := processed_rows + affected_rows;

        IF cycles > 16 THEN
            estimated_time := ((total_rows * total_time_elapsed / processed_rows - total_time_elapsed)::int::text || 's')::interval;
        END IF;

        RAISE NOTICE 'Query % processed % rows (id %% %/*cpu_max*/ = (%/*cpu_num*/ - 1) AND id > %) for % sec', cycles, affected_rows, cpu_max, cpu_num, current_start_id, query_time_elapsed;
        RAISE NOTICE 'Total processed % of % rows (% %%)', processed_rows, total_rows, round(processed_rows * 100.0 / total_rows, 2);
        RAISE NOTICE 'Current date time: %, elapsed time: %, estimated time: %', clock_timestamp()::timestamp(0), (clock_timestamp() - total_time_start)::interval(0), COALESCE(estimated_time::text, '?');
        RAISE NOTICE ''; -- just new line

        EXIT WHEN affected_rows < batch_rows OR next_start_id IS NULL;

        IF query_time_elapsed <= time_max THEN
            batch_rows := batch_rows * 2;
        ELSIF batch_rows > 1 THEN
            batch_rows := batch_rows / 2;
        ELSE
            PERFORM pg_sleep(greatest(sqrt(query_time_elapsed * time_max) - time_max, 0)); --try to save DB from overload
        END IF;

    END LOOP;

    RAISE NOTICE 'Done. % rows per second, % queries per second', (processed_rows / total_time_elapsed)::int, round(cycles / total_time_elapsed, 2);

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
              AND id % $4/*cpu_max*/ = ($3/*cpu_num*/ - 1)
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
              AND id % $4/*cpu_max*/ = ($3/*cpu_num*/ - 1)
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
