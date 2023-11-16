create type public.view_column_type as (
    "schema" regnamespace,
    "view"   regclass,
    "column" pg_catalog.name
);
