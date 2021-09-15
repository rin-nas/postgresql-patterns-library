Ссылки с примерами SQL запросов

# Хабр

   1. **https://m.habr.com/en/company/yandex/blog/435880/** — Изменение схемы таблиц PostgreSQL без долгих блокировок. Лекция Яндекса (дать пример оптимизации миграции Version20190516085945.php)
   1. https://habr.com/post/228023/ — Работа с геолокациями в режиме highload (Задача поиска ближайшего соседа)
   1. https://habr.com/post/280912/ — Полезные трюки PostgreSQL
   1. https://habr.com/ru/company/postgrespro/blog/448368/ — SQL: задача о рабочем времени. [Лучшее решение](https://habr.com/ru/company/postgrespro/blog/448368/#comment_20187570).
   1. https://habr.com/ru/company/0/blog/316304/ Как заставить PostgreSQL считать быстрее
   1. https://m.habr.com/ru/post/468463/ - Улучшение производительности Zabbix + PostgreSQL при помощи партиционирования и индексирования
      1. https://github.com/Doctorbal/zabbix-postgres-partitioning
   3. https://m.habr.com/ru/company/otus/blog/472364/ - PostgreSQL и настройки согласованности записи для каждого конкретного соединения
   4. https://m.habr.com/ru/post/481556/ - Очередь задач в PostgreSQL

# GitHub
   1. https://github.com/dataegret/pg-utils Useful DBA tools by Data Egret
   1. https://github.com/pgexperts/pgx_scripts/ A collection of useful little scripts for database analysis and administration, created by our team at PostgreSQL Experts
      1. index_bloat_checksql
      1. table_bloat_checksql
      1. fk_no_indexsql
      1. duplicate_indexes_fuzzysql
      1. needed_indexessql
      1. unneeded_indexessql
   1. https://github.com/k1aus/parallelsql - A sql extenstion that parallizes sql queries using dblink
      1. https://tech.binary.com/parallel-query-without-parallel-query/
      1. https://chumaky.team/blog/postgres-parallel-jobs
   1. https://github.com/ioguix/pgsql-bloat-estimation - Queries to mesure statistical bloat in btree indexes and tables for PostgreSQL
   1. https://github.com/lesovsky/uber-scripts - Scripts for Linux system administrators
   1. https://github.com/NikolayS/postgres_dba - The missing set of useful tools for Postgres DBA
   1. https://github.com/NikolayS/awesome-postgres - links
   1. https://github.com/Basje/postgres-domains - validation
   2. https://gist.github.com/david-sanabria/0d3ff67eb56d2750502aed4186d6a4a7 - `CREATE OR REPLACE FUNCTION base62_encode( long_number bigint ) RETURNS text`

# StackOverflow
   1. https://stackoverflow.com/questions/7923237/return-pre-update-column-values-using-sql-only
   1. https://stackoverflow.com/questions/11532550/atomic-update-select-in-postgres
   1. https://stackoverflow.com/questions/28550679/what-is-the-difference-between-lateral-and-a-subquery-in-postgresql
   1. https://stackoverflow.com/questions/8443716/postgres-unique-constraint-for-array
   1. https://dba.stackexchange.com/questions/11329/monitoring-progress-of-index-construction-in-postgresql
   1. https://stackoverflow.com/questions/34657669/find-rows-where-text-array-contains-value-similar-to-input
   1. https://stackoverflow.com/questions/3994556/eliminate-duplicate-array-values-in-postgres
   1. https://stackoverflow.com/questions/3942258/how-do-i-temporarily-disable-triggers-in-postgresql
   1. https://stackoverflow.com/questions/38112379/disable-postgresql-foreign-key-checks-for-migrations

# Other
   1. https://www.citusdata.com/blog/2018/02/22/seven-tips-for-dealing-with-postgres-locks/
   1. http://cwestblog.com/2018/10/27/postgresql-query-hierarchical-data-without-recursion/
   1. http://cwestblog.com/2018/10/29/postgresql-recursively-query-hierarchical-data/
   1. http://www.pateldenish.com/2018/11/postgres-11-partitioning.html
   1. https://use-the-index-luke.com/no-offset — Как правильно делать постраничную навигацию без OFFSET
   1. https://www.jooq.org/sakila — БД, для которой есть примеры SQL запросов в документации MySQL
   1. https://pgloader.io/ —  Continuous Migration from your current database to PostgreSQL
   1. https://tapoueh.org/blog/2013/08/understanding-window-functions/ — Understanding Window Functions
   1. https://blog.jooq.org/2014/04/29/nosql-no-sql-how-to-calculate-running-totals/ — How to Calculate Running Totals
   1. https://hashrocket.com/blog/posts/faster-json-generation-with-postgresql — генерация JSON 
   1. https://tapoueh.org/blog/2018/05/postgresql-data-types-point/ (см. запрос с итоговыми суммами и диаграммами внизу)
   1. [задача параллельной многопроцессной обработки очереди](http://dklab.ru/chicken/nablas/53.html), обсуждение на [форуме](https://www.sql.ru/forum/681777/obsuzhdaem-blokirovki-pg-try-advisory-lock)
   1. https://pgday.ru/files/pgmaster14/max.boguk.query.optimization.pdf (оптимизация запросов)
   1. https://pgday.ru/presentation/232/5964945ea4142.pdf Учим слона танцевать
рок-н-ролл (оптимизация запросов)
   1. http://tatiyants.com/how-to-navigate-json-trees-in-postgres-using-recursive-ctes/
   1. https://wiki.postgresql.org/wiki/Category:Performance_Snippets
   1. https://wiki.postgresql.org/wiki/Index_Maintenance
   1. https://postgres.cz/wiki/PostgreSQL_SQL_Tricks
   1. https://pgday.ru/ru/2016/papers/62 Where is the space, Postgres?
   1. https://pgcookbook.ru/index.html
   1. https://wiki.postgresql.org/wiki/ArrXor
   1. http://akorotkov.github.io/blog/2016/06/17/faceted-search/ Фасетный поиск
   1. https://postgrespro.ru/media/2016/11/08/pgconfeu-fts-2016.pdf Better Full Text Search in PostgreSQL
   1. http://sqlfiddle.postgrespro.ru/ - песочница
   1. https://www.percona.com/blog/2019/07/22/automatic-index-recommendations-in-postgresql-using-pg_qualstats-and-hypopg/
   1. https://tech.binary.com/lock-contention-in-postgres/ (интересный способ уменьшить блокировки)
   1. **https://dataedo.com/kb/query/** Useful queries for popular relational databases to explore schema. Database Data Dictionary Query Toolbox
   1. https://aws.amazon.com/ru/blogs/database/validating-database-objects-after-migration-using-aws-sct-and-aws-dms/ Validating database objects after migration using AWS SCT and AWS DMS
   1. http://morozovsk.blogspot.com/2011/07/array-function-arraydiff-in-postgresql.html `array_diff()` и `array_intersect()` и др.
   1. https://begriffs.com/posts/2017-08-27-deferrable-sql-constraints.html
   1. https://begriffs.com/posts/2017-10-21-sql-domain-integrity.html
   1. https://begriffs.com/posts/2018-03-20-user-defined-order.html
      1. https://ru.wikipedia.org/wiki/Дерево_Штерна_—_Броко
      1. https://www.youtube.com/watch?v=qPeD87HJ0UA&ab_channel=InsightsintoMathematics
      1. https://wiki.postgresql.org/wiki/User-specified_ordering_with_fractions
      2. https://github.com/begriffs/pg_rational
      3. https://begriffs.com/pdf/dec2frac.pdf

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

# TODO

1. Рассказать, как Postgresql можно обойтись без SQL_CALC_FOUND_ROWS и почему это лучше.
1. /rdw/x/-/blob/develop/src/Rdw/X/NameSurnameSecondNameExtractor.php переделать на SQL
1. https://git.rabota.space/rdw/rabota/x/-/merge_requests/13065/diffs#6a9cd44f5721f71f7e332362e696dc0807f49448 CORE-474 Дать возможность в триггере для определения пола указывать пол явно - см. триггеры

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
  1. https://postgrespro.ru/docs/postgresql/11/logical-replication
  1. https://blog.codacy.com/how-to-update-large-tables-in-postgresql/
  1. https://dba.stackexchange.com/questions/41059/optimizing-bulk-update-performance-in-postgresql
  1. https://m.habr.com/en/company/lanit/blog/351160/ - PostgreSQL. Ускоряем деплой в семь раз с помощью «многопоточки»
  1. https://habr.com/ru/post/481610/ - PostgreSQL Antipatterns: обновляем большую таблицу под нагрузкой

```sql
explain
with recursive fizzbuzz (num,val) as (
    select 0, false
    union
    select (num + 1),
           (num + 1) % 3 = 0
    from fizzbuzz
    where num < 100
    )
select num, val
from fizzbuzz
where num > 0;
```

```sql
SELECT to_char(last_event_at, 'YYYY-MM-DD') as calls_date, COUNT(*) AS cnt
FROM cts__cdr
WHERE last_event_at > '2021-01-01'
GROUP BY calls_date
ORDER BY calls_date ASC
limit 100;

--vs

SELECT last_event_at::date as calls_date, COUNT(*) AS cnt
FROM cts__cdr
WHERE last_event_at > '2021-01-01'
GROUP BY calls_date
ORDER BY calls_date ASC
limit 100;
```

MySQL's [`make_set()`](https://dev.mysql.com/doc/refman/8.0/en/string-functions.html#function_make-set) function equivalent:
```sql
select to_json(array_agg(name))
from unnest(array['a','b','c', 'd']::text[]) with ordinality as s(name, num)
where 10 & (1 << (num::int-1)) > 0;

select array_agg(name)
from unnest(string_to_array('a,b,c,d', ',')) with ordinality as s(name, num)
where 10 & (1 << (num::int-1)) > 0;
```

Как защитить БД от внезапных нагрузок, создаваемых приложениями? Например в периодически запускаемых фоновых (background) задачах.
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

Битовый тип годится только для хранения > 64 вариантов значений (битов). Обоснование:
```sql
select pg_column_size(0::smallint), --2 байта
       pg_column_size(0::int), --4
       pg_column_size(0::bigint), --8
       pg_column_size(0::bit(8)), --9
       pg_column_size(0::bit(16)) --10
```
