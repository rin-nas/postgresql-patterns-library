CREATE FUNCTION array_min(anyarray)
    RETURNS anyelement
    stable
    returns null on null input
    parallel safe
    language sql
    set search_path = ''
AS $$
    SELECT min(x) FROM unnest($1) t(x);
$$;

COMMENT ON FUNCTION array_min(anyarray) IS 'Returns the mininmum value of an array';
