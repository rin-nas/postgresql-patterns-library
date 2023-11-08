# DOMAIN vs CHECK CONSTRAINT

So you might be wondering why you would use a domain when you could just use a check constraint on the data itself? 
The simple answer here is that check constraints are not easily altered. They have to be dropped and re-added.

Additionally, DOMAIN can be created at the schema level and there may be several tables with email address or birth dates. 
Use one DOMAIN to control several fields, thus centralizing the logic.

See more at https://www.crunchydata.com/blog/intro-to-postgres-custom-data-types

# Domains list sql query

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
