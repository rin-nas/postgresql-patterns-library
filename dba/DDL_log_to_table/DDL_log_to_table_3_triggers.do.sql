CREATE EVENT TRIGGER ddl_command_start_trigger ON ddl_command_start
    --WHEN TAG IN ('CREATE TABLE', 'DROP TABLE', 'ALTER TABLE') --для отладки
    EXECUTE FUNCTION db_audit.ddl_command_start_log();

CREATE EVENT TRIGGER ddl_command_end_trigger ON ddl_command_end
    --WHEN TAG IN ('CREATE TABLE', 'DROP TABLE', 'ALTER TABLE') --для отладки
    EXECUTE FUNCTION db_audit.ddl_command_end_log();

CREATE EVENT TRIGGER sql_drop_trigger ON sql_drop
    --WHEN TAG IN ('CREATE TABLE', 'DROP TABLE', 'ALTER TABLE') --для отладки
    EXECUTE FUNCTION db_audit.sql_drop_log();

------------------------------------------------------------------------------------------------------------------------
--TEST

create schema if not exists test;

DO $$
BEGIN
    EXECUTE 'CRE' || 'ATE TABLE test.a() /*"test", ''test''*/ ';
END
$$;

create table test.b();
alter table test.a
    add column i int,
    add column t text,
    add column s varchar(320);
create index on test.a(i);
drop table if exists test.a, test.b;
