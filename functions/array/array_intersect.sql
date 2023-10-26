create function public.array_intersect(anyarray, anyarray)
    returns anyarray
    immutable
    strict -- returns null if any parameter is null
    parallel safe -- Postgres 10 or later
    security invoker
    language sql
    set search_path = ''
as
$$
    select array(
        select unnest($1)
        intersect
        select unnest($2)
    );
$$;
