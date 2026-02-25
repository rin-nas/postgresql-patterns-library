# Ссылки
1. https://habr.com/ru/companies/postgrespro/articles/788268/ Как в СУБД реализовать администратора без прав доступа к данным (2024)
1. https://postgres.men/database/postgresql/acl-server/ PostgreSQL ACL Server
1. https://postgres.men/database/postgresql/acl-object/ PostgreSQL ACL Object


# Роли `SEMIDBA_READ` и `SEMIDBA_WRITE` - доступ администратора БД для просмотра и изменения данных
```sql
CREATE ROLE SEMIDBA_READ WITH NOLOGIN NOCREATEDB NOCREATEROLE NOSUPERUSER INHERIT NOREPLICATION NOBYPASSRLS;
CREATE ROLE SEMIDBA_WRITE WITH NOLOGIN NOCREATEDB NOCREATEROLE NOSUPERUSER INHERIT NOREPLICATION NOBYPASSRLS;

GRANT PG_READ_ALL_SETTINGS TO SEMIDBA_READ;
GRANT PG_READ_ALL_STATS TO SEMIDBA_READ;
GRANT PG_STAT_SCAN_TABLES TO SEMIDBA_READ;
GRANT PG_SIGNAL_BACKEND TO SEMIDBA_READ;
GRANT PG_MONITOR TO SEMIDBA_READ;
GRANT SEMIDBA_READ TO SEMIDBA_WRITE;

GRANT USAGE ON SCHEMA <ИМЯ_СХЕМЫ> TO SEMIDBA_READ;
GRANT SELECT ON ALL TABLES IN SCHEMA <ИМЯ_СХЕМЫ> TO SEMIDBA_READ;
GRANT USAGE ON ALL SEQUENCES IN SCHEMA <ИМЯ_СХЕМЫ> TO SEMIDBA_READ;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA <ИМЯ_СХЕМЫ> TO SEMIDBA_READ;
ALTER DEFAULT PRIVILEGES FOR USER <ИМЯ_ПОЛЬЗОВАТЕЛЯ> IN SCHEMA <ИМЯ_СХЕМЫ> GRANT USAGE ON SEQUENCES TO SEMIDBA_READ;
ALTER DEFAULT PRIVILEGES FOR USER <ИМЯ_ПОЛЬЗОВАТЕЛЯ> IN SCHEMA <ИМЯ_СХЕМЫ> GRANT EXECUTE ON FUNCTIONS TO SEMIDBA_READ;
ALTER DEFAULT PRIVILEGES FOR USER <ИМЯ_ПОЛЬЗОВАТЕЛЯ> IN SCHEMA <ИМЯ_СХЕМЫ> GRANT SELECT ON TABLES TO SEMIDBA_3LINE;
ALTER DEFAULT PRIVILEGES FOR USER <ИМЯ_ПОЛЬЗОВАТЕЛЯ> IN SCHEMA <ИМЯ_СХЕМЫ> GRANT SELECT ON TABLES TO SEMIDBA_READ;

GRANT <ВЛАДЕЛЕЦ_БД> TO SEMIDBA_WRITE;

ALTER ROLE SEMIDBA_READ SET SEARCH_PATH = '<ИМЯ_СХЕМЫ>';
ALTER ROLE SEMIDBA_WRITE SET SEARCH_PATH = '<ИМЯ_СХЕМЫ>';
```

# Роль `auditor` - доступ ОКБ для ПО аудита СУБД, техническая учётка
```sql
CREATE USER AUDITOR WITH PASSWORD '***';
ALTER USER AUDITOR SET DEFAULT_TRANSACTION _READ_ONLY = on;
grant select on pg_catalog.pg_authid to auditor;
grant select on pg_catalog.pg_file_settings to auditor;
grant execute on function pg_catalog.pg_show_all_file_settings to auditor;
grant select on pg_catalog.pg_hba_file_rules to auditor;
grant execute on function pg_catalog.pg_hba_file_rules to auditor;
grant select on pg_catalog.pg_config to auditor;
grant execute on function pg_catalog.pg_config to auditor;
grant select on pg_catalog.pg_shadow to auditor;
```

# Роль `useraud` - доступ сотрудников для разбора инцидентов, персональная учётка
```sql
CREATE USER useraud WITH PASSWORD '***';
ALTER USER useraud SET DEFAULT_TRANSACTION _READ_ONLY = on;
grant select on pg_catalog.pg_authid to useraud;
grant select on pg_catalog.pg_file_settings to useraud;
grant execute on function pg_catalog.pg_show_all_file_settings to useraud;
grant select on pg_catalog.pg_hba_file_rules to useraud;
grant execute on function pg_catalog.pg_hba_file_rules to useraud;
grant select on pg_catalog.pg_config to useraud;
grant execute on function pg_catalog.pg_config to useraud;
grant select on pg_catalog.pg_shadow to useraud;
```
