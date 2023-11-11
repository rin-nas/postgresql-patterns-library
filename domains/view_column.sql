create domain public.view_column as public.view_column_type check(
    public.is_view_column(value)
);

--TEST
do $$
    begin
        assert not row('pg_catalog', 'pg_config', 'name')::public.view_column is null;
    end;
$$;
