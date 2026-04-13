create or replace function public.quote_like(text)
    returns text
    immutable
    returns null on null input
    parallel safe
    language sql
    set search_path = ''
return replace(replace(replace($1
                               , '\', '\\') -- must come first!
                               , '_', '\_')
                               , '%', '\%');
