drop function if exists public.os_home_dir(user_name text);

create function public.os_home_dir(
    user_name text
)
    returns text
    immutable
    strict -- returns null if any parameter is null
    parallel safe
    SECURITY DEFINER -- due pg_read_file() reason
    language sql
    set search_path = 'pg_catalog, pg_temp' -- prevent SQL injection and privilege escalation attacks
begin atomic
    -- username:password:UID:GID:GECOS:home_directory:shell
    select split_part(t.line, ':', 6)
    from string_to_table(pg_read_file('/etc/passwd'), E'\n') as t(line)
    where split_part(t.line, ':', 1) = os_home_dir.user_name;
end;

comment on function public.os_home_dir(user_name text) is 'Get OS home directory';

--alter function public.os_home_dir(user_name text) owner to postgres;

--TEST
--select public.os_home_dir('postgres');