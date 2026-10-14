DROP FUNCTION IF EXISTS public.shell_exec(command text);

CREATE FUNCTION public.shell_exec(command text)
    returns setof text
    volatile -- !!!
    strict -- returns null if any parameter is null
    parallel safe
    SECURITY DEFINER -- due pg_read_file() reason
    language plpgsql
    set search_path = 'pg_catalog, pg_temp' -- prevent SQL injection and privilege escalation attacks
AS $$
DECLARE
    sql      text default 'COPY (SELECT %L) TO PROGRAM %L';
    filename text default '/tmp/pg_pid_' || pg_backend_pid();
    contents text;
BEGIN
    EXECUTE format(sql, command, 'bash > ' || filename);
    contents := pg_read_file(filename);
    EXECUTE format(sql, '',  'rm -f ' || filename);
    RETURN QUERY SELECT string_to_table(contents, E'\n');
END;
$$;

COMMENT ON FUNCTION public.shell_exec(command text) IS 'Executes Linux command and returns its result lines (stdout)';

-- TEST
-- SELECT * FROM public.shell_exec('getent ahosts ya.ru');
