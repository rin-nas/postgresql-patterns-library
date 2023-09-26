/*
TODO Добавить альтернативную функцию со вторым и третьим параметром text[], чтобы передавать
     array['search1', 'search2', ...],
     array['replace1','replace2', ...]
TODO См. ещё https://wiki.postgresql.org/wiki/Multi_Replace_plpgsql
     Логика работы как у PHP strtr(), но реализация сложная, на ходу строится регулярное выражение
*/
create or replace function public.replace_pairs(
    str text,
    pairs json --don't use jsonb type, because it reorder pairs positions!
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
        from json_each_text(pairs)
        --where json_typeof(pairs) = 'object' --DO NOT USE, we need raise error
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
    assert public.replace_pairs('aaabaaba', json_build_object(
        'aa', 2,
        'a', 1
    )) = '21b2b1';
    assert public.replace_pairs('aaabaaba', json_build_object(
        'a', 1,
        'aa', 2
    )) = '111b11b1';
end
$$;
