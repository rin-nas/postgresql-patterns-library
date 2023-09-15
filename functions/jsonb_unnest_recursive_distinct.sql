create or replace function public.jsonb_unnest_recursive_distinct(data jsonb[])
    returns table(
        path  text[],
        value jsonb,
        member_of text
    )
    immutable
    returns null on null input -- = strict
    parallel safe -- Postgres 10 or later
    security invoker
    language sql
    set search_path = ''
as $func$
    --explain (analyse)
    with recursive r (path, value, member_of) as
    (
        select
            distinct --!!! also fix performance problem
            array[k.key],
            v.value,
            t.type
        from unnest(jsonb_unnest_recursive_distinct.data) as u(data)
        cross join jsonb_typeof(u.data) as t(type)
        left join jsonb_each(case t.type when 'object' then u.data end) as o(obj_key, obj_value) on true
        left join jsonb_array_elements(case t.type when 'array' then u.data end) with ordinality as a(arr_value, arr_key) on true
        cross join coalesce(o.obj_key, (a.arr_key - 1)::text) as k(key)
        cross join coalesce(o.obj_value, a.arr_value) as v(value)
        where t.type in ('object', 'array')
          and k.key is not null
    union --all
        select
            array_append(r.path, k.key),
            v.value,
            t.type
        from r
        cross join jsonb_typeof(r.value) as t(type)
        left join jsonb_each(case t.type when 'object' then r.value end) as o(obj_key, obj_value) on true
        left join jsonb_array_elements(case t.type when 'array' then r.value end) with ordinality as a(arr_value, arr_key) on true
        cross join coalesce(o.obj_key, (a.arr_key - 1)::text) as k(key)
        cross join coalesce(o.obj_value, a.arr_value) as v(value)
        where t.type in ('object', 'array')
          and k.key is not null
    )
    select r.*
    from r
    where jsonb_typeof(r.value) not in ('object', 'array');
$func$;

comment on function public.jsonb_unnest_recursive_distinct(arr_data jsonb[])
    is 'Recursive parse nested JSONs (arrays and objects), returns distinct keys and its values';

------------------------------------------------------------------------------------------------------------------------
--TEST

do $$
begin
    assert (select count(*) = 9
            from public.jsonb_unnest_recursive_distinct(array[
                    '{"id":123,"g":null,"a":[9,8,4,5],"name":"unknown", "7": 3}'::jsonb,
                    '{"id":123,"g":null,"a":[9,8,4,5],"name":"unknown", "7": 3}'::jsonb,
                    '{"id":123,"g":null,"a":[9,8,4,5],"name":"unknown", "7": 2}'::jsonb
                 ])
           );
end;
$$;
