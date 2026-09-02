CREATE OR REPLACE FUNCTION public.array_sum(anyarray)
    returns anyelement
    immutable
    strict -- returns null if any parameter is null
    parallel safe
    security invoker
    language sql
    set search_path = 'pg_catalog, pg_temp' -- prevent SQL injection and privilege escalation attacks
AS $$
    SELECT sum(x) FROM unnest($1) t(x);
$$;

COMMENT ON FUNCTION public.array_sum(anyarray) IS 'Returns the sum value of an array';
