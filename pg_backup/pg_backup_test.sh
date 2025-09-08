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
 
bash -n "$SCRIPT_FILE" || exit # check syntax this file
 
# colors
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
 
# colored messages
echoerr()  { echo -e "${Red}$@${Reset}"    1>&2; } # ошибки
echowarn() { echo -e "${Yellow}$@${Reset}" 1>&2; } # предупреждения
echohead() { echo -e "${Blue}$@${Reset}"  ; } # заголовок или этап
echoinfo() { echo -e "${White}$@${Reset}" ; } # важные сообщения
echosucc() { echo -e "${Green}$@${Reset}" ; } # сообщения об успехе
 
# функция подсчитывает длительность (day:hh:mm:ss) между временными метками в Unixtime
elapsed() {
  local time_start=$1 # time_start=$(date +%s)
  local time_end=$2   # time_end=$(date +%s)
  local dt=$(echo "$time_end - $time_start" | bc)
  local dd=$(echo "$dt/86400" | bc)
  local dt2=$(echo "$dt-86400*$dd" | bc)
  local dh=$(echo "$dt2/3600" | bc)
  local dt3=$(echo "$dt2-3600*$dh" | bc)
  local dm=$(echo "$dt3/60" | bc)
  local ds=$(echo "$dt3-60*$dm" | bc)
  printf '%dd:%02d:%02d:%02d' $dd $dh $dm $ds
}
 
read -p "Запустить тестирование скрипта pg_backup.sh на тестовой СУБД? (yes/no): " RUN_FLAG
if test "$RUN_FLAG" != "yes"; then
  echowarn "Запуск отменён"
  exit 1
fi
 
echohead "Test started"
TIME_START=$(date +%s) # время в Unixtime
 
BACKUP_DIR="/mnt/backup_db/active_full/cluster"
TEMP_DIR="$BACKUP_DIR/pg_backup_test"
CONF_FILE="$SCRIPT_DIR/pg_backup.conf"
 
for BACKUP_WAL_DOY_DIVIDER in 1 999; do
  for FLAG in 0 1; do
 
    echohead "Корректируем '$CONF_FILE': BACKUP_WAL_DOY_DIVIDER=$BACKUP_WAL_DOY_DIVIDER, GPG_ENCRYPT=$FLAG, PG_AMCHECK_VALIDATE=$FLAG"
    sed -E -e "s/(BACKUP_WAL_DOY_DIVIDER)=[0-9]+/\1=${BACKUP_WAL_DOY_DIVIDER}/" \
           -e "s/(GPG_ENCRYPT)=[0-9]+/\1=${FLAG}/" \
           -e "s/(PG_AMCHECK_VALIDATE)=[0-9]+/\1=${FLAG}/" \
           -i $CONF_FILE
 
    echohead "Удаляем все файлы в папке '$BACKUP_DIR'"
    find $BACKUP_DIR -mindepth 1 -delete
 
    echohead "Тестируем ExecCondition"
    sudo -i -u postgres -- ./pg_backup.sh ExecCondition
 
    echohead "Тестируем create"
    sudo -i -u postgres -- ./pg_backup.sh create
 
    echohead "Тестируем validate"
    sudo -i -u postgres -- ./pg_backup.sh validate
 
    echohead "Получаем название папки/файла бекапа"
    BACKUP_FILE_OR_DIR=$(find $BACKUP_DIR -maxdepth 1 -name "*.pg_backup*" ! -name "*.log" -printf "%p")
    test -z "$BACKUP_FILE_OR_DIR" && echoerr "no backup archive file/directory found in directory '$BACKUP_DIR'" && exit 1
    echo "Название папки/файла бекапа: '$BACKUP_FILE_OR_DIR'"
     
    echohead "Создаём временную папку '$TEMP_DIR'"
    sudo -i -u postgres -- mkdir -p $TEMP_DIR
 
    echohead "Тестируем restore"
    printf 'primary\n' | sudo -i -u postgres -- ./pg_backup.sh restore $BACKUP_FILE_OR_DIR $TEMP_DIR
 
    echohead "Удаляем временную папку '$TEMP_DIR'"
    sudo -i -u postgres -- rm -r $TEMP_DIR
  done
done
 
TIME_END=$(date +%s) # время в Unixtime
TIME_ELAPSED=$(elapsed $TIME_START $TIME_END)
echosucc "Test finished successfully, duration: $TIME_ELAPSED (day:hh:mm:ss)"
