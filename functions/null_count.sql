create or replace function public.null_count(variadic anyarray)
    returns integer
    immutable
    strict -- returns null if any parameter is null
    parallel safe
    security invoker
    language sql
    set search_path = ''
as $func$
    SELECT COUNT(*)::int FROM unnest($1) g(v) WHERE g.v IS NULL;
$func$;

/*
--TEST
CREATE TABLE xxx(
  a int,
  b int,
  c int,
  CHECK (null_count(a,b,c) <= 1));
*/
