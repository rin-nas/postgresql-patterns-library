-- TODO https://wiki.postgresql.org/wiki/Multi_Replace_plpgsql
-- TODO добавить альтернативную функцию со вторым параметром text[], чтобы передавать array['search1', 'replace1', 'search2', 'replace2', ...]

create or replace function replace_pairs(
    str text,
    input json --don't use jsonb type, because it reorder pairs positions!
)
    returns text
    immutable
    returns null on null input
    parallel safe -- postgres 10 or later
    language plpgsql
    set search_path = ''
    cost 3
as
$func$
declare
    rec record;
begin
    for rec in
        select *
        from json_each_text(input)
        --order by length(key) desc --DO NOT SORT, we need preserve pairs positions!
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
    assert replace_pairs('aaabaaba', json_build_object(
        'a', 1,
        'aa', 2
    )) = '111b11b1';
end
$$;
