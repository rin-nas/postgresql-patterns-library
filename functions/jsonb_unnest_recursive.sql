create or replace function public.jsonb_unnest_recursive(data jsonb)
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
            array[k.key],
            v.value,
            t.type
        from jsonb_typeof(data) as t(type)
        left join jsonb_each(case t.type when 'object' then data end) as o(obj_key, obj_value) on true
        left join jsonb_array_elements(case t.type when 'array' then data end) with ordinality as a(arr_value, arr_key) on true
        cross join coalesce(o.obj_key, (a.arr_key - 1)::text) as k(key)
        cross join coalesce(o.obj_value, a.arr_value) as v(value)
        where t.type in ('object', 'array')
          and k.key is not null
    union all
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

comment on function public.jsonb_unnest_recursive(data jsonb) is 'Recursive parse nested JSON (arrays and objects), returns keys and its values';


------------------------------------------------------------------------------------------------------------------------

create or replace function public.jsonb_unnest_recursive(arr_data jsonb[])
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
            array[k.key],
            v.value,
            t.type
        from unnest(arr_data) as u(data)
        cross join jsonb_typeof(u.data) as t(type)
        left join jsonb_each(case t.type when 'object' then u.data end) as o(obj_key, obj_value) on true
        left join jsonb_array_elements(case t.type when 'array' then u.data end) with ordinality as a(arr_value, arr_key) on true
        cross join coalesce(o.obj_key, (a.arr_key - 1)::text) as k(key)
        cross join coalesce(o.obj_value, a.arr_value) as v(value)
        where t.type in ('object', 'array')
          and k.key is not null
    union all
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

comment on function public.jsonb_unnest_recursive(arr_data jsonb[]) is 'Recursive parse nested JSONs (arrays and objects), returns keys and its values';

------------------------------------------------------------------------------------------------------------------------
--TEST

--TEST AND USING EXAMPLE
select cardinality(path) as level, *
from public.jsonb_unnest_recursive('{"id":123,"g":null,"a":[9,8,4,5],"name":"unknown", "7": 3}'::jsonb)
order by level, member_of, path;

/*
-- Example: find all emails in JSON data
select j.path, v.value as email
from public.jsonb_unnest_recursive('[{"name":"Mike", "age": 45, "emails":[null, "mike.1977@gmail.com", ""]}]'::jsonb) as j
cross join nullif(j.value #>> '{}', '') as v(value) --cast jsonb scalar to text (can be null)
where jsonb_typeof(j.value) = 'string'
  and v.value is not null
  and public.is_email(v.value);
*/

do $$
begin
    assert (select COUNT(*) = 8
            from public.jsonb_unnest_recursive(
                    '{"id":123,"g":null,"a":[9,8,4,5],"name":"unknown", "7": 3}'::jsonb
                 )
           );

    assert (select COUNT(*) = 16
            from public.jsonb_unnest_recursive(array[
                    '{"id":123,"g":null,"a":[9,8,4,5],"name":"unknown", "7": 3}'::jsonb,
                    '{"id":123,"g":null,"a":[9,8,4,5],"name":"unknown", "7": 3}'::jsonb
                 ])
           );
end;
$$;
