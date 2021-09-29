CREATE FUNCTION array_unique(anyarray)
    RETURNS anyarray
    stable
    returns null on null input
    parallel safe
    language sql
AS $$
    SELECT array_agg(DISTINCT x ORDER BY x) FROM unnest($1) t(x);
$$;
