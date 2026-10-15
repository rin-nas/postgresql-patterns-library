DROP FUNCTION IF EXISTS public.shell_exec(command text);

CREATE FUNCTION public.shell_exec(
    command text,
    --returns record:
    stdout    out text,
    stderr    out text,
    exit_code out text
)
    returns record
    volatile -- !!!
    strict -- returns null if any parameter is null
    parallel safe
    SECURITY DEFINER -- due pg_read_file() reason
    language plpgsql
    set search_path = 'pg_catalog, pg_temp' -- prevent SQL injection and privilege escalation attacks
AS $$
DECLARE
    sql            text default 'COPY (SELECT %L) TO PROGRAM %L';
    file_prefix    text default '/tmp/pg_shell_exec.pid_' || pg_backend_pid();
    file_stdout    text default file_prefix || '.stdout.log';
    file_stderr    text default file_prefix || '.stderr.log';
    file_exit_code text default file_prefix || '.exit_code.log';
    bash_program   text default concat('bash > ', file_stdout, ' 2> ', file_stderr, '; printf $? > ', file_exit_code);
    rm_program     text default concat('rm -f ', file_stdout, ' ', file_stderr, ' ', file_exit_code);
BEGIN
    EXECUTE format(sql, command, bash_program);
    stdout    := pg_read_file(file_stdout,    true);
    stderr    := pg_read_file(file_stderr,    true);
    exit_code := pg_read_file(file_exit_code, true);
    EXECUTE format(sql, '',  rm_program);
END;
$$;

COMMENT ON FUNCTION public.shell_exec(command text) IS 'Executes Linux command and returns its result: stdout, stderr, exit_code';

-- TEST
-- SELECT * FROM public.shell_exec('getent ahosts ya.ru');

-- TEST
do $$
    begin
        --positive
        assert public.shell_exec(null) is null;
        assert (select stdout = '' and stderr = '' and exit_code = '0' from public.shell_exec('true'));
        assert (select stdout > '' and stderr = '' and exit_code = '0' from public.shell_exec('date'));

        --negative
        assert (select stdout = '' and stderr = '' and exit_code = '1'   from public.shell_exec('false'));
        assert (select stdout = '' and stderr > '' and exit_code = '127' from public.shell_exec('non_exist_command'));
    end;
$$;
