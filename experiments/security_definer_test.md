
PostgreSQL 18.

Создаём представление и функцию под пользователем `postgres`

```sql

create view pro.test_v as
select current_user, session_user, current_schemas(true);

create function pro.test_v()
    returns setof pro.test_v
    volatile
    returns null on null input
    parallel safe
    SECURITY DEFINER -- !!!
    language sql
    set search_path = 'pg_catalog, pg_temp' -- prevent SQL injection and privilege escalation attacks
begin atomic
    table pro.test_v;
end;

GRANT SELECT ON pro.test_v TO alice;
```

Читаем представление и выполняем функцию под пользователем `alice`

```
=> table pro.test_v;
┌──────────────┬──────────────┬─────────────────────┐
│ current_user │ session_user │   current_schemas   │
├──────────────┼──────────────┼─────────────────────┤
│ alice        │ alice        │ {pg_catalog,public} │
└──────────────┴──────────────┴─────────────────────┘

=> select * from pro.test_v();
┌──────────────┬──────────────┬─────────────────┐
│ current_role │ session_user │ current_schemas │
├──────────────┼──────────────┼─────────────────┤
│ postgres     │ alice        │ {pg_catalog}    │
└──────────────┴──────────────┴─────────────────┘
```
