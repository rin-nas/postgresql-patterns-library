create function quote_like(text) returns text
    immutable
    strict
    language sql
as
$$
SELECT replace(replace(replace($1, '\', '\\'), '_', '\_'), '%', '\%');
$$;
