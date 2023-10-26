CREATE FUNCTION public.array_avg(anyarray)
    returns anyelement
    immutable
    strict -- returns null if any parameter is null
    parallel safe -- Postgres 10 or later
    security invoker
    language sql
    set search_path = ''
AS $$
    SELECT avg(x) FROM unnest($1) t(x);
$$;

COMMENT ON FUNCTION public.array_avg(anyarray) IS 'Returns the average value of an array';
