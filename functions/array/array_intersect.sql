create or replace function public.array_intersect(anyarray, anyarray)
    returns anyarray
    immutable
    strict -- returns null if any parameter is null
    parallel safe
    security invoker
    language sql
    set search_path = 'pg_catalog, pg_temp' -- prevent SQL injection and privilege escalation attacks
as
$$
    select array(
        select unnest($1)
        intersect
        select unnest($2)
    );
$$;
