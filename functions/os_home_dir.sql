drop function if exists public.os_home_dir();

create function public.os_home_dir()
    returns text
    immutable
    strict -- returns null if any parameter is null
    parallel safe
    SECURITY DEFINER
    language sql
    set search_path = ''
begin atomic
    -- username:password:UID:GID:GECOS:home_directory:shell
    select split_part(t.line, ':', 6)
    from string_to_table(pg_read_file('/etc/passwd'), E'\n') as t(line)
    where t.line ~ '^postgres:';
end;

alter function public.os_home_dir() owner to postgres;

comment on function public.os_home_dir() is 'Get OS home directory';

--TEST
--select public.os_home_dir();