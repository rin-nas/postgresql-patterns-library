create domain public.table_column as public.table_column_type check(
    public.is_table_column(value)
);

--TEST
do $$
    begin
        assert not row('pg_catalog', 'pg_class', 'relname')::public.table_column is null;
    end;
$$;
