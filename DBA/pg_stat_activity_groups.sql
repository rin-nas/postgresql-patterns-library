with a as (
    select
        a.backend_type,
        a.datname,
        a.state,
        a.usename,
        a.wait_event_type,
        a.wait_event,
        count(*) as count
    from pg_stat_activity as a
    group by a.backend_type, a.datname, a.state, a.usename, a.wait_event_type, a.wait_event
    order by a.backend_type, a.datname, a.state, a.usename, a.wait_event_type, a.wait_event
)
--select * from a; -- для отладки
select
    a.*,
    --q.*,

    --t.*
    q."max_query_elapsed.duration",
    t."max_xact_elapsed.duration",

    q."max_query_elapsed.application_name",
    t."max_xact_elapsed.application_name",

    q."max_query_elapsed.query",
    t."max_xact_elapsed.query"
from a
left join lateral (
    select d.query_elapsed,
           t.query,
           t.application_name
    from pg_stat_activity as t
    cross join coalesce(case when t.state ~ '^idle\M'
                                  then t.state_change - t.query_start
                             else statement_timestamp() - t.query_start
                        end) as d(query_elapsed)
    where (a.backend_type, a.datname, a.state, a.usename, a.wait_event_type, a.wait_event) is not distinct from
          (t.backend_type, t.datname, t.state, t.usename, t.wait_event_type, t.wait_event)
          and t.query_start is not null
    order by d.query_elapsed desc
    limit 1
) as q ("max_query_elapsed.duration", "max_query_elapsed.query", "max_query_elapsed.application_name") on true
left join lateral (
    select d.xact_elapsed,
           t.query,
           t.application_name
    from pg_stat_activity as t
    cross join coalesce(statement_timestamp() - t.xact_start) as d(xact_elapsed)
    where (a.backend_type, a.datname, a.state, a.usename, a.wait_event_type, a.wait_event) is not distinct from
          (t.backend_type, t.datname, t.state, t.usename, t.wait_event_type, t.wait_event)
      and t.xact_start is not null
    order by d.xact_elapsed desc
    limit 1
) as t ("max_xact_elapsed.duration", "max_xact_elapsed.query", "max_xact_elapsed.application_name") on true
order by a;
