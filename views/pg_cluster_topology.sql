/*
Предусловия:
1) На сервере, где будет выполняться SQL запрос, в файле ~postgres/.pgpass для пользователя postgres сохраните пароль
2) На СУБД с ролью мастер в базе postgres создайте расширение dblink
*/
-- Выполните в psql:
\! nano ~postgres/.pgpass
\connect postgres
create extension if not exists dblink;

-- Запускать под пользователем postgres на базе postgres на любом узле кластера СУБД!
-- Шаг 1. Получаем мастер, для этого движемся от листа к корню.
CREATE OR REPLACE VIEW pg_cluster_topology AS
with recursive m as (
    select not pg_is_in_recovery()                                    as is_primary,
           concat(regexp_replace(
               current_setting('primary_conninfo'),
               '\m(application_name|connect_timeout)=\S*', ''),
               ' application_name=dblink_topology connect_timeout=5') as conninfo,
           coalesce(inet_server_addr(), '127.0.0.1'::inet)            as addr,
           coalesce(inet_server_port(), current_setting('port')::int) as port,
           0                                                          as level
    union all
    select s.*,
           m.level - 1
    from m, dblink(m.conninfo,
                   $$select not pg_is_in_recovery(),
                            concat(regexp_replace(
                                current_setting('primary_conninfo'),
                                '\m(application_name|connect_timeout)=\S*', ''),
                                ' application_name=dblink_topology connect_timeout=5'),
                            inet_server_addr(),
                            inet_server_port()
                   $$,
                   false --fail_on_error
                  ) as s (is_primary bool, conninfo text, addr inet, port int)
    where m.is_primary = false and m.conninfo != ''
)
-- select * from m order by level; -- для отладки
-- Шаг 2. Получаем мастер и реплики, для этого движемся от корня к листам.
, r as (
    (select 1                           as level,
            null::inet                  as parent_addr,
            addr                        as addr,
            port                        as port,
            null::pg_stat_replication   as pg_sr,
            null::pg_replication_slots  as pg_rs
    from m
    where is_primary
    limit 1)
    union all
    select r.level + 1           as level,
           r.addr                as parent_addr,
           (s.pg_sr).client_addr as addr,
           r.port,
           s.pg_sr,
           s.pg_rs
    from r, dblink(format('user=postgres host=%s port=%s dbname=postgres application_name=dblink_topology connect_timeout=5', r.addr, r.port),
                   $$select pg_sr, pg_rs
                     from pg_stat_replication as pg_sr
                     left join pg_replication_slots as pg_rs on pg_sr.pid = pg_rs.active_pid
                   $$,
                   false --fail_on_error
                  ) as s (pg_sr pg_stat_replication, pg_rs pg_replication_slots)
)
select level, parent_addr, addr, port, (pg_sr).*, (pg_rs).*
from r;

COMMENT ON VIEW pg_cluster_topology IS 'Cluster topology. Returns servers: master and dependent replicas, including cascaded ones.';

/*
-- TEST example
select level, parent_addr, addr, port from pg_cluster_topology;

 level │  parent_addr   │      addr      │ port
───────┼────────────────┼────────────────┼──────
     1 │ ¤              │ 192.168.22.104 │ 5432
     2 │ 192.168.22.104 │ 192.168.22.145 │ 5432
     2 │ 192.168.22.104 │ 192.168.20.152 │ 5432
     3 │ 192.168.22.145 │ 192.168.22.86  │ 5432
(4 rows)
*/
