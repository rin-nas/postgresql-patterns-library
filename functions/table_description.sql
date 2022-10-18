create or replace function table_description(
    table_name regclass,
    new_description text default null
)
    returns text
    volatile --COMMENT is not allowed in a non-volatile function
    --returns null on null input
    parallel safe -- Postgres 10 or later
    language plpgsql
as
$$
declare
    rec record;
    query text not null default 'comment on table %I.%I is %L';
begin
    if table_name is null then
        return null;
    elsif new_description is null then
        return obj_description(table_name, 'pg_class');
    end if;

    SELECT ns.nspname as table_schema, c.relname as table_name
    INTO rec
    FROM pg_catalog.pg_class AS c
    JOIN pg_catalog.pg_namespace AS ns ON c.relnamespace = ns.oid
    WHERE c.oid = table_name;

    query := format(query, rec.table_schema, rec.table_name, new_description);
    --raise notice '%', query;
    execute query;
    return new_description;
end;
$$;

comment on function table_description is 'Get or set table description, like COMMENT ON TABLE command, but it can set description dynamically';

--TEST

do $$
begin
    create schema if not exists test;
    create table test.d();

    assert table_description('test.d'::regclass) is null;
    assert table_description('test.d'::regclass, 'table''d') = 'table''d';

    drop table test.d;
end
$$;
