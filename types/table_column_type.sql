create type public.table_column_type as (
    "schema" regnamespace,
    "table"  regclass,
    "column" pg_catalog.name
);
