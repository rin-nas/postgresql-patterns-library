create function quote_like(text) returns text
    stable
    returns null on null input
    parallel safe
    language sql
as
$$
SELECT replace(replace(replace($1
                               , '\', '\\') -- must come first!
                               , '_', '\_')
                               , '%', '\%');
$$;
