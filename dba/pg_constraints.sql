--Find the Constraints in your Database
--source: https://www.crunchydata.com/blog/postgres-constraints-for-newbies
SELECT * FROM (
    SELECT
       c.connamespace::regnamespace::text as table_schema,
       c.conrelid::regclass::text as table_name,
       con.column_name,
       c.conname as constraint_name,
       pg_get_constraintdef(c.oid)
    FROM
        pg_constraint c
    JOIN
        pg_namespace ON pg_namespace.oid = c.connamespace
    JOIN
        pg_class ON c.conrelid = pg_class.oid
    LEFT JOIN
        information_schema.constraint_column_usage con ON
        c.conname = con.constraint_name AND pg_namespace.nspname = con.constraint_schema
    UNION ALL
    SELECT
        table_schema, table_name, column_name, NULL, 'NOT NULL'
    FROM information_schema.columns
    WHERE
        is_nullable = 'NO'
) all_constraints
WHERE
    table_schema NOT IN ('pg_catalog', 'information_schema')
ORDER BY table_schema, table_name, column_name, constraint_name
;
