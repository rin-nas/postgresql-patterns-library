create extension if not exists dblink schema public;

drop function if exists public.dblink_u(connection_str text, sql text, record_definition text);

create function public.dblink_u(connection_str text, sql text, record_definition text)
    returns setof record
    volatile -- !!!
    returns null on null input
    parallel safe
    security invoker -- !!!
    language plpgsql
    set search_path = 'pg_catalog, pg_temp' -- prevent SQL injection and privilege escalation attacks
as $$
declare
    conn_name text := 'tmp_conn_' || extract('epoch' from clock_timestamp());
begin
    perform public.dblink_connect_u(conn_name, connection_str);
    --return next public.dblink(conn_name, sql); -- throw error
    --return query select * from public.dblink(conn_name, sql); -- throw error
    return query execute format('select * from public.dblink($1, $2) as s(%s)', record_definition) using conn_name, sql;
    perform public.dblink_disconnect(conn_name);
end;
$$;

/*
Если подключиться к СУБД не под суперпользователем и выполнить функцию dblink() без явного указания пароля в строке подключения, то получим ошибку:
    ERROR:  password or GSSAPI delegated credentials required
    DETAIL:  Non-superusers must provide a password in the connection string or send delegated GSSAPI credentials.
Поведение ожидаемое согласно документации: https://postgrespro.ru/docs/postgresql/current/contrib-dblink-connect
Чтобы пароль брался из файла "~/.pgpass", нужно либо использовать функцию dblink_connect_u(),
либо выполнять функцию dblink() под суперпользователем (для этого можно сделать функцию-обёртку с SECURITY DEFINER)
*/
comment on function public.dblink_u(connection_str text, sql text, record_definition text)
    is 'Аналог функции dblink(), но для не суперпользователя позволяет не указывать пароль в строке подключения, а брать его из файла "~/.pgpass"';

-- TEST
-- select * from public.dblink_u('user=psqlrc_user host=192.168.20.152 port=5432 dbname=postgres', 'select 1', 'f int') as s(f int);