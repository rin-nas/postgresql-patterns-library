create or replace function public.json_unnest_recursive(data json)
    returns table(
        path  text[],
        value json,
        member_of text
    )
    immutable
    returns null on null input -- = strict
    parallel safe -- Postgres 10 or later
    security invoker
    language sql
    set search_path = ''
AS $func$
    --explain (analyse)
    with recursive r (path, value, member_of) as
    (
        select
            --distinct --[42883] ERROR: could not identify an equality operator for type json
            distinct on (array[k.key], v.value::text, t.type) --!!! fix performance problem
            array[k.key],
            v.value,
            t.type
        from json_typeof(data) as t(type)
        left join json_each(case t.type when 'object' then data end) as o(obj_key, obj_value) on true
        left join json_array_elements(case t.type when 'array' then data end) with ordinality as a(arr_value, arr_key) on true
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
        cross join json_typeof(r.value) as t(type)
        left join json_each(case t.type when 'object' then r.value end) as o(obj_key, obj_value) on true
        left join json_array_elements(case t.type when 'array' then r.value end) with ordinality as a(arr_value, arr_key) on true
        cross join coalesce(o.obj_key, (a.arr_key - 1)::text) as k(key)
        cross join coalesce(o.obj_value, a.arr_value) as v(value)
        where t.type in ('object', 'array')
          and k.key is not null
    )
    select r.*
    from r
    where json_typeof(r.value) not in ('object', 'array');
$func$;

comment on function public.json_unnest_recursive(data json) is 'Recursive parse nested JSON (arrays and objects), returns keys and its values';


------------------------------------------------------------------------------------------------------------------------
--TEST

--TEST AND USING EXAMPLE
select cardinality(path) as level, *
from public.json_unnest_recursive('{"id":123,"g":null,"a":[9,8,4,5],"name":"unknown", "7": 3}'::json)
order by level, member_of, path;


/*
-- Example: find all emails in JSON data
select j.path, v.value as email
from public.json_unnest_recursive('[{"name":"Mike", "age": 45, "emails":[null, "mike.1977@gmail.com", ""]}]'::json) as j
cross join nullif(j.value #>> '{}', '') as v(value) --cast jsonb scalar to text (can be null)
where json_typeof(j.value) = 'string'
  and v.value is not null
  and public.is_email(v.value);
*/

do $$
begin
    assert (select count(*) = 8
            from public.json_unnest_recursive(
                    '{"id":123,"g":null,"a":[9,8,4,5],"name":"unknown", "7": 3}'::json
                 )
           );
end;
$$;
