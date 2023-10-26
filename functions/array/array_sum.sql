CREATE FUNCTION public.array_sum(anyarray)
    returns anyelement
    immutable
    strict -- returns null if any parameter is null
    parallel safe -- Postgres 10 or later
    security invoker
    language sql
    set search_path = ''
AS $$
    SELECT sum(x) FROM unnest($1) t(x);
$$;

COMMENT ON FUNCTION public.array_sum(anyarray) IS 'Returns the sum value of an array';
