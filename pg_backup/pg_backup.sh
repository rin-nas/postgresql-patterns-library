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
 
bash -n "${SCRIPT_FILE}" || exit # Check syntax this file
 
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
 
# меняем приоритет этого процесса ($$ - это его pid) на минимальный (дочерние процессы наследуют значение приоритета родительского процесса)
ionice -c 2 -n 7 -p $$
renice -n 19 -p $$
 
source "$SCRIPT_DIR/pg_backup.conf" # include
 
PG_PASS_FILE="$SCRIPT_DIR/.pgpass"
if test $(whoami) != "postgres"; then
  echoerr "pg_backup: run script as user postgres, not $(whoami)!"
  exit 1
elif ! grep -q -w "$PG_USERNAME" "$PG_PASS_FILE"; then
  echoerr "pg_backup: file '$PG_PASS_FILE' must contain record for user '$PG_USERNAME'"
  exit 1
elif test "$GPG_PASSPHRASE" = "*censored*"; then
  echoerr "pg_backup: change value of \$GPG_PASSPHRASE in '$SCRIPT_DIR/pg_backup.conf'!"
  exit 1
fi
 
# вычисляем, с какого сервера СУБД будем создавать или проверять резервную копию (Systemd service ExecCondition)
if test "${1:-}" = "ExecCondition"; then
  if ! (command -v patronictl &> /dev/null && command -v jq &> /dev/null); then
    # test ! -f "$PGDATA/standby.signal" # deprecated
    PG_ROLE=$(psql --user=$PG_USERNAME --no-password --dbname=postgres --quiet --no-psqlrc --pset=null=¤ --tuples-only --no-align \
                   --command="select case when pg_is_in_recovery() then 'standby' else 'primary' end")
    echo "pg_backup: candidate role is $PG_ROLE (checked by psql)"
    test ${2:='primary'} = "$PG_ROLE"
    exit
  fi
 
  echo 'pg_backup: check candidate role is "Sync Standby", "Leader", "Replica" (in order of priority)'
  # https://jqlang.org/manual/
  #   https://stackoverflow.com/questions/46070012/how-to-filter-an-array-of-json-objects-with-jq
  #   https://stackoverflow.com/questions/76476166/jq-sorting-by-value
  #   https://stackoverflow.com/questions/35540294/sort-descending-by-multiple-keys-in-jq
  # https://stackoverflow.com/questions/1952404/linux-bash-multiple-variable-assignment
  DC=$(hostname | grep -oP '^\w+') # текущий ЦОД
  IFS=',' read -r MEMBER HOST ROLE <<< $(patronictl -c /etc/patroni/patroni.yml list --format=json \
    | jq -Mcr --arg DC $DC '
        map(select(
          (.Member | startswith($DC + "-")) and
          .State == ("streaming", "running") and
          ."Lag in MB" < 1000
        ))
        | sort_by(.Role != ("Sync Standby", "Leader", "Replica"), .Host)
        | .[0] # LIMIT 1
        | [.Member, .Host, .Role]
        | join(",")
      ')
  test -z "$HOST" && echoerr "pg_backup: no candidate found" && exit 1
  echo "pg_backup: perform will be from '$MEMBER' [$HOST] ($ROLE)"
  test $(hostname) = "$MEMBER"
  exit
# восстанавливаем PostgreSQL из резервной копии
elif test "${1:-}" = "restore"; then
  TIME_START=$(date +%s) # время в Unixtime
 
  # скрипт должен запускаться с тремя параметрами
  test "$#" -ne 3 && echoinfo "Usage: $0 restore SOURCE_BACKUP_FILE_OR_DIR TARGET_PG_DATA_DIR" && exit 2
 
  BACKUP_FILE_OR_DIR="$2"
  if test -f "$BACKUP_FILE_OR_DIR"; then
    BACKUP_FILE="$BACKUP_FILE_OR_DIR"
  elif test -d "$BACKUP_FILE_OR_DIR"; then
    BACKUP_FILE=$(find $BACKUP_FILE_OR_DIR -maxdepth 1 -type f -name "base.tar.*" -printf "%p")
    test ! -f "$BACKUP_FILE" \
      && echoerr "pg_backup restore: source backup archive file '$BACKUP_FILE_OR_DIR/base.tar.*' does not exist!" && exit 1
  else
    echoerr "pg_backup restore: source backup archive file/directory '$BACKUP_FILE_OR_DIR' does not exist!"
    exit 1
  fi
 
  PG_DATA_DIR="$3"
  test ! -d "$PG_DATA_DIR" && echoerr "pg_backup restore: target directory '$PG_DATA_DIR' does not exist!" && exit 1
 
  # определяем архиватор по расширению файла
  BACKUP_FILE_EXT=$(echo "$BACKUP_FILE" | grep -oP '\.\Ktar\..*$')
  ARCHIVE_TYPE=$(echo "$BACKUP_FILE_EXT" | cut -d. -f2)
  if test "$ARCHIVE_TYPE" = "zst"; then
    COMPRESS_PROGRAM="unzstd"
  elif test "$ARCHIVE_TYPE" = "lz4"; then
    COMPRESS_PROGRAM="unlz4"
  else
    echoerr "pg_backup validate: no compress program found"
    exit 1
  fi
 
  echo "Расшифровываем и распаковываем архив '$BACKUP_FILE' в папку '$PG_DATA_DIR'"
  pv -treb $BACKUP_FILE \
    | gpg --decrypt --passphrase=$GPG_PASSPHRASE --batch \
    | tar -xf - --use-compress-program="$COMPRESS_PROGRAM" --directory=$PG_DATA_DIR
 
  if test -d "$BACKUP_FILE_OR_DIR"; then
    FILE="$BACKUP_FILE_OR_DIR/pg_wal.$BACKUP_FILE_EXT"
    test ! -f "$FILE" && echoerr "Файл '$FILE' не найден" && exit 1
    echo "Расшифровываем и распаковываем архив '$FILE' в папку '$PG_DATA_DIR/pg_wal'"
    pv -treb $FILE \
      | gpg --decrypt --passphrase=$GPG_PASSPHRASE --batch \
      | tar -xf - --use-compress-program="$COMPRESS_PROGRAM" --directory=$PG_DATA_DIR/pg_wal
  fi
 
  echo "Удаляем старые и ненужные файлы (информация об удалённых файлах будет выведена)"
  rm -f -r -v $PG_DATA_DIR/*.{signal,{backup,old}{,.*}} $PG_DATA_DIR/log/*
 
  TIME_END=$(date +%s) # время в Unixtime
  TIME_ELAPSED=$(elapsed $TIME_START $TIME_END)
  echosucc "pg_backup restore: success, duration: $TIME_ELAPSED (day:hh:mm:ss)"
 
  cd $PG_DATA_DIR
  read -p "Укажите роль создаваемого сервера (primary/standby): " PG_ROLE
  if test "$PG_ROLE" = "primary"; then
    touch recovery.signal && echo "Создан файл recovery.signal"
  elif test "$PG_ROLE" = "standby"; then
    touch standby.signal && echo "Создан файл standby.signal"
  else
    echoerr "Роль указана неверно, ожидается primary/standby"
    exit 1
  fi
  echowarn "Донастройте postgresql.conf и запустите кластер СУБД!"
  exit 0
# проверяем корректность и восстанавливаемость PostgreSQL из резервной копии
elif test "${1:-}" = "validate"; then
  TIME_START=$(date +%s) # время в Unixtime
 
  echo "Получаем название предпоследнего или последнего файла с архивом резервной копии (сортировка по дате модификации)"
  BACKUP_FILE=$(find $BACKUP_DIR -maxdepth 2 -type f \( -name "*.pg_backup.tar.*" -o -path "*.pg_backup/base.tar.*" \) \
                -printf "%T@ %p\n" | sort -n | tail -2 | head -1 | cut -d" " -f2)
  test -z "$BACKUP_FILE" && echoerr "pg_backup validate: no backup archive file found in directory '$BACKUP_DIR'" && exit 1
  echo "pg_backup validate: archive file '$BACKUP_FILE' selected"
 
  # определяем архиватор по расширению файла
  BACKUP_FILE_EXT=$(echo "$BACKUP_FILE" | grep -oP '\.\Ktar\..*$')
  ARCHIVE_TYPE=$(echo "$BACKUP_FILE_EXT" | cut -d. -f2)
  if test "$ARCHIVE_TYPE" = "zst"; then
    COMPRESS_PROGRAM="unzstd"
  elif test "$ARCHIVE_TYPE" = "lz4"; then
    COMPRESS_PROGRAM="unlz4"
  else
    echoerr "pg_backup validate: no compress program found"
    exit 1
  fi
  LOG_FILE_PREFIX=$(dirname $BACKUP_FILE)/$(basename $BACKUP_FILE .$BACKUP_FILE_EXT)
  touch $LOG_FILE_PREFIX.validate-selected.log
 
  PG_DATA_TEST_DIR=$(dirname $(dirname $BACKUP_DIR))/pgdata_validate
  echo "Создаём тестовую папку '$PG_DATA_TEST_DIR' для данных СУБД, удаляем старые данные (защита от предыдущего неудачного запуска скрипта)"
  test -d "$PG_DATA_TEST_DIR" && rm -r $PG_DATA_TEST_DIR && echo "pg_backup validate: old temporary directory '$PG_DATA_TEST_DIR' deleted"
  mkdir $PG_DATA_TEST_DIR
  echo "pg_backup validate: temporary directory '$PG_DATA_TEST_DIR' created"
 
  echo "Проверяем, что у папки '$PG_DATA_TEST_DIR' права доступа 750 или 700, иначе PostgreSQL не запустится"
  chmod 750 $PG_DATA_TEST_DIR
  # chmod не гарантирует изменение прав доступа на SMB/CIFS
  stat -c "%a" $PG_DATA_TEST_DIR | grep -qP '^7[05]0$' \
    || (echoerr "pg_backup validate: directory '$PG_DATA_TEST_DIR' permission must be 750 or 700" && exit 1)
 
  echo "Расшифровываем и распаковываем архив '$BACKUP_FILE' в папку '$PG_DATA_TEST_DIR'"
  gpg --decrypt --passphrase=$GPG_PASSPHRASE --batch $BACKUP_FILE \
    | tar -xf - --use-compress-program="$COMPRESS_PROGRAM" --directory=$PG_DATA_TEST_DIR
 
  BACKUP_BASE_DIR=$(echo "$BACKUP_FILE" | grep -qP '\.pg_backup/base\.tar\.' && dirname "$BACKUP_FILE" || true)
  if test -z "$BACKUP_BASE_DIR"; then
    echo "Проверяем существование папки '$WAL_DIR', из неё могут быть прочитаны дополнительные WAL файлы"
    test ! -d "$WAL_DIR" && echowarn "pg_backup validate: directory '$WAL_DIR' does not exist"
  else
    echo "Копируем '$BACKUP_BASE_DIR/backup_manifest' в папку '$PG_DATA_TEST_DIR'"
    cp $BACKUP_BASE_DIR/backup_manifest $PG_DATA_TEST_DIR
 
    FILE="$BACKUP_BASE_DIR/pg_wal.$BACKUP_FILE_EXT"
    test ! -f "$FILE" && echoerr "Файл '$FILE' не найден" && exit 1
    echo "Расшифровываем и распаковываем архив '$FILE' в папку '$PG_DATA_TEST_DIR/pg_wal'"
    gpg --decrypt --passphrase=$GPG_PASSPHRASE --batch $FILE \
      | tar -xf - --use-compress-program="$COMPRESS_PROGRAM" --directory=$PG_DATA_TEST_DIR/pg_wal
  fi
 
  DIR_SIZE=$(du -sh "$PG_DATA_TEST_DIR" | grep -oP '^\S+')
  echo "pg_backup validate: archive file extracted to directory '$PG_DATA_TEST_DIR' (total size: $DIR_SIZE)"
 
  echo "Проверяем целостность копии кластера СУБД, сделанной программой pg_basebackup, по манифесту backup_manifest"
  $PG_BIN_DIR/pg_verifybackup --no-parse-wal --exit-on-error --quiet $PG_DATA_TEST_DIR &> $LOG_FILE_PREFIX.pg_verifybackup.log
  echo "pg_backup validate: '$PG_DATA_TEST_DIR' backup verify OK"
 
  echo "Удаляем старые и ненужные файлы (информация об удалённых файлах будет выведена)"
  rm -f -r -v $PG_DATA_TEST_DIR/*.{signal,{backup,old}{,.*}} $PG_DATA_TEST_DIR/log/*
 
  echo "Разрешаем локальному пользователю postgres аутентифицироваться методом peer"
  sed -i '1i local all postgres peer' $PG_DATA_TEST_DIR/pg_hba.conf # добавляем строчку в начало файла
 
  echo "(Ре)стартуем сервер СУБД в роли мастер (рестарт - это защита от предыдущего неудачного запуска скрипта)"
  touch $PG_DATA_TEST_DIR/recovery.signal
  PG_PORT=55432
  $PG_BIN_DIR/pg_ctl restart --pgdata=$PG_DATA_TEST_DIR --silent \
    --options="-p $PG_PORT -B 128MB --cluster_name=BACKUP_VALIDATE --log_directory=log --archive_mode=off"
  echo "pg_backup validate: server started (port $PG_PORT)"
 
  echo "Проверяем подключение к СУБД"
  psql --port=$PG_PORT --user=$PG_USERNAME --no-password --dbname=postgres --no-psqlrc --command='\conninfo'
  echo "pg_backup validate: server connection OK"
 
  echo "Проверяем логическую целостность таблиц и индексов (amcheck)"
  $PG_BIN_DIR/pg_amcheck --port=$PG_PORT --username=postgres --no-password --database=* \
                         --rootdescend --on-error-stop &> $LOG_FILE_PREFIX.pg_amcheck.log
  echo "pg_backup validate: amcheck OK"
 
  echo "Останавливаем сервер СУБД"
  $PG_BIN_DIR/pg_ctl stop --pgdata=$PG_DATA_TEST_DIR --silent
  echo "pg_backup validate: server stopped"
 
  for LOG_FILE in $PG_DATA_TEST_DIR/log/*; do
    echo "Проверяем отсутствие ошибок в файле $LOG_FILE"
    grep -P '\b(WARNING|ERROR|FATAL|PANIC)\b' $LOG_FILE && exit 1 || true
  done
  echo "pg_backup validate: no problems found in log files"
 
  echo "Проверяем контрольные суммы данных в кластере СУБД"
  $PG_BIN_DIR/pg_checksums --check --pgdata=$PG_DATA_TEST_DIR &> $LOG_FILE_PREFIX.pg_checksums.log
  echo "pg_backup validate: '$PG_DATA_TEST_DIR' checksums OK"
 
  LOG_FILE=$LOG_FILE_PREFIX.pg_controldata.log
  echo "Сохраняем управляющую информацию кластера СУБД в файл '$LOG_FILE'"
  $PG_BIN_DIR/pg_controldata --pgdata=$PG_DATA_TEST_DIR &> $LOG_FILE
 
  echo "Удаляем папку '$PG_DATA_TEST_DIR', она больше не нужна"
  rm -r $PG_DATA_TEST_DIR
  echo "pg_backup validate: temporary directory '$PG_DATA_TEST_DIR' deleted"
 
  TIME_END=$(date +%s) # время в Unixtime
  TIME_ELAPSED=$(elapsed $TIME_START $TIME_END)
  LOG_FILE=$LOG_FILE_PREFIX.validate-success.log
  echo "Total size: $DIR_SIZE" >> $LOG_FILE
  echo "Validate duration: $TIME_ELAPSED (day:hh:mm:ss)" >> $LOG_FILE
  echosucc "pg_backup validate: success, duration: $TIME_ELAPSED (day:hh:mm:ss)"
  exit 0
elif test -n "${1:-}"; then
  echoerr "pg_backup: unknown first parameter '${1:-}'"
  exit 2
fi
 
# -----------------------------------------------------------------------------------------------------------------------
echoinfo "pg_backup: creating started"
TIME_START=$(date +%s) # время в Unixtime
BASE_NAME=${BACKUP_DIR}/$(date +%Y-%m-%d.%H%M%S).$(hostname).pg_backup
ZSTD_THREADS=$(echo "$(nproc) / 2.5 + 1" | bc)
mkdir -p ${BACKUP_DIR} ${WAL_DIR} # создаём директории, если их ещё нет
 
# Для многопоточного режима zstd используется степень сжатия 5, которая получена опытным путём.
# Это баланс между скоростью работы, размером сжатого файла, скоростью записи на сетевой диск с учётом его нагрузки другими процессами.
 
echo 'Проверяем необходимость бекапирования WAL файлов'
# зависит от текущего дня, настройки параметра archive_mode и роли СУБД primary/standby
IS_BACKUP_WAL=$(psql --user=$PG_USERNAME --no-password --dbname=postgres --quiet --no-psqlrc --pset=null=¤ --tuples-only --no-align \
                     --command="select extract(doy from now())%${BACKUP_WAL_DOY_DIVIDER}=0
                                       or setting='off' or (pg_is_in_recovery() and setting='on')
                                  from pg_settings where name='archive_mode'")
 
if test "$IS_BACKUP_WAL" = "f"; then
  echo 'Создаём физическую резервную копию (без WAL файлов)'
  ${PG_BIN_DIR}/pg_basebackup --username=${PG_USERNAME} --no-password --wal-method=none --checkpoint=fast --format=tar --pgdata=- \
    | zstd -q -T${ZSTD_THREADS} -5 \
    | gpg -c --passphrase=${GPG_PASSPHRASE} --batch --compress-algo=none -o ${BASE_NAME}.tar.zst.gpg
else
  echo 'Создаём физическую резервную копию (с WAL файлами)'
  # в библиотеке libzstd многопоточность поддерживается с версии 1.5.0
  LIBZSTD_VER=$(rpm -q libzstd | grep -oP '^libzstd-\K\d+\.\d+')
  test -z "$LIBZSTD_VER" && echoerr "pg_backup: cannot get libzstd version, it is installed?" && exit 1
  OPT_COMPRESS="server-zstd:level=1"
  test $(echo "$LIBZSTD_VER >= 1.5" | bc -l) = 1 && OPT_COMPRESS="server-zstd:level=5,workers=${ZSTD_THREADS}"
  ${PG_BIN_DIR}/pg_basebackup --username=${PG_USERNAME} --no-password --compress=${OPT_COMPRESS} --checkpoint=fast --format=tar \
                              --pgdata=${BASE_NAME}
 
  FILES="${BASE_NAME}/base.tar ${BASE_NAME}/pg_wal.tar"
  for FILE in $FILES; do
    if test -f "$FILE"; then
      echo "Сжимаем и шифруем '$FILE'"
      zstd -c -q -T${ZSTD_THREADS} -5 $FILE | gpg -c --passphrase=${GPG_PASSPHRASE} --batch --compress-algo=none -o $FILE.zst.gpg
      rm -f $FILE
    elif test -f "$FILE.zst"; then
      echo "Шифруем '$FILE.zst'"
      gpg -c --passphrase=${GPG_PASSPHRASE} --batch --compress-algo=none $FILE.zst
      rm -f $FILE.zst
    else
      echoerr "Файл '$FILE' или '$FILE.zst' не найден" && exit 1
    fi
  done
fi
 
# создаём логическую резервную копию (deprecated)
# ${PG_BIN_DIR}/pg_dumpall --username=${PG_USERNAME} --no-password | zstd -q -T${ZSTD_THREADS} -5 -o ${BASE_NAME}.sql.zst
 
TIME_END=$(date +%s) # время в Unixtime
TIME_ELAPSED=$(elapsed $TIME_START $TIME_END)
 
echosucc "pg_backup: created successfully, duration: $TIME_ELAPSED (day:hh:mm:ss)"
 
# -----------------------------------------------------------------------------------------------------------------------
# удаляем архивные резервные копии старше N дней (папки и файлы рекурсивно)
echo "pg_backup: deleting backup files older than ${BACKUP_AGE_DAYS} days"
find ${BACKUP_DIR} -mindepth 1 -mtime +${BACKUP_AGE_DAYS} -delete
 
# удаляем архивные WAL файлы старше N дней (сортировка по дате модификации)
echo "pg_backup: detect oldest kept WAL file for ${BACKUP_AGE_DAYS} days"
WAL_OLD_FILE=$(find ${WAL_DIR} -maxdepth 1 -mtime +${BACKUP_AGE_DAYS} -type f ! -size 0 \
                               ! -name "*.history" ! -name "*.history.*" -printf "%T@ %f\n" \
               | sort -n | tail -1 | cut -d" " -f2)
if test -z "${WAL_OLD_FILE}"; then
    echo "pg_backup: WAL old file is not found"
else
    echo "pg_backup: WAL old file is ${WAL_OLD_FILE}"
    WAL_OLD_FILE_EXT=$(echo "${WAL_OLD_FILE}" | grep -oP '\.[a-z\d]+$') # compressed files support (.gz, .zst, .lz4)
 
    BEFORE_WAL_DIR_SIZE=$(du -sh "${WAL_DIR}" | grep -oP '^\S+')
    ${PG_BIN_DIR}/pg_archivecleanup -x "${WAL_OLD_FILE_EXT}" "${WAL_DIR}" "${WAL_OLD_FILE}"
 
    AFTER_WAL_DIR_SIZE=$(du -sh "${WAL_DIR}" | grep -oP '^\S+')
    echo "pg_backup: WAL dir size reducing: ${BEFORE_WAL_DIR_SIZE} (before cleanup) -> ${AFTER_WAL_DIR_SIZE} (after cleanup)"
fi
 
echosucc "pg_backup: done"
