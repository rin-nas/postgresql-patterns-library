CREATE FUNCTION array_min(anyarray)
    RETURNS anyelement
    stable
    returns null on null input
    parallel safe
    language sql
AS $$
    SELECT min(x) FROM unnest($1) t(x);
$$;
