create schema if not exists test;
drop table if exists test.test_check;
drop function if exists test.echo(s text);
create or replace function test.echo(s text) returns bool as $$
begin
    perform pg_sleep(1); --emulate heavy check process, for example is_email() function
    raise notice 'echo: %', s;
    return true;
end;
$$ language plpgsql;

create table test.test_check (
    id integer generated always as identity primary key,
    s text not null check (test.echo(s) )
);

truncate test.test_check;
insert into test.test_check (s) values ('a'), ('b'), ('c');
/*
output:
echo: a
echo: b
echo: c
*/
update test.test_check set id = default where true;
/*
output:
echo: a
echo: b
echo: c
*/
update test.test_check set s = s where true;
/*
output:
echo: a
echo: b
echo: c
*/
