with a as (
    select
        backend_type,
        datname,
        state,
        usename,
        --application_name,
        /*
        client_addr,
        client_port,
        --*/
        wait_event_type,
        wait_event,
        count(*) as "count",
        concat_ws('/',
            count(*) filter (where state_change < now() - interval '1 minute'),
            count(*) filter (where state_change < now() - interval '1 hour')
        ) as "state_changed > 1m/1h ago"
    from pg_stat_activity
    group by backend_type, datname, state, usename/*, application_name, client_addr, client_port*/, wait_event_type, wait_event
    order by backend_type, datname, state, usename/*, application_name, client_addr, client_port*/, wait_event_type, wait_event
)
--select * from a; -- for debug
select
    a.backend_type,
    a.datname as "db",
    a.state,
    a.usename as "user",
    --a.application_name as "application",
    /*
    nullif(concat_ws(':',
        host(a.client_addr),
        nullif(a.client_port, -1)
    ), '') as "client_addr:port",
    --*/
    a.wait_event_type,
    a.wait_event,
    a."count",
    a."state_changed > 1m/1h ago",

    q."max_query_elapsed.duration",
    t."max_xact_elapsed.duration",

    q."max_query_elapsed.pid",
    t."max_xact_elapsed.pid",

    q."max_query_elapsed.application_name",
    t."max_xact_elapsed.application_name",

    q."max_query_elapsed.query",
    t."max_xact_elapsed.query"
from a
left join lateral (
    select case when t.state ~ '^idle\M'
                     then t.state_change - t.query_start
                else statement_timestamp() - t.query_start
           end as query_elapsed,
           t.pid,
           t.query,
           t.application_name
    from pg_stat_activity as t
    where (a.backend_type, a.datname, a.state, a.usename, a.wait_event_type, a.wait_event) is not distinct from
          (t.backend_type, t.datname, t.state, t.usename, t.wait_event_type, t.wait_event)
          and t.query_start is not null
    order by query_elapsed desc
    limit 1
) as q ("max_query_elapsed.duration", "max_query_elapsed.pid", "max_query_elapsed.query", "max_query_elapsed.application_name") on true
left join lateral (
    select statement_timestamp() - t.xact_start as xact_elapsed,
           t.pid,
           t.query,
           t.application_name
    from pg_stat_activity as t
    where (a.backend_type, a.datname, a.state, a.usename, a.wait_event_type, a.wait_event) is not distinct from
          (t.backend_type, t.datname, t.state, t.usename, t.wait_event_type, t.wait_event)
          and t.xact_start is not null
    order by xact_elapsed desc
    limit 1
) as t ("max_xact_elapsed.duration", "max_xact_elapsed.pid", "max_xact_elapsed.query", "max_xact_elapsed.application_name") on true
order by a;
