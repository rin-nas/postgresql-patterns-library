CREATE FUNCTION array_avg(anyarray)
    RETURNS anyelement
    stable
    returns null on null input
    parallel safe
    language sql
    set search_path = ''
AS $$
    SELECT avg(x) FROM unnest($1) t(x);
$$;

COMMENT ON FUNCTION array_avg(anyarray) IS 'Returns the average value of an array';
