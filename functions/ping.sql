create extension if not exists dblink schema public;

create or replace function public.ping(
    connection_str text,
    latency out interval,
    time_diff out interval
)
    returns record
    immutable
    returns null on null input
    parallel safe
    language sql
    set search_path = ''
begin atomic
    select d3.latency,
           (s.local_connection_start - s.remote_connection_start) - d3.latency as time_diff
    from public.dblink(
               ping.connection_str,
               format($sql$
                      select
                          %L                as local_connection_start,
                          a.backend_start   as remote_connection_start,
                          clock_timestamp() as remote_connection_end
                      from pg_stat_activity as a
                      where a.pid = pg_backend_pid()
                      $sql$, clock_timestamp()),
               false --fail_on_error
    ) as s (local_connection_start  timestamptz,
            remote_connection_start timestamptz,
            remote_connection_end   timestamptz),
    coalesce(clock_timestamp() /*local_connection_end*/ - s.local_connection_start) as d2(local_connection_duration),
    coalesce(s.remote_connection_end - s.remote_connection_start) as d1(remote_connection_duration),
    coalesce(d2.local_connection_duration - d1.remote_connection_duration) as d3(latency);
end;

comment on function public.ping(connection_str text,
                             latency out interval,
                             time_diff out interval) is 'Get latency and date-time difference between current and remote servers';

-- TEST
do $$
    begin
        --positive
        assert (select latency between '-1s'::interval and '1s'::interval
                   and time_diff between '-1s'::interval and '1s'::interval
                from public.ping('application_name=dblink_ping connect_timeout=3') as t);

        assert (select latency between '-1s'::interval and '1s'::interval
                   and time_diff between '-1s'::interval and '1s'::interval
                from public.ping('application_name=dblink_ping connect_timeout=3 host=127.0.0.1') as t);

        --negative
        assert public.ping(null) is null;
    end;
$$;
