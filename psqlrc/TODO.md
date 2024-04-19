# TODO list

Get some ideas from
   * https://github.com/zalando/pg_view
   * https://github.com/lesovsky/pgcenter/tree/master/internal/query ; https://habr.com/ru/articles/494162/

Overall info
1. Uptime (mark red if < 1d)
   * `select now() - pg_postmaster_start_time() as uptime;`
1. Databases total amount, tables size, indexes size, toast size, total size
   * `select count(*), pg_size_pretty(sum(pg_database_size(datname))) from pg_database;`
1. Databases total used space in percent (mark red if > 90%).
1. Activity: currently used, total available, used precent (mark red if > 90%), total by status

Configutarion problems
1. Check config file `show config_file;` for errors:
   * `select count(*) from pg_file_settings where error is not null or not applied;`
1. Check hba file `show hba_file;` for errors:
   * `select count(*) from pg_hba_file_rules where error is not null;`
1. Check need to restart server:
   * `select count(*) from pg_settings where pending_restart;`
