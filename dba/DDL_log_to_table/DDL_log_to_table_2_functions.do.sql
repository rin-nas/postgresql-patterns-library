--Журналирование (логирование) DDL команд в таблицу БД и аудит

--Выполнять под суперпользователем postgres!

create or replace function db_audit.grep_inet(str text)
    returns table (order_num int, "all" text, addr inet, port int, mask int)
    stable
    returns null on null input
    parallel safe -- Postgres 10 or later
    language sql
as $func$
    select (row_number() over ())::int as order_num,
        m[1] as all,
        array_to_string(m[2:5], '.')::inet as addr,
        m[6]::int as port,
        m[7]::int as mask
    from regexp_matches(str,
                        $$
                          ( #1 all
                              (?<![\d.:/]) #boundary
                              (\d{1,3}) \. (\d{1,3}) \. (\d{1,3}) \. (\d{1,3}) #2-5 addr 1..255
                              (?:
                                  : (\d{1,5}) #6 port 1..65535
                                | / (\d{1,2}) #7 mask 0..32
                              )?
                              (?![\d.:/]) #boundary
                          )
                        $$, 'xg') as t(m)
    where not exists(select
                     from unnest(m[2:5]) u(e)
                     where e::int not between 0 and 255)
      and (m[6] is null or m[6]::int between 1 and 65535)
      and (m[7] is null or m[7]::int between 0 and 32);
$func$;

comment on function db_audit.grep_inet(str text) is $$
    Захватывает из строки все существующие IP адреса.
    IP адрес может иметь необязательный порт или маску.
$$;

--TEST
do $do$
declare
    str_in constant text not null default $$
    #valid
    0.0.0.0
    1.2.3.4
    -1.2.3.4
    1.2.3.4-
    01.02.03.04
    001.002.003.004
    9.9.9.9
    10.10.10.10
    99.99.99.99
    100.100.100.100
    255.255.255.255
    127.0.0.1
    192.168.1.1:1
    192.168.1.255:65535
    192.168.1.1/0
    192.168.1.255/32

    #invalid octet range
    256.2.3.4
    1.256.3.4
    1.2.256.4
    1.2.3.256

    #invalid boundary
    1.1.1.1.
    1.1.1.1/
    1.1.1.1:

    1.1.1.1:9.
    1.1.1.1:99:
    1.1.1.1:999/

    1.1.1.1/0.
    1.1.1.1/32:
    1.1.1.1/32/

    .2.2.2.2
    :2.2.2.2
    /2.2.2.2

    #invalid length
    1.2.3.4.5
    1.2.3
    0.1
    3...3

    #invalid mask
    5.5.5.5/-1
    5.5.5.5/33

    #invalid port
    5.5.5.5:0
    5.5.5.5:65536
    $$;

    str_out constant text not null default '[{"order_num":1,"all":"0.0.0.0","addr":"0.0.0.0","port":null,"mask":null}, {"order_num":2,"all":"1.2.3.4","addr":"1.2.3.4","port":null,"mask":null}, {"order_num":3,"all":"1.2.3.4","addr":"1.2.3.4","port":null,"mask":null}, {"order_num":4,"all":"1.2.3.4","addr":"1.2.3.4","port":null,"mask":null}, {"order_num":5,"all":"01.02.03.04","addr":"1.2.3.4","port":null,"mask":null}, {"order_num":6,"all":"001.002.003.004","addr":"1.2.3.4","port":null,"mask":null}, {"order_num":7,"all":"9.9.9.9","addr":"9.9.9.9","port":null,"mask":null}, {"order_num":8,"all":"10.10.10.10","addr":"10.10.10.10","port":null,"mask":null}, {"order_num":9,"all":"99.99.99.99","addr":"99.99.99.99","port":null,"mask":null}, {"order_num":10,"all":"100.100.100.100","addr":"100.100.100.100","port":null,"mask":null}, {"order_num":11,"all":"255.255.255.255","addr":"255.255.255.255","port":null,"mask":null}, {"order_num":12,"all":"127.0.0.1","addr":"127.0.0.1","port":null,"mask":null}, {"order_num":13,"all":"192.168.1.1:1","addr":"192.168.1.1","port":1,"mask":null}, {"order_num":14,"all":"192.168.1.255:65535","addr":"192.168.1.255","port":65535,"mask":null}, {"order_num":15,"all":"192.168.1.1/0","addr":"192.168.1.1","port":null,"mask":0}, {"order_num":16,"all":"192.168.1.255/32","addr":"192.168.1.255","port":null,"mask":32}]';
begin
    --positive and negative both
    assert (select json_agg(to_json(t))::text = str_out
            from db_audit.grep_inet(str_in) as t);
end;
$do$;

------------------------------------------------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION db_audit.ddl_command_start_log()
    RETURNS event_trigger
    SECURITY DEFINER
    PARALLEL SAFE
    LANGUAGE plpgsql
AS $$
DECLARE
    stack text;
    app_name text default nullif(trim(current_setting('application_name'), E' \r\n\t'), '');
    addr inet default inet_client_addr();
    port int default inet_client_port();
    via_proxy boolean;

BEGIN
    GET DIAGNOSTICS stack := PG_CONTEXT;
    stack := nullif(regexp_replace(stack, '^[^\r\n]*\s*', ''), ''); --удаляем первую строку, она всегда одинаковая

    /*
    PgBouncer при включённом параметре конфигурации application_name_add_host добавляет в application_name IP адрес и порт клиента
    https://www.pgbouncer.org/config.html#application_name_add_host по аналогии с
    https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/X-Forwarded-For
    */
    if addr is null and port is null and app_name is not null then

        select t.addr, t.port, true, nullif(rtrim(replace(app_name, t."all", ''), E'-, \r\n\t'), '')
        into addr, port, via_proxy, app_name
        from db_audit.grep_inet(app_name) as t
        where t.port is not null
        order by t.order_num desc
        limit 1;

    end if;

    insert into db_audit.ddl_log (
        event, tag, client_addr, client_port, via_pooler,
        backend_pid, application_name, "session_user", "current_user", transaction_id,
        conf_load_time, postmaster_start_time, server_version_num,
        current_schemas, trigger_depth, top_queries, context_stack)
    select TG_EVENT::db_audit.tg_event_type, TG_TAG, addr, port, via_proxy,
           pg_backend_pid(), app_name, session_user, current_user, txid_current(),
           pg_conf_load_time(), pg_postmaster_start_time(), current_setting('server_version_num')::int,
           current_schemas(true), pg_trigger_depth(), trim(current_query(), E' \r\n\t'), stack;

END;
$$;

CREATE OR REPLACE FUNCTION db_audit.ddl_command_end_log()
    RETURNS event_trigger
    SECURITY DEFINER
    PARALLEL SAFE
    LANGUAGE plpgsql
AS $$
DECLARE
    rec record;
    stack text;
    app_name text default nullif(trim(current_setting('application_name'), E' \r\n\t'), '');
    addr inet default inet_client_addr();
    port int default inet_client_port();
    via_proxy boolean;
    is_deleted boolean not null default false;
BEGIN
    GET DIAGNOSTICS stack := PG_CONTEXT;
    stack := nullif(regexp_replace(stack, '^[^\r\n]*\s*', ''), ''); --удаляем первую строку, она всегда одинаковая

    /*
    PgBouncer при включённом параметре конфигурации application_name_add_host добавляет в application_name IP адрес и порт клиента
    https://www.pgbouncer.org/config.html#application_name_add_host по аналогии с
    https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/X-Forwarded-For
    */
    if addr is null and port is null and app_name is not null then

        select t.addr, t.port, true, nullif(rtrim(replace(app_name, t."all", ''), E'-, \r\n\t'), '')
        into addr, port, via_proxy, app_name
        from db_audit.grep_inet(app_name) as t
        where t.port is not null
        order by t.order_num desc
        limit 1;

    end if;

    FOR rec IN SELECT * FROM pg_event_trigger_ddl_commands()
    LOOP
        insert into db_audit.ddl_log (
            event, tag, client_addr, client_port, via_pooler,
            backend_pid, application_name, "session_user", "current_user", transaction_id,
            conf_load_time, postmaster_start_time, server_version_num,
            current_schemas, trigger_depth, top_queries, context_stack,
            object_type, schema_name, object_identity, in_extension)
        select TG_EVENT::db_audit.tg_event_type, TG_TAG, addr, port, via_proxy,
               pg_backend_pid(), app_name, session_user, current_user, txid_current(),
               pg_conf_load_time(), pg_postmaster_start_time(), current_setting('server_version_num')::int,
               current_schemas(true), pg_trigger_depth(), trim(current_query(), E' \r\n\t'), stack,
               rec.object_type, rec.schema_name, rec.object_identity, rec.in_extension;

        -- в истории создания и удаления временных таблиц храним только 1000 последних строк,
        -- остальные удаляем в момент создания временной таблицы
        if rec.schema_name = 'pg_temp' and not is_deleted then

            is_deleted := true;

            with t as (
                select t.transaction_id
                from db_audit.ddl_log as t
                where t.schema_name = 'pg_temp'
                order by t.created_at desc
                offset 1000
            ),
            s as (
                select m.id
                from db_audit.ddl_log as m
                where m.transaction_id in (select t.transaction_id from t)
                for update of m -- пытаемся заблокировать строки таблицы от изменения в параллельных транзакциях
                skip locked -- если строки заблокировать не удалось, пропускаем их (они уже заблокированы в параллельных транзакциях)
            )
            --select * from s; --для отладки
            delete from db_audit.ddl_log as d
            where d.id in (select s.id from s); -- наиболее эффективно удаление по первичному ключу
            --returning id --для отладки

        end if;

    END LOOP;

END;
$$;

CREATE OR REPLACE FUNCTION db_audit.sql_drop_log()
    RETURNS event_trigger
    SECURITY DEFINER
    PARALLEL SAFE
    LANGUAGE plpgsql
AS $$
DECLARE
    rec record;
    stack text;
    app_name text default nullif(trim(current_setting('application_name'), E' \r\n\t'), '');
    addr inet default inet_client_addr();
    port int default inet_client_port();
    via_proxy boolean;
BEGIN
    GET DIAGNOSTICS stack := PG_CONTEXT;
    stack := nullif(regexp_replace(stack, '^[^\r\n]*\s*', ''), ''); --удаляем первую строку, она всегда одинаковая

    /*
    PgBouncer при включённом параметре конфигурации application_name_add_host добавляет в application_name IP адрес и порт клиента
    https://www.pgbouncer.org/config.html#application_name_add_host по аналогии с
    https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/X-Forwarded-For
    */
    if addr is null and port is null and app_name is not null then

        select t.addr, t.port, true, nullif(rtrim(replace(app_name, t."all", ''), E'-, \r\n\t'), '')
        into addr, port, via_proxy, app_name
        from db_audit.grep_inet(app_name) as t
        where t.port is not null
        order by t.order_num desc
        limit 1;

    end if;

    FOR rec IN SELECT * FROM pg_event_trigger_dropped_objects()
    LOOP
        insert into db_audit.ddl_log (
            event, tag, client_addr, client_port, via_pooler,
            backend_pid, application_name, "session_user", "current_user", transaction_id,
            conf_load_time, postmaster_start_time, server_version_num,
            current_schemas, trigger_depth, top_queries, context_stack,
            object_type, schema_name, object_identity)
        select TG_EVENT::db_audit.tg_event_type, TG_TAG, addr, port, via_proxy,
               pg_backend_pid(), app_name, session_user, current_user, txid_current(),
               pg_conf_load_time(), pg_postmaster_start_time(), current_setting('server_version_num')::int,
               current_schemas(true), pg_trigger_depth(), trim(current_query(), E' \r\n\t'), stack,
               rec.object_type, rec.schema_name, rec.object_identity;
    END LOOP;

END;
$$;
