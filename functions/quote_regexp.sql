-- https://stackoverflow.com/questions/5144036/escape-function-for-regular-expression-or-like-patterns/45741630#45741630
create or replace function public.quote_regexp(text)
    returns text
    immutable
    returns null on null input
    parallel safe
    language sql
    set search_path = ''
return
    regexp_replace($1, '([[\](){}.+*^$|\\?-])', '\\\1', 'g');
