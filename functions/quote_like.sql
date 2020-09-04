create function quote_like(text) returns text
    immutable
    strict
    language sql
    PARALLEL SAFE -- Postgres 10 or later
as
$$
SELECT replace(replace(replace($1
                               , '\', '\\') -- must come 1st
                               , '_', '\_')
                               , '%', '\%');
$$;
