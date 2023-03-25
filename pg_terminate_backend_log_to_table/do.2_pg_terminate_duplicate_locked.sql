drop function if exists db_audit.pg_terminate_duplicate_locked(interval);

create or replace function db_audit.pg_terminate_duplicate_locked(
    -- Sets the maximum allowed duration for a locked process
    locked_timeout interval
)
    returns setof db_audit.pg_terminated
    parallel safe
    rows 10
    volatile --https://postgrespro.ru/docs/postgresql/14/xfunc-volatility
    returns null on null input
    language sql
    set search_path = ''
as $BODY$
with s as (
    select a.*,
           --e.*, --для отладки
           pg_blocking_pids(a.pid) as pg_blocking_pids,
           pg_terminate_backend(a.pid) as terminated
    from pg_stat_activity as a
    cross join lateral (
        select statement_timestamp() - xact_start as xact_elapsed,  --длительность транзакции или NULL, если транзакции нет
               case when a.state ~ '^idle\M' --idle, idle in transaction, idle in transaction (aborted)
                    then state_change - query_start
                    else statement_timestamp() - query_start
               end as query_elapsed, --длительность выполнения запроса всего
               statement_timestamp() - state_change as state_change_elapsed --длительность после изменения состояния (поля state)
    ) as e
    cross join pg_size_bytes(regexp_replace(trim(current_setting('track_activity_query_size')), '(?<![a-zA-Z])B$', '')) as s(track_activity_query_size_bytes)
    where true
      and exists(
          select
          from pg_stat_activity as b
          where true
            and b.pid != a.pid --Идентификатор процесса
            and b.datid = a.datid --OID базы данных, к которой подключён серверный процесс
            and b.usesysid = a.usesysid --OID пользователя, подключённого к серверному процессу
            and b.pid = any(pg_blocking_pids(a.pid)) --Серверный процесс заблокировал другие
            and b.query = a.query --SQL запрос
            and octet_length(b.query) < s.track_activity_query_size_bytes
      )
      --по умолчанию текст запроса обрезается до 1024 байт; это число определяется параметром track_activity_query_size
      --обрезанные запросы игнорируем
      and octet_length(a.query) < s.track_activity_query_size_bytes
      and a.pid != pg_backend_pid()
      and a.state = 'active' --серверный процесс выполняет запрос
      and a.wait_event_type = 'Lock' --Lock: процесс ожидает тяжёлую блокировку
      and e.state_change_elapsed > pg_terminate_duplicate_locked.locked_timeout
      and a.application_name not in ('pg_dump', 'pg_restore')
      and a.usename != 'postgres'
    order by greatest(e.state_change_elapsed, e.query_elapsed, e.xact_elapsed) desc
)
--select * from s; --для отладки
, i as (
    insert into db_audit.pg_terminated (
        datid, datname, pid, leader_pid, usesysid, usename, application_name, client_addr, client_hostname, client_port,
        backend_start, xact_start, query_start, state_change, wait_event_type, wait_event, state, backend_xid, backend_xmin,
        query_id, query, backend_type, pg_blocking_pids, reason
    )
    select r.*,
           'duplicate_locked_query'::db_audit.pg_terminated_reason_type as reason
    from s
    -- Workaround to compatible with various version of PostgreSQL since v12
    cross join jsonb_to_record(to_jsonb(s)) as r (
        --https://postgrespro.ru/docs/postgresql/14/monitoring-stats#MONITORING-PG-STAT-ACTIVITY-VIEW
        datid oid,
        datname name,
        pid int,
        leader_pid int, --PG13+
        usesysid oid,
        usename name,
        application_name text,
        client_addr inet,
        client_hostname text,
        client_port int,
        backend_start timestamptz,
        xact_start timestamptz,
        query_start timestamptz,
        state_change timestamptz,
        wait_event_type text,
        wait_event text,
        state text,
        backend_xid xid,
        backend_xmin xid,
        query_id bigint, --PG14+
        query text,
        backend_type text,
        pg_blocking_pids integer[]
    )
    where terminated
    returning *
)
-- select * from i; --для отладки
, ds as (
    -- Автоочистка таблицы от старых ненужных данных
    select d.id
    from db_audit.pg_terminated as d
    where exists(select from i) -- чистим если были добавлены записи
      and d.created_at < statement_timestamp() - interval '1 month'
      and d.reason = 'duplicate_locked_query'
    order by d.created_at desc
    for update of d -- пытаемся заблокировать строки таблицы от изменения в параллельных транзакциях
    skip locked -- если строки заблокировать не удалось, пропускаем их (они уже заблокированы в параллельных транзакциях)
    offset 1000
    limit 1000
)
--select * from ds; --для отладки
, d as (
    delete from db_audit.ddl_log as d
    where d.id in (select ds.id from ds)
    -- наиболее эффективно удаление по первичному ключу
    returning id
)
select * from i;
$BODY$;

comment on function db_audit.pg_terminate_duplicate_locked(interval) is $$
    Терминирует заблокированные одинаковые запросы, образующие очередь.
    Цель — защита тестовой БД или производственной БД от сбоев из-за ошибок в коде приложений.

    Одинаковые запросы могут блокировать друг-друга и образовывать очередь.
    Когда кол-во допустимых соединений к БД будет превышено, она принудительно терминирует все соединения.
    Среди них могут быть "невиновные" запросы.
    Но можно терминировать только проблемные запросы.

    Сохраняет в таблицу db_audit.pg_terminated информацию о терминированных процессах.
    Автоматически очищает эту таблицу от старых ненужных записей.

    Запрос необходимо выполнять 1 раз в 15 секунд (например, из крона).
        $ crontab -l
        # m h dom mon dow command
        * * * * *               psql -U postgres --command="select * from db_audit.pg_terminate_duplicate_locked('15 second'::interval)"
        * * * * * ( sleep 15 && psql -U postgres --command="select * from db_audit.pg_terminate_duplicate_locked('15 second'::interval)" )
        * * * * * ( sleep 30 && psql -U postgres --command="select * from db_audit.pg_terminate_duplicate_locked('15 second'::interval)" )
        * * * * * ( sleep 45 && psql -U postgres --command="select * from db_audit.pg_terminate_duplicate_locked('15 second'::interval)" )
$$;

-- TEST
select * from db_audit.pg_terminate_duplicate_locked('15 second'::interval);
select * from db_audit.pg_terminated where reason = 'duplicate_locked_query' order by created_at desc;