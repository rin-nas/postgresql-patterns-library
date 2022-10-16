create schema if not exists test;
drop table if exists test.test_check;
drop function if exists test.constraint_check(s text);

create or replace function test.constraint_check(s text) returns bool as $$
begin
    perform pg_sleep(1); --emulate heavy check process, for example is_email() function
    raise notice 'constraint check: %', s;
    return true;
end;
$$ language plpgsql;

create table test.test_check (
    id integer generated always as identity primary key,
    s text not null check (test.constraint_check(s) )
);

--workaround with triggers
CREATE OR REPLACE FUNCTION test.trigger_check() RETURNS TRIGGER
    LANGUAGE plpgsql AS
$$
BEGIN
    perform pg_sleep(1); --emulate heavy check process, for example is_email() function
    raise notice 'trigger check: %', NEW.s;
    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS test_check_insert ON test.test_check;
CREATE TRIGGER test_check_insert
    BEFORE INSERT ON test.test_check
    FOR EACH ROW
    WHEN (NEW.s IS NOT NULL)
EXECUTE PROCEDURE test.trigger_check();

DROP TRIGGER IF EXISTS test_check_update ON test.test_check;
CREATE TRIGGER test_check_update
    BEFORE UPDATE OF s ON test.test_check
    FOR EACH ROW
    WHEN (NEW.s IS NOT NULL AND NEW.s IS DISTINCT FROM OLD.s)
EXECUTE PROCEDURE test.trigger_check();

--TEST
truncate test.test_check;
insert into test.test_check (s) values ('a'), ('b'), ('c');
/*
output:
trigger check: a
constraint check: a
trigger check: b
constraint check: b
trigger check: c
constraint check: c
*/
update test.test_check set id = default where true;
/*
output:
constraint_check: a
constraint_check: b
constraint_check: c
*/
update test.test_check set s = s where true;
/*
output:
constraint_check: a
constraint_check: b
constraint_check: c
*/
update test.test_check set s = s||s where true;
/*
output:
trigger check: aa
constraint check: aa
trigger check: bb
constraint check: bb
trigger check: cc
constraint check: cc
*/
