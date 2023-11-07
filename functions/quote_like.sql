create function public.quote_like(text)
    returns text
    immutable
    returns null on null input
    parallel safe -- Postgres 10 or later
    language sql
    set search_path = ''
as
$$
select replace(replace(replace($1
                               , '\', '\\') -- must come first!
                               , '_', '\_')
                               , '%', '\%');
$$;
