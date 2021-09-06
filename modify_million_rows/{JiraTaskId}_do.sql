-- Запросы выполнять НЕ в транзакции!

DO $do$
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
    -- в этом запросе нужно исправить только название временной таблицы, остальное не трогать!
    cur CURSOR FOR SELECT * FROM {table}_{JiraTaskId} ORDER BY id; -- здесь д.б. именно временная таблица, сортировка по id обязательна!
    time_max constant numeric default 1; -- пороговое максимальное время выполнения 1-го запроса, в секундах (рекомендуется 1 секунда)
    cpu_num constant smallint default 1; -- для распараллеливания скрипта для выполнения через {JiraTaskId}_do.sh: номер текущего ядра процессора
    cpu_max constant smallint default 1; -- для распараллеливания скрипта для выполнения через {JiraTaskId}_do.sh: максимальное количество ядер процессора
    --connection_str text default 'host=test dbname=test user=test password=test'; -- uncomment this line if you use PosgreSQL < 11
    
BEGIN
    RAISE NOTICE 'Calculate total rows%', ' ';
 
    -- в этом запросе нужно исправить только название временной таблицы, остальное не трогать!
    SELECT COUNT(*) INTO total_rows FROM {table}_{JiraTaskId};
    
    -- uncomment next command if you use PosgreSQL < 11
    -- PERFORM dblink_connect(connection_str);
 
    FOR rec_start IN cur LOOP
        cycles := cycles + 1;
 
        --EXIT WHEN cycles > 20; -- для отладки
 
        FETCH RELATIVE (batch_rows - 1) FROM cur INTO rec_stop;
 
        IF rec_stop IS NULL THEN
            batch_rows := total_rows - processed_rows;
            FETCH LAST FROM cur INTO rec_stop;
        END IF;
 
        query_time_start := clock_timestamp();
 
            -- напишите здесь запрос для добавления записей (PosgreSQL > 10):
            INSERT INTO ...
            SELECT ...
            FROM ... AS t
            WHERE t.id % cpu_max = (cpu_num - 1)
              AND t.id BETWEEN rec_start.id AND rec_stop.id;
             
            -- или напишите здесь запрос для удаления записей (PosgreSQL > 10):
            DELETE FROM {table}
            WHERE id % cpu_max = (cpu_num - 1)
              AND id BETWEEN rec_start.id AND rec_stop.id;
 
            -- или напишите здесь запрос для обновления записей (PosgreSQL > 10):
            UPDATE {table} AS n
            SET {column} = t.{column}, ...
            FROM {table}_{JiraTaskId} AS t
            WHERE t.id % cpu_max = (cpu_num - 1)
              AND t.id = n.id AND t.id BETWEEN rec_start.id AND rec_stop.id;
            
            -- для PosgreSQL < 11 выполнение команд должно быть через dblink:
            /*
            PERFORM dblink_exec('
                UPDATE {table} AS n
                SET ...
                FROM {table}_{JiraTaskId} AS t
                WHERE t.id % ' || cpu_max || ' = (' || cpu_num || ' - 1)
                AND t.id = n.id AND t.id BETWEEN ' || rec_start.id || ' AND ' || rec_stop.id
            );
            */
 
            -- comment next command if you use PosgreSQL < 11
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
    
    -- uncomment next command if you use PosgreSQL < 11
    -- PERFORM dblink_disconnect();
 
    RAISE NOTICE 'Done. % rows per second, % queries per second', (processed_rows / total_time_elapsed)::int, round(cycles / total_time_elapsed, 2);
 
END
$do$;
