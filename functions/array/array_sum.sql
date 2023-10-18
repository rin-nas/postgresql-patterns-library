CREATE FUNCTION array_sum(anyarray)
    RETURNS anyelement
    stable
    returns null on null input
    parallel safe
    language sql
    set search_path = ''
AS $$
    SELECT sum(x) FROM unnest($1) t(x);
$$;

COMMENT ON FUNCTION array_sum(anyarray) IS 'Returns the sum value of an array';
