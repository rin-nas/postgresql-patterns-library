CREATE OR REPLACE FUNCTION public.sort(anyarray)
    returns anyarray
    immutable
    strict -- returns null if any parameter is null
    parallel safe -- Postgres 10 or later
    security invoker
    language sql
    set search_path = ''
AS $$
  SELECT array(SELECT * FROM unnest($1) ORDER BY 1); 
$$;

COMMENT ON FUNCTION public.sort(anyarray) IS 'Sort array elements';