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
 
ARCHIVE_DIR=/mnt/backup_db/tmp
 
for dbname in my_db1 my_db2
do
    time ( \
        pg_dump --verbose --username=postgres --host=localhost --dbname=${dbname} \
            | zstd --verbose --adapt -f -q -o ${ARCHIVE_DIR}/${dbname}.sql.zst \
    )
done
 
# zstd -l ${ARCHIVE_DIR}/*.sql.zst
