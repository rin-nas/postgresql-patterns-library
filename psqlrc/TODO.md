# TODO list

Get some ideas from
   * https://github.com/zalando/pg_view
   * https://github.com/lesovsky/pgcenter/tree/master/internal/query ; https://habr.com/ru/articles/494162/

Show current_user `SELECT SESSION_USER, CURRENT_USER;` (after `SET ROLE rolename`)

Checksum failures: `select sum(checksum_failures) from pg_stat_database`.

Replica: cascade or final, physical or logical.

Show overall info on `psql` start
1. Standby count by status
1. Activity count by status, total currently used, total available, used precent (mark red if > 90%)
1. Databases total amount, tables size, indexes size, toast size, total size
   * `select count(*), pg_size_pretty(sum(pg_database_size(datname))) from pg_database;`
1. Databases total used space in percent (mark red if > 90%).
1. Start and load uptime - mark yellow if < 1d or if > 1y ?

## Advanced Role Detection

For a more detailed status, you can use a query that checks both sender and receiver statuses to distinguish between standalone, primary, and cascading replicas:
```sql
SELECT DISTINCT
  CASE
    WHEN s.sender=0 AND r.receiver=0 THEN 'standalone'
    WHEN s.sender>0 AND r.receiver=0 THEN 'primary'
    WHEN s.sender=0 AND r.receiver>0 THEN 'replica (final)'
    WHEN s.sender>0 AND r.receiver>0 THEN 'replica (cascade)'
  END AS pg_role
FROM 
  (SELECT COUNT(*) AS sender FROM pg_stat_replication) s,
  (SELECT COUNT(*) AS receiver FROM pg_stat_wal_receiver) r;
```
