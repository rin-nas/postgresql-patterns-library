CREATE OR REPLACE FUNCTION public.sort(anyarray)
    returns anyarray
    immutable
    strict -- returns null if any parameter is null
    parallel safe
    security invoker
    language sql
    set search_path = 'pg_catalog, pg_temp' -- prevent SQL injection and privilege escalation attacks
AS $$
  SELECT array(SELECT * FROM unnest($1) ORDER BY 1); 
$$;

COMMENT ON FUNCTION public.sort(anyarray) IS 'Sort array elements';