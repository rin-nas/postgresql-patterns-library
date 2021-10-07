CREATE FUNCTION depers.array_min(anyarray)
    RETURNS anyarray
    stable
    returns null on null input
    parallel safe
    language sql
AS $$
    SELECT min(x) FROM unnest($1) t(x);
$$;
