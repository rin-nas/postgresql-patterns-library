#!/bin/bash
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
 
# если есть файл ~/.pgpass, то можно просто ввести Enter
read -s -r -p "Enter password for user postgres: " PGPASSWORD
echo
export PGPASSWORD
 
LOG_DIR=/tmp
ARCHIVE_DIR=/mnt/backup_db/active_full/tmp
 
for DBNAME in my_db1 my_db2
do
    time ( \
        psql -U postgres -X -c "DROP DATABASE IF EXISTS ${DBNAME} WITH (FORCE)" -c "CREATE DATABASE ${DBNAME}" && \
        pv "${ARCHIVE_DIR}/${DBNAME}.sql.zst" \
            | zstd -dcq 2> "${LOG_DIR}/zstd.stderr.${DBNAME}.log" \
            | psql -U postgres -X \
                   --dbname=${DBNAME} \
                   --echo-errors \
                   --log-file="${LOG_DIR}/psql.stdout.${DBNAME}.log" \
                           2> "${LOG_DIR}/psql.stderr.${DBNAME}.log" \
    )
done
