-- Inspired by https://stackoverflow.com/questions/12391174/how-to-close-idle-connections-in-postgresql-automatically/69528572

drop function if exists db_audit.pg_terminate_idle_timeout(interval, interval);

create or replace function db_audit.pg_terminate_idle_timeout(
    -- Sets the maximum allowed idle time between queries, when not in a transaction:
    idle_session_timeout interval, --PG14+ https://postgresqlco.nf/doc/en/param/idle_session_timeout/
    -- Sets the maximum allowed idle time between queries, when in a transaction:
    idle_in_transaction_session_timeout interval --PG9.6+ https://postgresqlco.nf/doc/en/param/idle_in_transaction_session_timeout/
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
    where true
      and a.pid != pg_backend_pid()
      and a.backend_type = 'client backend' --comment on v9.4
      and a.wait_event_type = 'Client' --comment on v9.4
      and a.state ~ '^idle\M' --idle, idle in transaction, idle in transaction (aborted)
      --значение таймаутов в минутах д.б. меньше, чем указано на реплике в параметрах конфигурации max_standby_archive_delay или max_standby_streaming_delay
      and (e.state_change_elapsed > pg_terminate_idle_timeout.idle_session_timeout or
           e.xact_elapsed         > pg_terminate_idle_timeout.idle_in_transaction_session_timeout)
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
           'idle_timeout'::db_audit.pg_terminated_reason_type as reason
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
      and d.reason = 'idle_timeout'
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

comment on function db_audit.pg_terminate_idle_timeout(interval, interval) is $$
    Терминирует долгие простаивающие без дела подключения к БД.
    Цель — защита тестовой БД или производственной БД от сбоев из-за ошибок в коде приложений.

    Функцию целесообразно выполнять и на мастере и на реплике.
    Чтобы реплике забрать изменения с мастера, она принудительно терминирует по таймауту все очень долгие соединения на реплике.
    Под раздачу попадают все соединения, включая невиновные. Однако можно терминировать только проблемные.

    Терминирует процессы, у которых закончилось максимальная длительность пребывания в статусе idle, idle in transaction, idle in transaction (aborted).
    Сохраняет в таблицу db_audit.pg_terminated информацию о терминированных процессах.
    Автоматически очищает эту таблицу от старых ненужных записей.

    Запрос необходимо выполнять 1 раз в минуту (например, из крона).
        $ crontab -l
        # m h dom mon dow command
        * * * * * psql -U postgres --command="select * from db_audit.pg_terminate_idle_timeout('20 minutes'::interval, '50 minutes'::interval)" >/dev/null
$$;

-- TEST
select * from db_audit.pg_terminate_idle_timeout('20 minutes'::interval, '50 minutes'::interval);
select * from db_audit.pg_terminated where reason = 'idle_timeout' order by created_at desc;
