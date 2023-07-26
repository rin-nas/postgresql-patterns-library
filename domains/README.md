# Domains list

```sql
SELECT n.nspname AS schema
     , t.typname AS name
     , pg_catalog.format_type(t.typbasetype, t.typtypmod) AS underlying_type
     , t.typnotnull AS not_null
     , (SELECT c.collname
        FROM   pg_catalog.pg_collation c, pg_catalog.pg_type bt
        WHERE  c.oid = t.typcollation AND bt.oid = t.typbasetype AND t.typcollation <> bt.typcollation) AS collation
     , t.typdefault AS default
     , pg_catalog.array_to_string(ARRAY(SELECT pg_catalog.pg_get_constraintdef(r.oid, TRUE) FROM pg_catalog.pg_constraint r WHERE t.oid = r.contypid), ' ') AS check_constraints
FROM pg_catalog.pg_type t
LEFT JOIN pg_catalog.pg_namespace n ON n.oid = t.typnamespace
WHERE t.typtype = 'd'  -- domains
  AND n.nspname <> 'pg_catalog'
  AND n.nspname <> 'information_schema'
  AND pg_catalog.pg_type_is_visible(t.oid)
ORDER BY 1, 2;
```
