--CORE-969 Журналировать DDL команды в таблицу БД (откат)

--выполнять под суперпользователем postgres!

DROP EVENT TRIGGER ddl_command_start_trigger;
DROP EVENT TRIGGER ddl_command_end_trigger;
DROP EVENT TRIGGER sql_drop_trigger;

DROP FUNCTION db_audit.ddl_command_start_log();
DROP FUNCTION db_audit.ddl_command_end_log();
DROP FUNCTION db_audit.sql_drop_log();

DROP FUNCTION db_audit.grep_inet(str text);

drop view db_audit.objects, db_audit.ddl_start_log;
drop table db_audit.ddl_log;
drop type db_audit.tg_event_type;
drop schema db_audit;

