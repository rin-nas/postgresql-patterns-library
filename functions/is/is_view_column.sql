create or replace function public.is_view_column(
    schema_name pg_catalog.name,
    view_name   pg_catalog.name,
    column_name pg_catalog.name
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
                          and c.relkind = 'v' --view
                          and c.relname = is_view_column.view_name
        join pg_attribute as a on c.oid = a.attrelid
                              and a.attname = is_view_column.column_name
        where n.nspname = is_view_column.schema_name
    );
$$;

comment on function public.is_view_column(
    schema_name pg_catalog.name,
    view_name   pg_catalog.name,
    column_name pg_catalog.name
) is 'Check view column exists';

create or replace function public.is_view_column(
    r public.view_column_type
)
    returns boolean
    immutable
    returns null on null input
    parallel safe -- Postgres 10 or later
    language sql
    set search_path = ''
as
$$
    select public.is_view_column(
        is_view_column.r.schema::pg_catalog.name,
        is_view_column.r.view::pg_catalog.name,
        is_view_column.r.column
    );
$$;

comment on function public.is_view_column(
    r public.view_column_type
) is 'Check view column exists';


--TEST
do $$
    begin
        --positive
        assert public.is_view_column('pg_catalog', 'pg_config', 'name');
        assert public.is_view_column(row('pg_catalog', 'pg_config', 'name'));

        --negative
        assert not public.is_view_column('pg_catalog_unknown', 'pg_config', 'name');
        assert not public.is_view_column('pg_catalog', 'pg_config_unknown', 'name');
        assert not public.is_view_column('pg_catalog', 'pg_config', 'name_unknown');
        assert not public.is_view_column(row('pg_catalog', 'pg_config', 'name_unknown'));
    end;
$$;
