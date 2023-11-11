create or replace function public.is_table_column(
    schema_name text,
    table_name text,
    column_name text
)
    returns boolean
    immutable
    returns null on null input
    parallel safe -- Postgres 10 or later
    language sql
    set search_path = ''
as
$$
    select exists (
        select n.nspname as schema_name,
               c.relname as table_name,
               a.attname as column_name
        from pg_namespace as n
        join pg_class as c on n.oid = c.relnamespace
                          and c.relkind = 'r' --relation
                          and c.relname = is_table_column.table_name
        join pg_attribute as a on c.oid = a.attrelid
                              and a.attname = is_table_column.column_name
        where n.nspname = is_table_column.schema_name
    );
$$;

create or replace function public.is_table_column(
    r public.table_column_type
)
    returns boolean
    immutable
    returns null on null input
    parallel safe -- Postgres 10 or later
    language sql
    set search_path = ''
as
$$
    select public.is_table_column(
        is_table_column.r.schema::text,
        is_table_column.r.table::text,
        is_table_column.r.column
    );
$$;

--TEST
do $$
    begin
        --positive
        assert public.is_table_column('pg_catalog', 'pg_class', 'relname');
        assert public.is_table_column(row('pg_catalog', 'pg_class', 'relname'));

        --negative
        assert not public.is_table_column('pg_catalog_unknown', 'pg_class', 'relname');
        assert not public.is_table_column('pg_catalog', 'pg_class_unknown', 'relname');
        assert not public.is_table_column('pg_catalog', 'pg_class', 'relname_unknown');
        assert not public.is_table_column(row('pg_catalog', 'pg_class', 'relname_unknown'));
    end;
$$;
