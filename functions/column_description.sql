create or replace function column_description(
    table_name regclass,
    column_name name,
    new_description text default null
)
    returns text
    volatile --COMMENT is not allowed in a non-volatile function
    --returns null on null input
    parallel safe -- Postgres 10 or later
    language plpgsql
    set search_path = ''
as
$$
declare
    rec record;
    query text not null default 'comment on column %I.%I.%I is %L';
begin
    if table_name is null or column_name is null then
        return null;
    end if;

    select
        ns.nspname as table_schema,
        c.relname as table_name,
        a.attname as column_name,
        --atttypid::regtype as data_type,
        col_description(a.attrelid, a.attnum) as description
    into rec
    from pg_catalog.pg_attribute as a
    join pg_catalog.pg_class as c on c.oid = a.attrelid
    join pg_catalog.pg_namespace as ns on c.relnamespace = ns.oid
    where a.attrelid = table_name
      and a.attname = column_name
      and a.attnum > 0        -- hide system columns
      and not a.attisdropped;  -- hide dead/dropped columns

    if new_description is null then
        return rec.description;
    end if;

    query := format(query, rec.table_schema, rec.table_name, rec.column_name, new_description);
    --raise notice '%', query;
    execute query;
    return new_description;
end;
$$;

comment on function column_description is 'Get or set table column description, like COMMENT ON COLUMN command, but it can set description dynamically';

--TEST

do $$
begin
    create schema if not exists test;
    create table test.d(i int);

    assert column_description('test.d'::regclass, 'i') is null; --GET
    assert column_description('test.d'::regclass, 'i', 'col''i') = 'col''i'; --SET

    drop table test.d;
end
$$;
