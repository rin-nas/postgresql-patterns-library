create or replace function public.null_count(variadic anyarray)
    returns integer
    immutable
    strict -- returns null if any parameter is null
    parallel safe -- Postgres 10 or later
    security invoker
    language sql
    set search_path = ''
as $func$
    SELECT sum(CASE WHEN v IS NULL THEN 1 ELSE 0 END)::int FROM unnest($1) g(v);
$func$;

/*
--TEST
CREATE TABLE xxx(
  a int,
  b int,
  c int,
  CHECK (null_count(a,b,c) <= 1));
*/