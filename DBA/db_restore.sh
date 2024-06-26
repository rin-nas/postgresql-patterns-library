#!/bin/bash
# https://habr.com/ru/company/ruvds/blog/325522/ - Bash documentation
  
# https://www.gnu.org/software/bash/manual/html_node/The-Set-Builtin.html
set -euo pipefail
  
SCRIPT_FILE=$(readlink -f "$0")
SCRIPT_DIR=$(dirname "$SCRIPT_FILE")
  
# Check syntax this file
bash -n "${SCRIPT_FILE}" || exit
 
 
read -s -r -p "Enter password for postgres: " PGPASSWORD
echo
export PGPASSWORD
 
LOG_DIR=/tmp
ARCHIVE_DIR=/mnt/backup_db/active_full/tmp
 
for dbname in my_db1 my_db2
do
    time ( \
        psql -U postgres -X -c "DROP DATABASE IF EXISTS ${dbname} WITH (FORCE)" -c "CREATE DATABASE ${dbname}" && \
        pv "${ARCHIVE_DIR}/${dbname}.sql.zst" \
            | zstd -dcq 2> "${LOG_DIR}/zstd.stderr.${dbname}.log" \
            | psql -U postgres -X \
                   --dbname=${dbname} \
                   --echo-errors \
                   --set="ON_ERROR_STOP=1" \
                   --log-file="${LOG_DIR}/psql.stdout.${dbname}.log" \
                           2> "${LOG_DIR}/psql.stderr.${dbname}.log" \
    )
done
