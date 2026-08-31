drop function if exists public.os_home_dir();

create function public.os_home_dir()
    returns text
    VOLATILE -- not immutable (CREATE TABLE is not allowed in a non-volatile function)
    strict -- returns null if any parameter is null
    parallel safe
    language plpgsql
    set search_path = 'pg_temp'
as $$
DECLARE
    path TEXT;
BEGIN
    CREATE TEMPORARY TABLE IF NOT EXISTS os_home_dir(path text) ON COMMIT DROP;
    COPY os_home_dir FROM PROGRAM 'echo $HOME';
    SELECT t.path INTO path FROM os_home_dir AS t LIMIT 1;
    RETURN path;
END;
$$;

comment on function public.os_home_dir() is 'Get OS home directory. Works on primary server only';

--TEST
--select public.os_home_dir();