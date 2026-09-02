drop function if exists public.read_pgpass(filename text);

create function public.read_pgpass(filename text)
    returns table (
        hostname text,
        port     text,
        database text,
        username text,
        password text
    )
    immutable
    strict -- returns null if any parameter is null
    parallel safe
    SECURITY DEFINER
    language sql
    set search_path = 'pg_catalog, pg_temp' -- prevent SQL injection and privilege escalation attacks
begin atomic
    -- https://postgrespro.com/docs/postgresql/current/libpq-pgpass
    select t7.fields[1] as hostname,
           t7.fields[2] as port,
           t7.fields[3] as database,
           t7.fields[4] as username,
           t7.fields[5] as password
    from string_to_table(pg_read_file(read_pgpass.filename), E'\n') as t1(line)
    -- unquote chain
    cross join replace(t1.line, '\\', E'\x01') as t2(line)
    cross join replace(t2.line, '\:', E'\x02') as t3(line)
    cross join replace(t3.line, ':',  E'\x03') as t4(line)
    cross join replace(t4.line, E'\x01', '\') as t5(line)
    cross join replace(t5.line, E'\x02', ':') as t6(line)
    cross join string_to_array(t6.line, E'\x03') as t7(fields)
    where left(ltrim(t1.line), 1) not in ('', '#'); -- ignore empty strings and comments
end;

comment on function public.read_pgpass(filename text) is 'Read pgpass file';

--alter function public.read_pgpass(filename text) owner to postgres;

--TEST
--select * from public.read_pgpass(public.os_home_dir('postgres') || '/.pgpass');
