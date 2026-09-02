CREATE OR REPLACE FUNCTION public.is_timezone( tz TEXT ) RETURNS BOOLEAN
    stable
    language plpgsql
    set search_path = 'pg_catalog, pg_temp' -- prevent SQL injection and privilege escalation attacks
AS $$
BEGIN
  PERFORM now() AT TIME ZONE tz;
  RETURN TRUE;
EXCEPTION WHEN invalid_parameter_value THEN
  RETURN FALSE;
END;
$$;
