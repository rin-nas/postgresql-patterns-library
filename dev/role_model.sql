-- группы для членства ТУЗ и ПУЗ
CREATE ROLE group_personal;    COMMENT ON ROLE group_personal    IS 'Группа для персональных УЗ (сотрудников)';
CREATE ROLE group_patroni;     COMMENT ON ROLE group_patroni     IS 'Группа для технических УЗ Patroni';
CREATE ROLE group_application; COMMENT ON ROLE group_application IS 'Группа для технических УЗ приложения';

-- группы для наделения их привилегиями
CREATE ROLE group_read;       -- SELECT
CREATE ROLE group_write;      -- DML (INSERT, UPDATE, DELETE, TRUNCATE, MERGE), TCL (COMMIT, ROLLBACK, SAVEPOINT)
CREATE ROLE group_read_write; -- group_read + group_write
CREATE ROLE group_deploy;     -- DDL (CREATE, ALTER, DROP) + group_read_write
CREATE ROLE group_permission; -- DCL (REVOKE, GRANT)
CREATE ROLE group_admin;      -- администрирование СУБД без SELECT, DML, TCL, DCL
CREATE ROLE group_audit;      -- чтение всех настроек СУБД

-- группы с наследованием привилегий
GRANT group_read, group_write TO group_read_write /*WITH SET FALSE*/;
GRANT group_read_write        TO group_deploy     /*WITH SET FALSE*/;

--GRANT pg_read_all_data  TO group_read;
--GRANT pg_write_all_data TO group_write;

-- пользователи ТУЗ
CREATE USER app_read;
CREATE USER app_write;
CREATE USER app_read_write;
CREATE USER app_deploy;

-- пользователи ПУЗ
CREATE USER dba_rhmukhtarov WITH SUPERUSER;
COMMENT ON ROLE dba_rhmukhtarov IS 'DBA';

CREATE USER sup_petrov;
COMMENT ON ROLE sup_petrov IS 'Прикладное сопровождение АС (support)';

-- объединяем ТУЗ приложения в группу
GRANT group_application TO app_read;
GRANT group_application TO app_write;
GRANT group_application TO app_read_write;
GRANT group_application TO app_deploy;

-- объединяем ПУЗ в группу
GRANT group_personal TO dba_rhmukhtarov;
GRANT group_personal TO sup_petrov;

-- раздаём привилегии ТУЗ
GRANT group_read       TO app_read;
GRANT group_write      TO app_write;
GRANT group_read_write TO app_read_write;
GRANT group_deploy     TO app_deploy;
alter
--ALTER USER dba_rhmukhtarov SET statement_timeout = '6h';
--ALTER USER dba_rhmukhtarov SET log_min_duration_statement = 0;
--ALTER USER dba_rhmukhtarov set log_duration = 1;

CREATE DATABASE app_db WITH OWNER app_deploy;

\connect app_db

-- посмотреть список привилегий для текущей БД
--select * FROM information_schema.table_privileges

-- отнимаем привилегии у роли PUBLIC для уже созданных объектов в текущей БД
REVOKE ALL /*CREATE, CONNECT, TEMPORARY*/ ON DATABASE app_db FROM PUBLIC;
REVOKE ALL /*CREATE, USAGE*/ ON SCHEMA public             FROM PUBLIC;
REVOKE ALL /*CREATE, USAGE*/ ON SCHEMA pg_catalog         FROM PUBLIC;
REVOKE ALL /*CREATE, USAGE*/ ON SCHEMA information_schema FROM PUBLIC;
 
-- отнимаем привилегии у роли PUBLIC для будущих создаваемых объектов в текущей БД
ALTER DEFAULT PRIVILEGES REVOKE ALL ON tables    FROM PUBLIC;
ALTER DEFAULT PRIVILEGES REVOKE ALL ON sequences FROM PUBLIC;
ALTER DEFAULT PRIVILEGES REVOKE ALL ON routines  FROM PUBLIC;
ALTER DEFAULT PRIVILEGES REVOKE ALL ON types     FROM PUBLIC;
ALTER DEFAULT PRIVILEGES REVOKE ALL ON schemas   FROM PUBLIC;

GRANT CONNECT ON DATABASE app_db TO group_application; --не работает для группы

/*
  Для смены пароля нельзя использовать команду ALTER USER user_name WITH PASSWORD 'new_password';
  Т.к. пароль сохранится в журнале на сервере СУБД. Правильные клиенты передают хеш пароля.
  Поменять пароль можно в любом GUI клиенте, например в DBeaver.
  Для psql подключитесь к СУБД, затем введите команду \password
*/
\password app_read;
\password app_write;
\password app_read_write;
\password app_deploy;
\password dba_rhmukhtarov;
\password sup_petrov;

