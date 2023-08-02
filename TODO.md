
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

# Создание GIN индекса для uuid[]

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

# Как узнать стратегию хранения колонок для таблицы?

```sql
select att.attname,
    case att.attstorage
       when 'p' then 'plain'
       when 'm' then 'main'
       when 'e' then 'external'
       when 'x' then 'extended'
       end as attstorage
from pg_attribute att
join pg_class tbl on tbl.oid = att.attrelid
join pg_namespace ns on tbl.relnamespace = ns.oid
where tbl.relname = 'cts__cdr'
  and ns.nspname = 'public'
  and not att.attisdropped;
```

# Лайвхак по добыванию свободного места в БД

Имеется таблица
```sql
create table person_password_log
(
    id                   integer generated by default as identity
        primary key,
    person_id            integer                                   not null
        references person
            on update cascade on delete cascade,
    password_hash        varchar(60)                               not null
        constraint person_password_log_password_hash_check
            check (octet_length((password_hash)::text) = 60),
    created_at           timestamp(0) with time zone default now() not null,
    http_request_headers jsonb,
    request_remote_addr  inet,
    session_id           varchar(128),
    is_auto_generated    boolean
);

comment on table person_password_log is 'История изменений паролей пользователей';
comment on column person_password_log.id is 'ID записи';
comment on column person_password_log.person_id is 'ID персоны';
comment on column person_password_log.password_hash is 'Соль и хеш от пароля в формате bcrypt';
comment on column person_password_log.created_at is 'Дата-время создания';
comment on column person_password_log.http_request_headers is 'Заголовки HTTP запроса в формате ключ-значение';
comment on column person_password_log.request_remote_addr is 'IP адрес запроса';
comment on column person_password_log.session_id is 'ID сессии, значение из session.sid';
comment on column person_password_log.is_auto_generated is 'Признак генерации пароля системой';
```

В таблице есть разные колонки и ещё `http_request_headers`, `request_remote_addr`, `session_id`.
По данным этих колонок можно обнаруживать роботов, спам, делать аналитику и др.
Для этого интересны только "свежие" данные за последние N месяцев.
В таком случае данные старше N месяцев можно очищать (присваивать этим полям NULL).

Узнаём, сколько примерно места занимают данные:
```sql
select count(*),
       sum(pg_column_size(http_request_headers) +
           pg_column_size(request_remote_addr) +
           pg_column_size(session_id) +
           pg_column_size(is_auto_generated)) as size
from public.person_password_log as t
where created_at < now() - interval '1 year'
  and (http_request_headers is not null
       or request_remote_addr is not null
       or session_id is not null
       or is_auto_generated is not null
  ); 
```

Удаляем уже ненужные данные:
```sql
update public.person_password_log
set http_request_headers = null,
    request_remote_addr  = null,
    session_id           = null,
    is_auto_generated    = null
where created_at < now() - interval '1 year'
  and (http_request_headers is not null
    or request_remote_addr is not null
    or session_id is not null
    or is_auto_generated is not null);
```

# Улучшаем сжатие TOAST (лайвхак)

```
-- смотрим, как сжимаются данные в механизме TOAST
with t as (
    select id,
           history,
           pg_column_size(history) as "varchar",
           pg_column_size(history::json) as "json",
           pg_column_size(history::jsonb) as "jsonb"
    from public.cts__cdr
    limit 100000
)
select pg_size_pretty(sum("varchar")) as varchar_compressed, --108 MB
       pg_size_pretty(sum("json")) as json_uncompressed, --161 MB
       pg_size_pretty(sum("jsonb")) as jsonb_uncompressed --180 MB
from t;

-- https://postgrespro.ru/docs/postgresql/12/storage-toast
alter table cts__cdr alter column history set storage main; --запрос ничего не блокирует, текущие данные не изменяются

select sum(pg_column_size(history)) --11,424,009
from public.cts__cdr
where id < 10000;

update public.cts__cdr
--set history = trim(history)
set history = rpad(history, 2000, ' ')
where id < 10000 and octet_length(history) < 2000;

select sum(pg_column_size(history)) --6,294,649
from public.cts__cdr
where id < 10000;
```
Значит, можно сделать триггер и обновить все записи для TOAST сжатия.

# primary_key_columns

source https://supabase.com/blog/audit

```sql
create or replace function audit.primary_key_columns(entity_oid oid)
    returns text[]
    stable
    security definer
    language sql
as $$
    -- Looks up the names of a table's primary key columns
    select
        coalesce(
            array_agg(pa.attname::text order by pa.attnum),
            array[]::text[]
        ) column_names
    from
        pg_index pi
        join pg_attribute pa
            on pi.indrelid = pa.attrelid
            and pa.attnum = any(pi.indkey)
    where
        indrelid = $1
        and indisprimary
$$;
```
# Find indexes with a high ratio of NULL values

source: 
* https://github.com/pawurb/ruby-pg-extras/blob/master/lib/ruby_pg_extras/queries/null_indexes.sql
* https://habr.com/ru/company/otus/blog/672102/

SQL query small improved

```sql
SELECT
    --c.oid,
    --c.relname AS index,
    pg_size_pretty(pg_relation_size(c.oid)) AS index_size_pretty,
    i.indisunique AS unique,
    a.attname AS indexed_column,
    to_char(s.null_frac * 100, '999.00%') AS null_frac,
    pg_size_pretty(e.expected_saving) AS expected_saving_pretty
    , ixs.indexdef -- Uncomment to include the index definition
FROM
    pg_class c
    JOIN pg_index i ON i.indexrelid = c.oid
    JOIN pg_attribute a ON a.attrelid = c.oid
    JOIN pg_class c_table ON c_table.oid = i.indrelid
    JOIN pg_indexes ixs ON c.relname = ixs.indexname
    LEFT JOIN pg_stats s ON s.tablename = c_table.relname AND a.attname = s.attname
    JOIN LATERAL ( SELECT (pg_relation_size(c.oid) * s.null_frac)::bigint AS expected_saving ) AS e ON e.expected_saving > 0
WHERE
    NOT i.indisprimary -- Primary key cannot be partial
    AND i.indpred IS NULL -- Exclude already partial indexes
    AND array_length(i.indkey, 1) = 1 -- Exclude composite indexes
    AND pg_relation_size(c.oid) > 10 * 1024 ^ 2 -- Larger than 10MB
    AND s.null_frac * 100 > 5 -- Larger than 5%
ORDER BY
    e.expected_saving DESC;
```

# `html_strip_tags()` develop

```sql
select id,
       description as html,
       r6.s as text
from vacancy
--convert html to text, последовательность шагов обработки важна!
cross join regexp_replace(description, '</?(br|li|p)\M[^>]*>', e'\n', 'gi') as r1(s) --заменяем блочные html теги на перенос строки
cross join regexp_replace(r1.s, '</?[a-z][^>]*>', ' ', 'gi') as r2(s) --заменяем html теги на пробел
cross join html_entity_decode(r2.s) as r3(s) -- см. PHP html_entity_decode(), https://github.com/rin-nas/postgresql-patterns-library/blob/master/functions/html_entity_decode.sql
cross join regexp_replace(r3.s, '(?:\s(?<![\n\r]))+', ' ', 'g') as r4(s) --заменяем несколько пробельных символов на один пробел
cross join regexp_replace(r4.s, '\s*[\n\r]\s*', e'\n', 'g') as r5(s) --заменяем несколько переносов строк на один перенос
cross join trim(r5.s, e' \n') as r6(s) --вырезаем первые и последние пробелы и переносы строк
```

# Как восстановить значение последовательности, если оно отстало

```sql
select setval(pg_get_serial_sequence('paid_services.kpi_bars', 'id'), max(id), true)
from paid_services.kpi_bars;
```
