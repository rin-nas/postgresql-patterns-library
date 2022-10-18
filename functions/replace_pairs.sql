-- TODO https://wiki.postgresql.org/wiki/Multi_Replace_plpgsql

create or replace function replace_pairs(str text, input jsonb)
    returns text
    immutable
    returns null on null input
    parallel safe -- postgres 10 or later
    language plpgsql
    cost 3
as
$func$
declare
    rec record;
begin
    for rec in
        select * from jsonb_each_text(input) order by length(key) desc
    loop
        str := replace(str, rec.key, rec.value);
    end loop;

    return str;
end
$func$;

-- TEST
do $$
begin
    assert replace_pairs('aaabaaba', jsonb_build_object(
        'aa', 2,
        'a', 1
    )) = '21b2b1';
end
$$;

------------------------------------------------------------------------------------------------------------------------

create or replace function replace_pairs(str text, input json)
    returns text
    immutable
    returns null on null input
    parallel safe -- postgres 10 or later
    language plpgsql
    cost 3
as
$func$
declare
    rec record;
begin
    for rec in
        select * from json_each_text(input) order by length(key) desc
    loop
        str := replace(str, rec.key, rec.value);
    end loop;

    return str;
end
$func$;

-- TEST
do $$
begin
    assert replace_pairs('aaabaaba', json_build_object(
        'aa', 2,
        'a', 1
    )) = '21b2b1';
end
$$;
