create or replace function public.bigint_to_inet(bigint) 
    returns inet 
    immutable
    strict -- returns null if any parameter is null
    parallel safe -- Postgres 10 or later
    security invoker
    language sql
    set search_path = ''
as $func$
    select (($1>>24&255)||'.'||($1>>16&255)||'.'||($1>>8&255)||'.'||($1>>0&255))::inet;
$func$;
