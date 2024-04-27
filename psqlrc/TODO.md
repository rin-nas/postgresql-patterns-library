# TODO list

Get some ideas from
   * https://github.com/zalando/pg_view
   * https://github.com/lesovsky/pgcenter/tree/master/internal/query ; https://habr.com/ru/articles/494162/

Show current_user `SELECT SESSION_USER, CURRENT_USER;` (after `SET ROLE rolename`)

Show overall info on `psql` start
1. Uptime (mark red if < 1d)
   * `select now() - pg_postmaster_start_time() as uptime;`
1. Databases total amount, tables size, indexes size, toast size, total size
   * `select count(*), pg_size_pretty(sum(pg_database_size(datname))) from pg_database;`
1. Databases total used space in percent (mark red if > 90%).
1. Activity: currently used, total available, used precent (mark red if > 90%), total by status

Add check configutarion problems
1. Check config file `show config_file;` for errors:
    ```sql
    with t as (
        select distinct on (name) *
        from pg_file_settings
        order by name, seqno desc
    )
    select t.sourcefile,
           t.sourceline,
         t.name,
         t.setting,
         t.applied,
         t.error,
         s.vartype,
         s.min_val,
         s.max_val,
         s.enumvals,
         s.extra_desc
    from t
    join pg_settings as s on t.name = s.name
    where not applied;
    ```
1. Check hba file `show hba_file;` for errors:
   * `select exists(select from pg_hba_file_rules where error is not null);`
1. Check need to restart server:
   * `select exists(select from pg_settings where pending_restart);`
