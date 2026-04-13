-- https://stackoverflow.com/questions/5144036/escape-function-for-regular-expression-or-like-patterns/45741630#45741630
create function public.quote_regexp(text)
    returns text
    immutable
    returns null on null input
    parallel safe -- Postgres 10 or later
    language sql
    set search_path = ''
return regexp_replace($1, '([[\](){}.+*^$|\\?-])', '\\\1', 'g');
