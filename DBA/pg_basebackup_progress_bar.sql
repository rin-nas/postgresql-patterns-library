-- pg_basebackup progress bar, copy speed, estimated duration, estimated finish datetime
-- PostgreSQL 13+

-- Запуcкать под ролью postgres!!!

-- SET TIME ZONE '+3'; --MSK

select pg_size_pretty(b.backup_streamed) as pretty_backup_streamed,
       pg_size_pretty(b.backup_total) as pretty_backup_total,
       a.query_start,
       e.duration,
       round(e.progress_percent, 4) as progress_percent,
       bytes_per_second,
       (e2.estimated_duration || 'sec')::interval as estimated_duration,
       a.query_start + (e2.estimated_duration || 'sec')::interval as estimated_query_end
from pg_stat_progress_basebackup as b
inner join pg_stat_activity as a on a.pid = b.pid
cross join lateral (
    select
        NOW() - a.query_start as duration,
        b.backup_streamed * 100.0 / b.backup_total as progress_percent
) as e
cross join lateral (
    select
        EXTRACT(epoch FROM e.duration) * 100 / e.progress_percent as estimated_duration,
        round(b.backup_streamed / EXTRACT(epoch FROM e.duration)) as bytes_per_second
) as e2;
