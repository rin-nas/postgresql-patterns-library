CREATE FUNCTION public.array_max(anyarray)
    returns anyelement
    immutable
    strict -- returns null if any parameter is null
    parallel safe -- Postgres 10 or later
    security invoker
    language sql
    set search_path = ''
AS $$
    SELECT max(x) FROM unnest($1) t(x);
$$;

COMMENT ON FUNCTION public.array_max(anyarray) IS 'Returns the maximum value of an array';
