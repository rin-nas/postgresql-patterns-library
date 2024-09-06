# TODO list

Get some ideas from
   * https://github.com/zalando/pg_view
   * https://github.com/lesovsky/pgcenter/tree/master/internal/query ; https://habr.com/ru/articles/494162/

Show current_user `SELECT SESSION_USER, CURRENT_USER;` (after `SET ROLE rolename`)

Show overall info on `psql` start
1. Find unused replication slots and recommend to delete it
1. Start and load uptime - mark yellow if < 1d or if > 1y ?
1. Databases total amount, tables size, indexes size, toast size, total size
   * `select count(*), pg_size_pretty(sum(pg_database_size(datname))) from pg_database;`
1. Databases total used space in percent (mark red if > 90%).
1. Activity: currently used, total available, used precent (mark red if > 90%), total by status
