#!/bin/bash

# Скрипт на текущем хосте подключается к СУБД под пользователем postgres, 
# выгружает список текущих процессов в файл в формате CSV (в папку, откуда был запущен скрипт) и сжимает его через XZ.

# https://habr.com/ru/company/ruvds/blog/325522/ - Bash documentation

# https://www.gnu.org/software/bash/manual/html_node/The-Set-Builtin.html
# set -e - прекращает выполнение скрипта, если команда завершилась ошибкой
# set -u - прекращает выполнение скрипта, если встретилась несуществующая переменная
# set -x - выводит выполняемые команды в stdout перед выполнением (только для отладки, а то замусоривает журнал!)
# set -o pipefail - прекращает выполнение скрипта, даже если одна из частей пайпа завершилась ошибкой
set -euo pipefail

SCRIPT_FILE=$(readlink -f "$0")
SCRIPT_DIR=$(dirname "$SCRIPT_FILE")

# Check syntax this file
bash -n "${SCRIPT_FILE}" || exit

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

FILE="$SCRIPT_DIR/pg_stat_activity_dump.$(date +%Y-%m-%d_%H%M%S).csv.xz"

echo "$SQL" | psql --user=postgres --quiet --no-psqlrc --csv --pset=linestyle=unicode --pset=null=¤ | xz -c -9 -e > $FILE
echo "Dumped to file $FILE"

# как посмотреть протоколы в консоли?
# xz -dkc pg_stat_activity_dump.2024-11-01_124807.csv.xz | pspg --csv
# xz -dkc pg_stat_activity_dump.2024-11-01_124807.csv.xz | column -s, -t < somefile.csv | less -#2 -N -S
