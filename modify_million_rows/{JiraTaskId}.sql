-- Запросы выполнять НЕ в транзакции!
 
VACUUM VERBOSE ANALYZE {table};
 
-- сначала выполняем все тяжёлые вычисления
-- подготавливаем в таблице данные для последующего обновления: id, поля со старыми и/или новыми данными (при необходимости)
-- или подготавливаем в таблице данные для последующего удаления: id и все остальные поля
-- таблица является резервной копией для возможности отката
CREATE TABLE IF NOT EXISTS {table}_{JiraTaskId} AS
SELECT id/*значения в колонке id должны быть уникальными!*/, ...
FROM {table}, ...
WHERE ...;
 
CREATE UNIQUE INDEX IF NOT EXISTS {table}_{JiraTaskId}_uniq_id ON {table}_{JiraTaskId} (id);
 
--SELECT * FROM {table}_{JiraTaskId} ORDER BY id LIMIT 100; -- для отладки
 
DO $$
DECLARE
    -- private variables (do not edit):
    total_time_start timestamp default clock_timestamp();
    total_time_elapsed numeric default 0; -- время выполнения всех запросов, в секундах
    query_time_start timestamp;
    query_time_elapsed numeric default 0; -- фактическое время выполнения 1-го запроса, в секундах
    estimated_time interval default null; -- оценочное время, сколько осталось работать
    rec_start record;
    rec_stop record;
    cycles int default 0; -- счётчик для цикла
    batch_rows int default 1; -- по сколько записей будем обновлять за 1 цикл
    processed_rows int default 0; -- счётчик, сколько записей обновили, увеличивается на каждой итерации цикла
    total_rows int default 0; -- количество записей всего
    -- public variables (need to edit):
    cur CURSOR FOR SELECT * FROM {table}_{JiraTaskId} ORDER BY id; -- сортировка по id обязательна!
    time_max constant numeric default 1; -- пороговое максимальное время выполнения 1-го запроса, в секундах
    cpu_num constant smallint default 1; -- для распараллеливания скрипта для выполнения через bash и psql: номер текущего ядра процессора
    cpu_max constant smallint default 1; -- для распараллеливания скрипта для выполнения через bash и psql: максимальное количество ядер процессора
BEGIN
    RAISE NOTICE 'Calculate total rows%', ' ';
 
    SELECT COUNT(*) INTO total_rows FROM {table}_{JiraTaskId};
 
    FOR rec_start IN cur LOOP
        cycles := cycles + 1;
 
        --EXIT WHEN cycles > 15; -- для отладки
 
        FETCH RELATIVE (batch_rows - 1) FROM cur INTO rec_stop;
 
        IF rec_stop IS NULL THEN
            batch_rows := total_rows - processed_rows;
            FETCH LAST FROM cur INTO rec_stop;
        END IF;
 
        query_time_start := clock_timestamp();
 
            -- напишите здесь запрос для добавления записей:
            INSERT INTO ...
            SELECT ...
            FROM ... AS t
            WHERE t.id % cpu_max = (cpu_num - 1)
              AND t.id BETWEEN rec_start.id AND rec_stop.id;
 
            -- или напишите здесь запрос для обновления записей:
            UPDATE {table} AS n
            SET ...
            FROM {table}_{JiraTaskId} AS t
            WHERE t.id % cpu_max = (cpu_num - 1)
              AND t.id = n.id AND t.id BETWEEN rec_start.id AND rec_stop.id;
             
            -- или напишите здесь запрос для удаления записей:
            DELETE FROM {table}
            WHERE id % cpu_max = (cpu_num - 1)
              AND id BETWEEN rec_start.id AND rec_stop.id;
 
            -- comment next command if you use PosgreSQL < 11, but you will have one big long transaction
            COMMIT; -- https://www.postgresql.org/docs/11/plpgsql-transactions.html
 
        query_time_elapsed := round(extract('epoch' from clock_timestamp() - query_time_start)::numeric, 2);
        total_time_elapsed := round(extract('epoch' from clock_timestamp() - total_time_start)::numeric, 2);
        processed_rows := processed_rows + batch_rows;
 
        IF cycles > 16 THEN
            estimated_time := ((total_rows * total_time_elapsed / processed_rows - total_time_elapsed)::int::text || 's')::interval;
        END IF;
 
        RAISE NOTICE 'Query % processed % rows (id %% % = (% - 1) AND id BETWEEN % AND %) for % sec', cycles, batch_rows, cpu_max, cpu_num, rec_start.id, rec_stop.id, query_time_elapsed;
        RAISE NOTICE 'Total processed % of % rows (% %%)', processed_rows, total_rows, round(processed_rows * 100.0 / total_rows, 2);
        RAISE NOTICE 'Current date time: %, elapsed time: %, estimated time: %', clock_timestamp()::timestamp(0), (clock_timestamp() - total_time_start)::interval(0), COALESCE(estimated_time::text, '?');
        RAISE NOTICE '%', ' '; -- just new line
 
        IF query_time_elapsed < time_max THEN
            batch_rows := batch_rows * 2;
        ELSE
            batch_rows := GREATEST(1, batch_rows / 2);
        END IF;
 
    END LOOP;
 
    RAISE NOTICE 'Done. % rows per second, % queries per second', (processed_rows / total_time_elapsed)::int, round(cycles / total_time_elapsed, 2);
 
END
$$;
 
VACUUM VERBOSE ANALYZE {table};
