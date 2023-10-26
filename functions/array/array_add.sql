create or replace function public.array_add(a int[], n int)
    returns int[]
    immutable
    strict -- returns null if any parameter is null
    parallel safe -- Postgres 10 or later
    security invoker
    language sql
    set search_path = ''
as $$
    select array(select x + n from unnest(a) t(x));
$$;

comment on function public.array_add(a int[], n int) is 'Add value to each element of an array';

--TEST

do $$
    begin
        assert public.array_add('{1,2,3}', 1) = '{2,3,4}';
    end;
$$;
