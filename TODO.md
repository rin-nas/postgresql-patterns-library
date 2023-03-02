
# Btree, GIN, GIST indexes bloat

source: https://stackoverflow.com/questions/56704625/index-bloat-on-gin-index-for-insert-only-table


```sql
WITH constants AS (
  SELECT current_setting('block_size')::numeric AS bs, 23 AS hdr, 4 AS ma
), bloat_info AS (
  SELECT
    ma,bs,schemaname,tablename,
    (datawidth+(hdr+ma-(case when hdr%ma=0 THEN ma ELSE hdr%ma END)))::numeric AS datahdr,
    (maxfracsum*(nullhdr+ma-(case when nullhdr%ma=0 THEN ma ELSE nullhdr%ma END))) AS nullhdr2
  FROM (
    SELECT
      schemaname, tablename, hdr, ma, bs,
      SUM((1-null_frac)*avg_width) AS datawidth,
      MAX(null_frac) AS maxfracsum,
      hdr+(
        SELECT 1+count(*)/8
        FROM pg_stats s2
        WHERE null_frac<>0 AND s2.schemaname = s.schemaname AND s2.tablename = s.tablename
      ) AS nullhdr
    FROM pg_stats s, constants
    GROUP BY 1,2,3,4,5
  ) AS foo
), table_bloat AS (
  SELECT
    schemaname, tablename, cc.relpages, bs,
    CEIL((cc.reltuples*((datahdr+ma-
      (CASE WHEN datahdr%ma=0 THEN ma ELSE datahdr%ma END))+nullhdr2+4))/(bs-20::float)) AS otta
  FROM bloat_info
  JOIN pg_class cc ON cc.relname = bloat_info.tablename
  JOIN pg_namespace nn ON cc.relnamespace = nn.oid AND nn.nspname = bloat_info.schemaname AND nn.nspname <> 'information_schema'
), index_bloat AS (
  SELECT
    schemaname, tablename, bs,
    COALESCE(c2.relname,'?') AS iname, COALESCE(c2.reltuples,0) AS ituples, COALESCE(c2.relpages,0) AS ipages,
    COALESCE(CEIL((c2.reltuples*(datahdr-12))/(bs-20::float)),0) AS iotta -- very rough approximation, assumes all cols
  FROM bloat_info
  JOIN pg_class cc ON cc.relname = bloat_info.tablename
  JOIN pg_namespace nn ON cc.relnamespace = nn.oid AND nn.nspname = bloat_info.schemaname AND nn.nspname <> 'information_schema'
  JOIN pg_index i ON indrelid = cc.oid
  JOIN pg_class c2 ON c2.oid = i.indexrelid
)
SELECT
  type, schemaname, object_name, bloat, pg_size_pretty(raw_waste) as waste
FROM
(SELECT
  'table' as type,
  schemaname,
  tablename as object_name,
  ROUND(CASE WHEN otta=0 THEN 0.0 ELSE table_bloat.relpages/otta::numeric END,1) AS bloat,
  CASE WHEN relpages < otta THEN '0' ELSE (bs*(table_bloat.relpages-otta)::bigint)::bigint END AS raw_waste
FROM
  table_bloat
    UNION
SELECT
  'index' as type,
  schemaname,
  tablename || '::' || iname as object_name,
  ROUND(CASE WHEN iotta=0 OR ipages=0 THEN 0.0 ELSE ipages/iotta::numeric END,1) AS bloat,
  CASE WHEN ipages < iotta THEN '0' ELSE (bs*(ipages-iotta))::bigint END AS raw_waste
FROM
  index_bloat) bloat_summary
ORDER BY raw_waste DESC, bloat DESC
```

# MySQL to PostgreSQL

1. https://stackoverflow.com/questions/1309624/simulating-mysqls-order-by-field-in-postgresql
1. https://postgres.cz/wiki/PostgreSQL_SQL_Tricks_III#MySQL_function_group_concat_in_PostgreSQL

# UPDATE/DELETE million rows ideas

```sql
LOOP
  UPDATE table SET flag=0 
  WHERE id IN (
      SELECT id 
      FROM table 
      WHERE flag <> 0 
      LIMIT 50000
      FOR UPDATE OF table SKIP LOCKED
  );
   
  IF NOT FOUND THEN
      UPDATE table SET flag=0 
      WHERE id IN (
          SELECT id 
          FROM table 
          WHERE flag <> 0 
          LIMIT 50000
          --FOR UPDATE OF table SKIP LOCKED
      );
  END IF;

  EXIT WHEN NOT FOUND;

  VACUUM ANALYSE table;
END LOOP;
```

```
-- FOR UPDATE of t -- пытаемся заблокировать строки таблицы от изменения в параллельных транзакциях (при этом читать строки можно)
-- NOWAIT -- если строки заблокировать не удалось, выдаём ошибку, а не ждём (строки уже заблокированы в параллельных транзакциях)
-- SKIP LOCKED -- если строки заблокировать не удалось, пропускаем их (они уже заблокированы в параллельных транзакциях)
```

  1. https://postgrespro.ru/docs/postgresql/11/logical-replication
  1. https://blog.codacy.com/how-to-update-large-tables-in-postgresql/
  1. https://m.habr.com/en/company/lanit/blog/351160/ - PostgreSQL. Ускоряем деплой в семь раз с помощью «многопоточки»
  1. https://habr.com/ru/post/481610/ - PostgreSQL Antipatterns: обновляем большую таблицу под нагрузкой

# Как получить дату из поля типа timestamp

```sql
-- медленее:
SELECT to_char(last_event_at, 'YYYY-MM-DD') as calls_date, COUNT(*) AS cnt
FROM cts__cdr
WHERE last_event_at > '2021-01-01'
GROUP BY calls_date
ORDER BY calls_date ASC
limit 100;

--быстрее:
SELECT last_event_at::date as calls_date, COUNT(*) AS cnt
FROM cts__cdr
WHERE last_event_at > '2021-01-01'
GROUP BY calls_date
ORDER BY calls_date ASC
limit 100;
```

# Как защитить БД от внезапных нагрузок, создаваемых приложениями? Например в периодически запускаемых фоновых (background) задачах.

Предполагаемое решение — измерять скорость выполнения каждого запроса (SELECT или DML) в приложении. Если оно превышает N секунд, значит ресурсов БД нехватает и после выполнения запроса приложение нужно замедлить, т.е. "поспать" некоторое время. Это даст "продохнуть" БД и адаптироваться под её нагрузку. Длительность сна можно высчитывать по формуле, отталкиваясь от длительности выполнения запроса. См. распределение значений запросом
```sql
with t as (
    select exec_time,
           round(greatest(sqrt(exec_time * 1) - 1, 0), 2) as sleep_time1,
           round(greatest(sqrt(exec_time * 2) - 2, 0), 2) as sleep_time2,
           round(greatest(sqrt(exec_time * 3) - 3, 0), 2) as sleep_time3
    from generate_series(0.1, 60, 0.1) as exec_time
)
select exec_time,
       sleep_time1, round(sleep_time1 * 100 / exec_time, 0) as percent1,
       sleep_time2, round(sleep_time2 * 100 / exec_time, 0) as percent2,
       sleep_time3, round(sleep_time3 * 100 / exec_time, 0) as percent3
from t
```

# Битовый тип годится только для хранения > 64 вариантов значений (битов)

Обоснование:
```sql
select pg_column_size(0::smallint), --2 байта
       pg_column_size(0::int), --4
       pg_column_size(0::bigint), --8
       pg_column_size(0::bit(8)), --9
       pg_column_size(0::bit(16)) --10
```


# Как быстро получить первые N уникальных значений из колонки таблицы без использования индексов (как я ускорял запрос)

```sql
-- было так
explain -- Limit  (cost=3293253.59..3293254.09 rows=100 width=1037)
select distinct history
from cts__cdr
limit 100;
--execution: > 30m ? (недождался)

explain  -- Limit  (cost=1113569.59..1113582.82 rows=100 width=1069)
select min(history)
from cts__cdr
group by history
limit 100;
--execution: 10 m 6 s

explain --Limit  (cost=1125020.27..1125034.43 rows=100 width=48)
select min(history)
from cts__cdr
group by md5(history)::uuid
limit 100;
--execution: 1 m 20 s


explain -- Limit  (cost=968190.32..968224.11 rows=100 width=1037)
select history
from cts__cdr as t
where not exists(select
                 from cts__cdr as d
                 where d.history = t.history
                   and d.ctid < t.ctid
                   --and d.history is not null
                 )
--and history is not null
limit 100;
--execution: 36 s

-- стало так
-- быстрое решение, но с большим расходом по памяти для больших N
explain --Limit  (cost=1.91..2.02 rows=11 width=32)
with recursive t (ctid, value, values) as (
    (select ctid, history, array[md5(history::text)::uuid]
     from cts__cdr
     limit 1)
    union all
    (select p.ctid, p.history, t.values || md5(p.history::text)::uuid
     from cts__cdr p
     inner join t on p.ctid > t.ctid and md5(p.history::text)::uuid != all(t.values)
     limit 1)
)
select value from t limit 100
--execution: 85 ms
/*
Можно было бы обойтись без колонки values и искать дубликаты подзапросом: WHERE not exists(select from t as d where p.history = d.history)
Но, к сожалению, БД возвращает ошибку [42P19] ERROR: recursive reference to query "t" must not appear within a subquery
*/

-- быстрое, но громоздкое решение с небольшим расходом памяти для больших N, на практике нужно обернуть в функцию
do $$
declare
    rec record;
    counter int default 0;
begin
    create temporary table t (
        v uuid unique
        --v bigint unique
    ) on commit drop;

    FOR rec IN select history as v from cts__cdr
    LOOP
        insert into t (v) values(md5(rec.v)::uuid) on conflict do nothing;
        if FOUND then
            counter := counter + 1;
            EXIT WHEN counter = 100;
        end if;
    END LOOP;

    perform * from t;

end
$$;
--completed in 111 ms
```

# Decode \uXXXX

https://stackoverflow.com/questions/20124393/convert-escaped-unicode-character-back-to-actual-character-in-postgresql/69554541
https://stackoverflow.com/questions/10111654/how-to-convert-literal-u-sequences-into-utf-8

Solution *without* using PL/pgSQL functions and EXECUTE trick, *without* SQL injection vulnerable. Pure SQL.

Query:
```sql
select string_agg(
            case
                when left(m[1], 2) in ('\u', '\U')
                then chr(('x' || lpad(substring(m[1], 3), 8, '0'))::bit(32)::int)
                else m[1]
            end,
            ''
        )
from regexp_matches('\u017D\u010F\u00E1r, Нello \u270C, Привет!\U0001F603', '\\u[\da-fA-F]{4}|\\U[\da-fA-F]{8}|.',  'g') as s(m);
-- TODO \ud83d\ude03 is the same as \U0001F603, but does not work, see https://github.com/rin-nas/php5-utf8/blob/master/UTF8.php#L2546
-- from regexp_matches('\u017D\u010F\u00E1r, Нello \u270C, Привет!\U0001F603 \ud83d\ude03', '\\u[\da-fA-F]{4}|\\U[\da-fA-F]{8}|.',  'g') as s(m);
```

Of course, you can make function from this query to hide implementation and get usability.

# Как очень быстро избавиться от bloat в маленьких таблицах, но очень интенсивных по записи

В таблицах, где записей < 10000, есть очень быстрый способ "огнетушителя" избавиться от bloat. Проверил на прод БД. Всё работает отлично.

```sql
DO $$
    BEGIN
        SET LOCAL lock_timeout TO '3s'; -- Максимальное время блокирования других SQL запросов (простоя веб-сайта) во время миграции. Если будет превышено, то транзакция откатится.
        IF pg_try_advisory_xact_lock('service__workers'::regclass::oid::bigint) THEN -- запрещаем этот код выполняться параллельно (блокировка действует до конца транзакции)
            LOCK TABLE service__workers IN SHARE MODE; -- защищаем таблицу от параллельного изменения данных, при этом читать из таблицы можно (блокировка действует до конца транзакции)
            CREATE TEMPORARY TABLE service__workers__tmp ON COMMIT DROP AS SELECT * FROM service__workers;
            TRUNCATE service__workers; -- немедленно высвобождаем место ОС
            INSERT INTO service__workers SELECT * FROM service__workers__tmp;
        END IF;
    END;
$$;
```

# duplicate indexes

```sql
SELECT pg_size_pretty(sum(pg_relation_size(idx))::bigint) AS size,
       (array_agg(idx))[1] AS idx1, (array_agg(idx))[2] AS idx2,
       (array_agg(idx))[3] AS idx3, (array_agg(idx))[4] AS idx4
FROM (
         SELECT indexrelid::regclass AS idx, (indrelid::text ||E'\n'|| indclass::text ||E'\n'|| indkey::text ||E'\n'||
                                              coalesce(indexprs::text,'')||E'\n' || coalesce(indpred::text,'')) AS KEY
         FROM pg_index) sub
GROUP BY KEY HAVING count(*)>1
ORDER BY sum(pg_relation_size(idx)) DESC;
```

# Создание индекса для uuid[]

```sql
CREATE TABLE someitems (
    items uuid[]
);

CREATE INDEX someitems_items_index ON someitems USING GIN (items); --ERROR:  data type uuid[] has no default operator class for access method "gin"

CREATE OPERATOR CLASS _uuid_ops DEFAULT FOR TYPE _uuid USING gin AS
    OPERATOR 1 &&(anyarray, anyarray),
    OPERATOR 2 @>(anyarray, anyarray),
    OPERATOR 3 <@(anyarray, anyarray),
    OPERATOR 4 =(anyarray, anyarray),
    FUNCTION 1 uuid_cmp(uuid, uuid),
    FUNCTION 2 ginarrayextract(anyarray, internal, internal),
    FUNCTION 3 ginqueryarrayextract(anyarray, internal, smallint, internal, internal, internal, internal),
    FUNCTION 4 ginarrayconsistent(internal, smallint, anyarray, integer, internal, internal, internal, internal),
    STORAGE uuid;
    
SELECT * FROM someitems WHERE items @> ARRAY['171e9457-5242-406d-ab5e-523419794d18']::uuid[];
```

# Progress bar experiment

Пример выгрузки дампа в формате директории:

`pg_dump --username=postgres --host=127.0.0.1 --format=directory --clean --if-exists --dbname=company_review --file=company_review.dir.dump --compress=5 --jobs=10`

Пример загрузки дампа в формате директории:

`pg_restore --username=postgres --dbname=company_review --clean --if-exists --jobs=10 company_review.dir.dump`


## pg_restore
```bash
time (pg_restore --username=postgres --dbname=company_review_tmp --clean --if-exists --jobs=10 --verbose company_review.dir.dump 2>&1 \
      | grep -E '(processing item|finished item)' \
      | pv -l -s $(pg_restore -l company_review.dir.dump | grep -c '^[^;]') \
      > /dev/null)
```
See also [https://www.google.com/search?q=pg_restore+pg_dump+pv] 

# pg_basebackup progress bar, estimated duration and query end


```sql
SET TIME ZONE '+3'; --MSK

select a.query_start,
       e.duration,
       e.progress_percent,
       (e2.estimated_duration || 'sec')::interval as estimated_duration,
       a.query_start + (e2.estimated_duration || 'sec')::interval as estimated_query_end
from pg_stat_progress_basebackup as b
inner join pg_stat_activity as a on a.pid = b.pid
cross join lateral (
    select
        NOW() - query_start as duration,
        backup_streamed * 100.0 / backup_total as progress_percent
) as e
cross join lateral (
    select
        EXTRACT(epoch FROM e.duration) * 100 / e.progress_percent as estimated_duration
) as e2;
```

# COPY progress bar with speed (MB/sec)

```sql
select query_start,
       e.duration,
       pg_size_pretty(bytes_processed) as processed_size,
       pg_size_pretty(bytes_processed / EXTRACT(epoch FROM e.duration)) || '/sec' as speed,
       p.datname as db_name,
       a.query,
       a.application_name
from pg_stat_progress_copy as p
inner join pg_stat_activity as a on p.pid = a.pid
cross join lateral (
    select
        NOW() - query_start as duration
) as e
```

# Parse recursive json:

* https://stackoverflow.com/questions/52773714/postgresql-recursively-parsing-nested-json
* https://stackoverflow.com/questions/69126374/automatically-normalizing-a-postgres-json-column-into-a-new-table
