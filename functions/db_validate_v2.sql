--Валидатор схемы БД v2

create or replace function db_validate_v2(
    checks                text[] default null,         -- Коды необходимых проверок
                                                       -- Если передан null - то все возможные проверки
                                                       -- Если передан пустой массив - то ни одной проверки

    schemas_ignore_regexp text default null,           -- Регулярное выражение со схемами, которые нужно проигнорировать
    schemas_ignore        regnamespace[] default null, -- Список схем, которые нужно проигнорировать
                                                       -- В список схем автоматически добавляются служебные схемы "information_schema" и "pg_catalog", указывать их явно не нужно

    tables_ignore_regexp  text default null,           -- Регулярное выражение с таблицами (с указанием схемы), которые нужно проигнорировать
    tables_ignore         regclass[] default null      -- Список таблиц в формате {scheme}.{table}, которые нужно проигнорировать
)
    returns void
    stable
    --returns null on null input
    parallel safe
    language plpgsql
    set search_path = ''
AS $func$
DECLARE
    rec record;
BEGIN

    schemas_ignore := coalesce(schemas_ignore, '{}') || '{information_schema,pg_catalog,pg_toast}';

    -- Наличие первичного или уникального индекса в таблице
    if checks is null or 'has_pk_uk' = any(checks) then
        raise notice 'check has_pk_uk';

        WITH t AS materialized (
            SELECT t.*
            FROM information_schema.tables AS t
            WHERE t.table_type = 'BASE TABLE'
            AND NOT EXISTS(SELECT
                             FROM information_schema.key_column_usage AS kcu
                            WHERE kcu.table_schema = t.table_schema
                              AND kcu.table_name = t.table_name
            )
        )
        SELECT *
        INTO rec
        FROM t
        cross join lateral (select concat_ws('.', quote_ident(t.table_schema), quote_ident(t.table_name))) as p(table_full_name)
        WHERE true
              -- исключаем схемы
              AND (schemas_ignore_regexp is null OR t.table_schema !~ schemas_ignore_regexp)
              AND t.table_schema::regnamespace != ALL (schemas_ignore)
              AND pg_catalog.has_schema_privilege(t.table_schema, 'USAGE') --fix [42501] ERROR: permission denied for schema ...

              -- исключаем таблицы
              AND (tables_ignore_regexp is null OR p.table_full_name !~ tables_ignore_regexp)
              AND (tables_ignore is null OR p.table_full_name::regclass != ALL (tables_ignore))
        ORDER BY t.table_schema, t.table_name
        LIMIT 1;

        IF FOUND THEN
            RAISE EXCEPTION 'Таблица %.% должна иметь первичный или уникальный индекс!', rec.table_schema, rec.table_name;
        END IF;

    end if;

    -- Отсутствие избыточных индексов в таблице
    if checks is null or 'has_not_redundant_index' = any(checks) then
        raise notice 'check has_not_redundant_index';

        WITH index_data AS (
            SELECT x.*,
                   string_to_array(x.indkey::text, ' ')                  as key_array,
                   array_length(string_to_array(x.indkey::text, ' '), 1) as nkeys,
                   am.amname,
                   n.nspname AS table_schema,
                   c.relname AS table_name
            FROM pg_index AS x
            JOIN pg_class AS i ON i.oid = x.indexrelid
            JOIN pg_class c ON c.oid = x.indrelid
            JOIN pg_am am ON am.oid = i.relam
            LEFT JOIN pg_namespace n ON n.oid = c.relnamespace
            WHERE x.indisvalid --игнорируем "нерабочие" индексы, которые ещё создаются командой create index concurrently
        ),
        index_data2 AS (
            SELECT *
            FROM index_data AS t
            cross join lateral (select concat_ws('.', quote_ident(t.table_schema), quote_ident(t.table_name))) as p(table_full_name)
            WHERE true

            -- исключаем схемы
            AND (schemas_ignore_regexp is null OR t.table_schema !~ schemas_ignore_regexp)
            AND t.table_schema::regnamespace != ALL (schemas_ignore)
            AND pg_catalog.has_schema_privilege(t.table_schema, 'USAGE') --fix [42501] ERROR: permission denied for schema ...

            -- исключаем таблицы
            AND (tables_ignore_regexp is null OR p.table_full_name !~ tables_ignore_regexp)
            AND (tables_ignore is null OR p.table_full_name::regclass != ALL (tables_ignore))
        ),
        t AS (
             SELECT
                 i1.indrelid::regclass::text as table_name,
                 pg_get_indexdef(i1.indexrelid)                  main_index,
                 pg_get_indexdef(i2.indexrelid)                  redundant_index,
                 pg_size_pretty(pg_relation_size(i2.indexrelid)) redundant_index_size
             FROM index_data2 as i1
             JOIN index_data2 as i2 ON i1.indrelid = i2.indrelid
                  AND i1.indexrelid <> i2.indexrelid
                  AND i1.amname = i2.amname
             WHERE (regexp_replace(i1.indpred, 'location \d+', 'location', 'g') IS NOT DISTINCT FROM
                    regexp_replace(i2.indpred, 'location \d+', 'location', 'g'))
               AND (regexp_replace(i1.indexprs, 'location \d+', 'location', 'g') IS NOT DISTINCT FROM
                    regexp_replace(i2.indexprs, 'location \d+', 'location', 'g'))
               AND ((i1.nkeys > i2.nkeys and not i2.indisunique)
                 OR (i1.nkeys = i2.nkeys and
                     ((i1.indisunique and i2.indisunique and (i1.indexrelid > i2.indexrelid)) or
                      (not i1.indisunique and not i2.indisunique and
                       (i1.indexrelid > i2.indexrelid)) or
                      (i1.indisunique and not i2.indisunique)))
                 )
               AND i1.key_array[1:i2.nkeys] = i2.key_array
             ORDER BY pg_relation_size(i2.indexrelid) desc,
                      i1.indexrelid::regclass::text,
                      i2.indexrelid::regclass::text
         )
         SELECT DISTINCT ON (redundant_index) t.* INTO rec FROM t LIMIT 1;

        IF FOUND THEN
            RAISE EXCEPTION E'Таблица % уже имеет индекс %\nУдалите избыточный индекс %', rec.table_name, rec.main_index, rec.redundant_index;
        END IF;

    end if;

    -- Наличие индексов для ограничений внешних ключей в таблице
    if checks is null or 'has_index_for_fk' = any(checks) then
        raise notice 'check has_index_for_fk';

        -- запрос для получения FK без индексов, взял по ссылке ниже и модифицировал
        -- https://github.com/NikolayS/postgres_dba/blob/master/sql/i3_non_indexed_fks.sql
        with fk_actions ( code, action ) as (
            values ('a', 'error'),
                   ('r', 'restrict'),
                   ('c', 'cascade'),
                   ('n', 'set null'),
                   ('d', 'set default')
        ), fk_list as (
            select
                pg_constraint.oid as fkoid, conrelid, confrelid as parentid,
                conname,
                relname,
                nspname,
                fk_actions_update.action as update_action,
                fk_actions_delete.action as delete_action,
                conkey as key_cols
            from pg_constraint
            join pg_class on conrelid = pg_class.oid
            join pg_namespace on pg_class.relnamespace = pg_namespace.oid
            join fk_actions as fk_actions_update on confupdtype = fk_actions_update.code
            join fk_actions as fk_actions_delete on confdeltype = fk_actions_delete.code
            where contype = 'f'
        ), fk_attributes as (
            select fkoid, conrelid, attname, attnum
            from fk_list
                     join pg_attribute on conrelid = attrelid and attnum = any(key_cols)
            order by fkoid, attnum
        ), fk_cols_list as (
            select fkoid, array_agg(attname) as cols_list
            from fk_attributes
            group by fkoid
        ), index_list as (
            select
                indexrelid as indexid,
                pg_class.relname as indexname,
                indrelid,
                indkey,
                indpred is not null as has_predicate,
                pg_get_indexdef(indexrelid) as indexdef
            from pg_index
            join pg_class on indexrelid = pg_class.oid
            where indisvalid
        ), fk_index_match as (
            select
                fk_list.*,
                indexid,
                indexname,
                indkey::int[] as indexatts,
                has_predicate,
                indexdef,
                array_length(key_cols, 1) as fk_colcount,
                array_length(indkey,1) as index_colcount,
                round(pg_relation_size(conrelid)/(1024^2)::numeric) as table_mb,
                cols_list
            from fk_list
            join fk_cols_list using (fkoid)
            left join index_list on conrelid = indrelid
                                and (indkey::int2[])[0:(array_length(key_cols,1) -1)] operator(pg_catalog.@>) key_cols

        ), fk_perfect_match as (
            select fkoid
            from fk_index_match
            where (index_colcount - 1) <= fk_colcount
              and not has_predicate
              and indexdef like '%USING btree%'
        ), fk_index_check as (
            select 'no index' as issue, *, 1 as issue_sort
            from fk_index_match
            where indexid is null
            /*union all
            select 'questionable index' as issue, *, 2
            from fk_index_match
            where
                indexid is not null
              and fkoid not in (select fkoid from fk_perfect_match)*/
        ), parent_table_stats as (
            select
                fkoid,
                tabstats.relname as parent_name,
                (n_tup_ins + n_tup_upd + n_tup_del + n_tup_hot_upd) as parent_writes,
                round(pg_relation_size(parentid)/(1024^2)::numeric) as parent_mb
            from pg_stat_user_tables as tabstats
                     join fk_list on relid = parentid
        ), fk_table_stats as (
            select
                fkoid,
                (n_tup_ins + n_tup_upd + n_tup_del + n_tup_hot_upd) as writes,
                seq_scan as table_scans
            from pg_stat_user_tables as tabstats
                     join fk_list on relid = conrelid
        ), result as (
            select
                nspname as schema_name,
                relname as table_name,
                conname as fk_name,
                issue,
                table_mb,
                writes,
                table_scans,
                parent_name,
                parent_mb,
                parent_writes,
                cols_list,
                coalesce(indexdef, 'CREATE INDEX /*CONCURRENTLY*/ ' || relname || '_' || cols_list[1] || ' ON ' ||
                                   quote_ident(nspname) || '.' || quote_ident(relname) || ' (' || quote_ident(cols_list[1]) || ')') as indexdef
            from fk_index_check
                     join parent_table_stats using (fkoid)
                     join fk_table_stats using (fkoid)
            where
                true /*table_mb > 9*/
              and (
                /*    writes > 1000
                or parent_writes > 1000
                or parent_mb > 10*/
                true
                )
              and issue = 'no index'
            order by issue_sort, table_mb asc, table_name, fk_name
            limit 1
        )
        select * into rec from result;

        IF FOUND THEN
            RAISE EXCEPTION E'Отсутствует индекс для внешнего ключа\nДобавьте индекс: %', rec.indexdef;
        END IF;

    end if;

    if checks is null or 'has_table_comment' = any(checks) then
        raise notice 'check has_table_comment';

        select --obj_description((t.table_schema || '.' || t.table_name)::regclass::oid),
               format($$comment on table %I.%I is '...';$$, t.table_schema, t.table_name) as sql
               --*,
               --t.table_schema, t.table_name
        into rec
        from information_schema.tables as t
        cross join lateral (select concat_ws('.', quote_ident(t.table_schema), quote_ident(t.table_name))) as p(table_full_name)
        where t.table_type = 'BASE TABLE'
          and coalesce(trim(obj_description((t.table_schema || '.' || t.table_name)::regclass::oid)), '') in ('', t.table_name)

          -- исключаем схемы
          AND (schemas_ignore_regexp is null OR t.table_schema !~ schemas_ignore_regexp)
          AND t.table_schema::regnamespace != ALL (schemas_ignore)
          AND pg_catalog.has_schema_privilege(t.table_schema, 'USAGE') --fix [42501] ERROR: permission denied for schema ...

          -- исключаем таблицы
          AND (tables_ignore_regexp is null OR p.table_full_name !~ tables_ignore_regexp)
          AND (tables_ignore is null OR p.table_full_name::regclass != ALL (tables_ignore))

          -- исключаем таблицы-секции
          AND NOT EXISTS (SELECT
                          FROM   pg_catalog.pg_inherits AS i
                          WHERE  i.inhrelid = (t.table_schema || '.' || t.table_name)::regclass
          )

        order by 1
        limit 1;

        IF FOUND THEN
            RAISE EXCEPTION E'Для таблицы отсутствует описание или совпадает с названием\nДобавьте его: %', rec.sql;
        END IF;

    end if;

    if checks is null or 'has_column_comment' = any(checks) then
        raise notice 'check has_column_comment';

        select --col_description((c.table_schema || '.' || t.table_name)::regclass::oid, c.ordinal_position) as column_comment,
               format($$comment on column %I.%I.%I is '...';$$, t.table_schema, t.table_name, c.column_name) as sql
        into rec
        from information_schema.columns as c
        inner join information_schema.tables as t on t.table_schema = c.table_schema
                                                 and t.table_name = c.table_name
                                                 and t.table_type = 'BASE TABLE'
        cross join lateral (select concat_ws('.', quote_ident(t.table_schema), quote_ident(t.table_name))) as p(table_full_name)
        where c.column_name != 'id'
          and coalesce(trim(col_description((c.table_schema || '.' || t.table_name)::regclass::oid, c.ordinal_position)), '') in ('', c.column_name)

          -- исключаем схемы
          AND (schemas_ignore_regexp is null OR t.table_schema !~ schemas_ignore_regexp)
          AND t.table_schema::regnamespace != ALL (schemas_ignore)
          AND pg_catalog.has_schema_privilege(t.table_schema, 'USAGE') --fix [42501] ERROR: permission denied for schema ...

          -- исключаем таблицы
          AND (tables_ignore_regexp is null OR p.table_full_name !~ tables_ignore_regexp)
          AND (tables_ignore is null OR p.table_full_name::regclass != ALL (tables_ignore))

          -- исключаем таблицы-секции
          AND NOT EXISTS (SELECT
                          FROM   pg_catalog.pg_inherits AS i
                          WHERE  i.inhrelid = (t.table_schema || '.' || t.table_name)::regclass
          )

        order by 1
        limit 1;

        IF FOUND THEN
            RAISE EXCEPTION E'Для колонки таблицы отсутствует описание или совпадает с названием\nДобавьте его: %', rec.sql;
        END IF;

    end if;

END
$func$;

--alter function db_validate_v2(text[], text, regnamespace[], text, regclass[]) owner to alexan;

-- TEST
-- запускаем валидатор БД
select db_validate_v2(
    --'{has_pk_uk,has_not_redundant_index,has_index_for_fk}', --some checks
    null, --all checks

    null, --schemas_ignore_regexp
    '{unused,migration,test}', --schemas_ignore

    '(?<![a-z])(te?mp|test|unused|backups?|deleted)(?![a-z])|_\d{4}[_\-]\d\d?$', --tables_ignore_regexp
    '{_migration_versions}' --tables_ignore
);


--SELECT EXISTS(SELECT * FROM pg_proc WHERE proname = 'db_validate_v2'); -- проверяем наличие валидатора
