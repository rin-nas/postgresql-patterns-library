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

# Colors
Red='\e[1;31m'
Green='\e[0;32m'
Yellow='\e[38;5;220m'
Blue='\e[38;5;39m'
Orange='\e[38;5;214m'
Magenta='\e[0;35m'
Cyan='\e[0;36m'
Gray='\e[0;37m'
White='\e[1;37m'
Reset='\e[0m'

# Colored messages
echoerr()  { echo -e "${Red}$@${Reset}"    1>&2; }
echowarn() { echo -e "${Yellow}$@${Reset}" 1>&2; }
echoinfo() { echo -e "${White}$@${Reset}" ; }
echosucc() { echo -e "${Green}$@${Reset}" ; }

elapsed() {
  local time_start=$1 #time_start=$(date +%s)
  local time_end=$2  #time_end=$(date +%s)
  local dt=$(echo "$time_end - $time_start" | bc)
  local dd=$(echo "$dt/86400" | bc)
  local dt2=$(echo "$dt-86400*$dd" | bc)
  local dh=$(echo "$dt2/3600" | bc)
  local dt3=$(echo "$dt2-3600*$dh" | bc)
  local dm=$(echo "$dt3/60" | bc)
  local ds=$(echo "$dt3-60*$dm" | bc)
  printf '%dd:%02d:%02d:%02d' $dd $dh $dm $ds #day:hh:mm:ss
}

# include
source "$SCRIPT_DIR/pg_backup.conf"

# calculated variables
PG_BIN_DIR="/usr/pgsql-${PG_MAJOR_VERSION}/bin"
FILENAME=${BACKUP_DIR}/$(date +%Y-%m-%d.%H-%M-%S).$(hostname)

if test $(whoami) != "postgres"; then
    echoerr "PostgreSQL backup: run script as user postgres, not $(whoami)!"
    exit 1
elif ! grep -q -P "\b${PG_USERNAME}\b" /var/lib/pgsql/.pgpass; then
    echoerr "File /var/lib/pgsql/.pgpass must contain rule for user '${PG_USERNAME}'"
    exit 1
fi

echoinfo "PostgreSQL backup: creating started"
TIME_START=$(date +%s) #время в Unixtime

# создаём директории, если их ещё нет
mkdir -p ${BACKUP_DIR} ${WAL_DIR}

# создаём физический бэкап
# zstd adapt compression level depending on I/O conditions, mainly how fast it can write the output
# В zstd v1.4.4 плохо работает адаптивный режим с кол-вом потоков > 1 (--adapt -T), постепенно увеличивается степень сжатия и длительность работы.
# Для многопоточного режима лучше явно поставить степень сжатия.
ZSTD_THREADS=$(echo "$(nproc) / 2.5 + 1" | bc)
${PG_BIN_DIR}/pg_basebackup --username=${PG_USERNAME} --no-password --wal-method=none --checkpoint=fast --format=tar --pgdata=- \
  | zstd -q -T${ZSTD_THREADS} -5 -o ${FILENAME}.pg_basebackup.tar.zst

# создаём логический бэкап (deprecated)
# ${PG_BIN_DIR}/pg_dumpall --username=${PG_USERNAME} --no-password | zstd -q -T${ZSTD_THREADS} -5 -o ${FILENAME}.sql.zst

TIME_END=$(date +%s) #время в Unixtime
TIME_ELAPSED=$(elapsed $TIME_START $TIME_END)

echosucc "PostgreSQL backup: created successfully, duration: $TIME_ELAPSED (day:hh:mm:ss)"

# удаляем архивные резервные копии старше N дней (папки и файлы рекурсивно)
echo "PostgreSQL backup: deleting backup files older than ${BACKUP_AGE_DAYS} days"
find ${BACKUP_DIR} -mindepth 1 -mtime +${BACKUP_AGE_DAYS} -delete

# удаляем архивные WAL файлы старше N дней
echo "PostgreSQL backup: detect oldest kept WAL file for ${BACKUP_AGE_DAYS} days"
WAL_OLD_FILE=$(find ${WAL_DIR} -maxdepth 1 -mtime +${BACKUP_AGE_DAYS} -type f -printf "%C@ %f\n" | sort -n | tail -n 1 | cut -d" " -f2)
if test -z "${WAL_OLD_FILE}"; then
    echo "PostgreSQL backup: WAL old file is not found"
else
    echo "PostgreSQL backup: WAL old file is ${WAL_OLD_FILE}"
 
    WAL_DIR_SIZE=$(du -sh "${WAL_DIR}" | grep -oP "^\S+")
    echo "PostgreSQL backup: Before cleanup WAL dir size: ${WAL_DIR_SIZE}"
 
    WAL_OLD_FILE_EXT=$(echo "${WAL_OLD_FILE}" | grep -oP "\.[a-z\d]+$") # compressed files support (.gz, .zst, .lz4)
    ${PG_BIN_DIR}/pg_archivecleanup -x "${WAL_OLD_FILE_EXT}" "${WAL_DIR}" "${WAL_OLD_FILE}"
 
    WAL_DIR_SIZE=$(du -sh "${WAL_DIR}" | grep -oP "^\S+")
    echo "PostgreSQL backup: After cleanup WAL dir size: ${WAL_DIR_SIZE}"
fi

echosucc "PostgreSQL backup: done"
