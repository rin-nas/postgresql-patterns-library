SQL=$(cat <<EOF
select e.*,
       pg_blocking_pids(pid),
       a.*
       --, pg_cancel_backend(pid) -- Остановить все SQL запросы, работающие более 1 часа, сигналом SIGINT. Подключение к БД для процесса сохраняется.
       --, pg_terminate_backend(pid) -- Принудительно завершить работу всех процессов, работающих более 1 часа, сигналом SIGTERM, если не помогает SIGINT. Подключение к БД для процесса теряется.
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
  --and pid != pg_backend_pid()
  --and state_change is not null
  --and query ~ ''
  --and application_name ~ ''
  --and state !~ '^idle'
  --and wait_event = 'ClientRead' --https://postgrespro.ru/docs/postgresql/16/monitoring-stats#WAIT-EVENT-TABLE
  --and (state_change_elapsed > interval '1 minutes' or xact_elapsed > interval '1 minutes')
order by greatest(state_change_elapsed, query_elapsed, xact_elapsed) desc;

\gdesc
EOF
)

FILE="pg_stat_activity_dump.$(date +%Y-%m-%d_%H%M%S).txt"

echo "$SQL" \
  | (sudo su postgres --command="psql --quiet --no-psqlrc --pset=linestyle=unicode --pset=null=¤") > $FILE \
  && echo "Dumped to file $FILE"
  
