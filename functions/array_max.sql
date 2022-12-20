CREATE FUNCTION array_max(anyarray)
    RETURNS anyelement
    stable
    returns null on null input
    parallel safe
    language sql
    set search_path = ''
AS $$
    SELECT max(x) FROM unnest($1) t(x);
$$;
