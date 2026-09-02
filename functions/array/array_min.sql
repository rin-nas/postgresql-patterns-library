CREATE OR REPLACE FUNCTION public.array_min(anyarray)
    returns anyelement
    immutable
    strict -- returns null if any parameter is null
    parallel safe
    security invoker
    language sql
    set search_path = 'pg_catalog, pg_temp' -- prevent SQL injection and privilege escalation attacks
AS $$
    SELECT min(x) FROM unnest($1) t(x);
$$;

COMMENT ON FUNCTION public.array_min(anyarray) IS 'Returns the mininmum value of an array';
