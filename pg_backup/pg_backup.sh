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
 
# для минимизации рисков влияния на работающую СУБД меняем приоритет этого процесса ($$ - это его pid) на минимальный
# (дочерние процессы наследуют значение приоритета родительского процесса)
ionice -c 2 -n 7 -p $$
renice -n 19 -p $$
 
source "$SCRIPT_DIR/pg_backup.conf" # include
TIME_START=$(date +%s) # время в Unixtime
 
# разные обязательные общие проверки при запуске скрипта
if test "$(whoami)" != "postgres"; then
  echoerr "pg_backup: run script as user 'postgres', not '$(whoami)'"
  exit 1
elif ! grep -q -w "$PG_USERNAME" "$PG_PASS_FILE"; then
  echoerr "pg_backup: file '$PG_PASS_FILE' must contain record for user '$PG_USERNAME'"
  exit 1
elif ! (echo "$PG_AMCHECK_VALIDATE" | grep -qoP '^[01]$'); then
  echoerr "pg_backup: '$SCRIPT_DIR/pg_backup.conf': incorrect value of PG_AMCHECK_VALIDATE, expected 0 or 1"
  exit 1
elif ! (echo "$GPG_ENCRYPT" | grep -qoP '^[01]$'); then
  echoerr "pg_backup: '$SCRIPT_DIR/pg_backup.conf': incorrect value of GPG_PASSPHRASE, expected 0 or 1"
  exit 1
elif test "$GPG_ENCRYPT" = 1 && test "$GPG_PASSPHRASE" = "*censored*"; then
  echoerr "pg_backup: '$SCRIPT_DIR/pg_backup.conf': change default value of GPG_PASSPHRASE"
  exit 1
elif test ! -d "$BACKUP_DIR"; then
  echoerr "pg_backup: directory '$BACKUP_DIR' does not exist"
  exit 1
elif test ! -d "$WAL_DIR"; then
  echoerr "pg_backup: directory '$WAL_DIR' does not exist"
  exit 1
elif test ! -x "$PG_ARCHIVE_COMMAND_FILE"; then
  echoerr "pg_backup: file '$PG_ARCHIVE_COMMAND_FILE' does not exist or user has not execute access"
  exit 1
elif test ! -x "$PG_RESTORE_COMMAND_FILE"; then
  echoerr "pg_backup: file '$PG_RESTORE_COMMAND_FILE' does not exist or user has not execute access"
  exit 1
fi
 
# вычисляем, с какого сервера СУБД будем создавать или проверять резервную копию (Systemd service ExecCondition)
if test "${1:-}" = "ExecCondition"; then
  if ! (command -v patronictl &> /dev/null && command -v jq &> /dev/null); then
    # test ! -f "$PGDATA/standby.signal" # deprecated
    PG_ROLE=$(psql --username=$PG_USERNAME --no-password --dbname=postgres --quiet --no-psqlrc --pset=null=¤ --tuples-only --no-align \
                   --command="select case when pg_is_in_recovery() then 'standby' else 'primary' end")
    echo "pg_backup: candidate role is $PG_ROLE (checked by psql)"
    test ${2:-primary} = "$PG_ROLE"
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
# на экране будет отображаться прогресс работы в процентах, скорость работы в мегабайтах/секунду, текущая и оставшаяся длительность работы
elif test "${1:-}" = "restore"; then
  # скрипт должен запускаться с тремя параметрами
  test "$#" -ne 3 && echoinfo "Usage: $0 restore SOURCE_BACKUP_FILE_OR_DIR TARGET_PG_DATA_DIR" && exit 2
 
  BACKUP_FILE_OR_DIR="$2"
  if test -f "$BACKUP_FILE_OR_DIR"; then
    BACKUP_FILE="$BACKUP_FILE_OR_DIR"
  elif test -d "$BACKUP_FILE_OR_DIR"; then
    BACKUP_FILE=$(find $BACKUP_FILE_OR_DIR -maxdepth 1 -type f -name "base.tar.*" ! -name "*.log" -printf "%p")
    test ! -f "$BACKUP_FILE" \
      && echoerr "pg_backup restore: source backup archive file '$BACKUP_FILE_OR_DIR/base.tar.*' does not exist" && exit 1
  else
    echoerr "pg_backup restore: source backup archive file/directory '$BACKUP_FILE_OR_DIR' does not exist"
    exit 1
  fi
 
  PG_DATA_DIR="$3"
  test ! -d "$PG_DATA_DIR" && echoerr "pg_backup restore: target directory '$PG_DATA_DIR' does not exist" && exit 1
 
  # определяем архиватор по расширению файла
  BACKUP_FILE_EXT=$(basename "$BACKUP_FILE" | grep -oP '\.\Ktar\..+$')
  ARCHIVE_TYPE=$(echo "$BACKUP_FILE_EXT" | cut -d. -f2)
  COMPRESS_PROGRAM=$(echo "zst:unzstd,lz4:unlz4,gz:unpigz" | grep -oP "\b${ARCHIVE_TYPE}:\K[^,]+")
  if test -z "$ARCHIVE_TYPE" || test -z "$COMPRESS_PROGRAM"; then
    echoerr "pg_backup validate: no compress program found"
    exit 1
  fi
 
  if test "$GPG_ENCRYPT" = 0; then
    echo "Распаковываем архив '$BACKUP_FILE' в папку '$PG_DATA_DIR'"
    GPG_COMMAND="cat"
  else
    echo "Расшифровываем и распаковываем архив '$BACKUP_FILE' в папку '$PG_DATA_DIR'"
    GPG_COMMAND="gpg --decrypt --passphrase=$GPG_PASSPHRASE --batch"
  fi
  # посмотреть прогресс выполнения процесса pv: sudo pv -d PID
  pv -trebp $BACKUP_FILE \
    | $GPG_COMMAND \
    | tar -xf - --use-compress-program="$COMPRESS_PROGRAM" --directory=$PG_DATA_DIR
 
  if test -d "$BACKUP_FILE_OR_DIR"; then
    WAL_FILE="$BACKUP_FILE_OR_DIR/pg_wal.$BACKUP_FILE_EXT"
    test ! -f "$WAL_FILE" && echoerr "Файл '$WAL_FILE' не найден" && exit 1
    if test "$GPG_ENCRYPT" = 0; then
      echo "Распаковываем архив '$WAL_FILE' в папку '$PG_DATA_DIR/pg_wal'"
    else
      echo "Расшифровываем и распаковываем архив '$WAL_FILE' в папку '$PG_DATA_DIR/pg_wal'"
    fi
    pv -trebp $WAL_FILE \
      | $GPG_COMMAND \
      | tar -xf - --use-compress-program="$COMPRESS_PROGRAM" --directory=$PG_DATA_DIR/pg_wal
  fi
 
  echo "Удаляем старые и ненужные файлы (информация об удалённых файлах будет выведена)"
  # https://www.google.com/search?q=Linux+curly+brace+expansion+documentation
  rm -f -r -v $PG_DATA_DIR/{*.{signal,{backup,old}{,.*}},log/*,*~}
 
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
  echowarn "После старта СУБД дождитесь наката всех WAL файлов. Проверить завершение можно запросом select pg_is_in_recovery()"
  exit 0
 
# проверяем корректность и восстанавливаемость PostgreSQL из резервной копии
elif test "${1:-}" = "validate"; then
  echo "Получаем название предпоследнего или последнего файла с архивом резервной копии (сортировка по дате модификации)"
  BACKUP_FILE=$(find $BACKUP_DIR -maxdepth 2 -type f \( -name "*.pg_backup.tar.*" -o -path "*.pg_backup/base.tar.*" \) \
                ! -name "*.log" -printf "%T@ %p\n" | sort -n | tail -2 | head -1 | cut -d" " -f2)
  test -z "$BACKUP_FILE" && echoerr "pg_backup validate: no backup archive file found in directory '$BACKUP_DIR'" && exit 1
  echo "pg_backup validate: archive file '$BACKUP_FILE' selected"
 
  # определяем архиватор по расширению файла
  BACKUP_FILE_EXT=$(basename "$BACKUP_FILE" | grep -oP '\.\Ktar\..+$')
  ARCHIVE_TYPE=$(echo "$BACKUP_FILE_EXT" | cut -d. -f2)
  COMPRESS_PROGRAM=$(echo "zst:unzstd,lz4:unlz4,gz:unpigz" | grep -oP "\b${ARCHIVE_TYPE}:\K[^,]+")
  if test -z "$ARCHIVE_TYPE" || test -z "$COMPRESS_PROGRAM"; then
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
 
  if test "$GPG_ENCRYPT" = 0; then
    echo "Распаковываем архив '$BACKUP_FILE' в папку '$PG_DATA_TEST_DIR'"
    # посмотреть прогресс выполнения процесса pv: sudo pv -d PID
    pv $BACKUP_FILE \
      | tar -xf - --use-compress-program="$COMPRESS_PROGRAM" --directory=$PG_DATA_TEST_DIR 2> $LOG_FILE_PREFIX.tar.stderr.log
  else
    echo "Расшифровываем и распаковываем архив '$BACKUP_FILE' в папку '$PG_DATA_TEST_DIR'"
    # посмотреть прогресс выполнения процесса pv: sudo pv -d PID
    pv $BACKUP_FILE \
      | gpg --decrypt --passphrase=$GPG_PASSPHRASE --batch 2> $LOG_FILE_PREFIX.gpg.stderr.log \
      | tar -xf - --use-compress-program="$COMPRESS_PROGRAM" --directory=$PG_DATA_TEST_DIR 2> $LOG_FILE_PREFIX.tar.stderr.log
  fi
 
  BACKUP_BASE_DIR=$(echo "$BACKUP_FILE" | grep -qP '\.pg_backup/base\.tar\.' && dirname "$BACKUP_FILE" || true)
  if test ! -z "$BACKUP_BASE_DIR"; then
    echo "Копируем '$BACKUP_BASE_DIR/backup_manifest' в папку '$PG_DATA_TEST_DIR'"
    cp $BACKUP_BASE_DIR/backup_manifest $PG_DATA_TEST_DIR
 
    WAL_FILE="$BACKUP_BASE_DIR/pg_wal.$BACKUP_FILE_EXT"
    test ! -f "$WAL_FILE" && echoerr "Файл '$WAL_FILE' не найден" && exit 1
    if test "$GPG_ENCRYPT" = 0; then
      echo "Распаковываем архив '$WAL_FILE' в папку '$PG_DATA_TEST_DIR/pg_wal'"
      pv $WAL_FILE \
        | tar -xf - --use-compress-program="$COMPRESS_PROGRAM" --directory=$PG_DATA_TEST_DIR/pg_wal \
          2> $LOG_FILE_PREFIX.tar.stderr.log
    else
      echo "Расшифровываем и распаковываем архив '$WAL_FILE' в папку '$PG_DATA_TEST_DIR/pg_wal'"
      pv $WAL_FILE \
        | gpg --decrypt --passphrase=$GPG_PASSPHRASE --batch \
          2> $LOG_FILE_PREFIX.gpg.stderr.log \
        | tar -xf - --use-compress-program="$COMPRESS_PROGRAM" --directory=$PG_DATA_TEST_DIR/pg_wal \
          2> $LOG_FILE_PREFIX.tar.stderr.log
    fi
  fi
 
  DIR_SIZE=$(du -sh "$PG_DATA_TEST_DIR" | grep -oP '^\S+')
  echo "pg_backup validate: archive file extracted to directory '$PG_DATA_TEST_DIR' (total size: $DIR_SIZE)"
 
  echo "Проверяем целостность копии кластера СУБД, сделанной программой pg_basebackup, по манифесту backup_manifest"
  $PG_BIN_DIR/pg_verifybackup --no-parse-wal --exit-on-error --quiet $PG_DATA_TEST_DIR \
    1> $LOG_FILE_PREFIX.pg_verifybackup.stdout.log \
    2> $LOG_FILE_PREFIX.pg_verifybackup.stderr.log
  echo "pg_backup validate: '$PG_DATA_TEST_DIR' backup verify OK"
 
  echo "Удаляем старые и ненужные файлы (информация об удалённых файлах будет выведена)"
  # https://www.google.com/search?q=Linux+curly+brace+expansion+documentation
  rm -f -r -v $PG_DATA_TEST_DIR/{*.{signal,{backup,old}{,.*}},log/*,*~}
 
  echo "Разрешаем локальному пользователю postgres аутентифицироваться методом peer"
  sed -i '1i local all postgres peer' $PG_DATA_TEST_DIR/pg_hba.conf # добавляем строчку в начало файла
 
  echo "(Ре)стартуем сервер СУБД в роли мастер (рестарт - это защита от предыдущего неудачного запуска скрипта)"
  touch $PG_DATA_TEST_DIR/recovery.signal
  PG_PORT=55432
  $PG_BIN_DIR/pg_ctl restart --pgdata=$PG_DATA_TEST_DIR \
    --options="-p $PG_PORT -B 128MB --cluster_name=BACKUP_VALIDATE --archive_mode=off --log_directory=$PG_DATA_TEST_DIR/log" \
    --options="--hba_file=$PG_DATA_TEST_DIR/pg_hba.conf --ident-file=$PG_DATA_TEST_DIR/pg_ident.conf" \
    --options="--restore_command='$PG_RESTORE_COMMAND_FILE %f %p'" \
    1> $LOG_FILE_PREFIX.pg_ctl.stdout.log \
    2> $LOG_FILE_PREFIX.pg_ctl.stderr.log
  echoinfo "pg_backup validate: server started (port $PG_PORT)"
 
  # ВНИМАНИЕ! После старта тестовой СУБД завершать работу скрипта с ошибкой нельзя до остановки СУБД!
 
  echo "Ждём, пока накатятся WAL файлы"
  while true; do
    PG_IS_IN_RECOVERY=$(psql --port=$PG_PORT --username=postgres --no-password --dbname=postgres --quiet --no-psqlrc \
                             --pset=null=¤ --tuples-only --no-align --command="select pg_is_in_recovery()")
    test -z "$PG_IS_IN_RECOVERY" && echowarn "pg_backup validate: get in recovery status error" && break
    test "$PG_IS_IN_RECOVERY" = "f" && echo && break
    sleep 1
    # echo -n "." # debug only
  done
 
  echo "Проверяем количество ошибок в контрольных суммах"
  CHECKSUM_FAILURES=$(psql --port=$PG_PORT --username=postgres --no-password --dbname=postgres --quiet --no-psqlrc \
                           --pset=null=¤ --tuples-only --no-align --command='select sum(checksum_failures) from pg_stat_database' \
                        2> $LOG_FILE_PREFIX.psql.stderr.log) || true
  if test -z "$CHECKSUM_FAILURES"; then
    echowarn "pg_backup validate: connection ERROR"
  elif test "$CHECKSUM_FAILURES" = "¤"; then
    echowarn "pg_backup validate: data checksums disabled"
  elif test "$CHECKSUM_FAILURES" -gt 0; then
    echowarn "pg_backup validate: data checksum failures: $CHECKSUM_FAILURES"
  else
    echo "pg_backup validate: data checksum failures: 0"
  fi
 
  if test "$PG_AMCHECK_VALIDATE" = 0; then
    echowarn "Проверка логической целостности таблиц и индексов (amcheck) отключена"
  else
    echo "Проверяем логическую целостность таблиц и индексов (amcheck)"
    if $PG_BIN_DIR/pg_amcheck --port=$PG_PORT --username=postgres --no-password --database=* --rootdescend --on-error-stop \
                           1> $LOG_FILE_PREFIX.pg_amcheck.stdout.log \
                           2> $LOG_FILE_PREFIX.pg_amcheck.stderr.log ; then
      echo "pg_backup validate: amcheck OK"
    else
      echowarn "pg_backup validate: amcheck ERROR"
    fi
  fi
 
  echo "Останавливаем сервер СУБД"
  $PG_BIN_DIR/pg_ctl stop --pgdata=$PG_DATA_TEST_DIR \
    1> $LOG_FILE_PREFIX.pg_ctl.stdout.log \
    2> $LOG_FILE_PREFIX.pg_ctl.stderr.log
  echoinfo "pg_backup validate: server stopped (port $PG_PORT)"
 
  BAD_WORDS_RE="\b(WARNING|ERROR|FATAL|PANIC|ignored?|(fail|(?<!might be )corrupt|unexpect)(ed)?)\b"
  for LOG_FILE in $PG_DATA_TEST_DIR/log/*; do
    echo "Проверяем отсутствие ошибок '$BAD_WORDS_RE' в файле '$LOG_FILE'"
    grep -i -P "$BAD_WORDS_RE" $LOG_FILE && echoerr "pg_backup validate: problems found in log file '$LOG_FILE'" && exit 1 || true
  done
  echo "pg_backup validate: no problems found in log files"
 
  if echo "$CHECKSUM_FAILURES" | grep -qP '^\d+$'; then
    echo "Проверяем контрольные суммы данных в кластере СУБД"
    $PG_BIN_DIR/pg_checksums --check --pgdata=$PG_DATA_TEST_DIR \
      1> $LOG_FILE_PREFIX.pg_checksums.stdout.log \
      2> $LOG_FILE_PREFIX.pg_checksums.stderr.log
    echo "pg_backup validate: '$PG_DATA_TEST_DIR' checksums OK"
  fi
 
  echo "Сохраняем управляющую информацию кластера СУБД"
  $PG_BIN_DIR/pg_controldata --pgdata=$PG_DATA_TEST_DIR \
    1> $LOG_FILE_PREFIX.pg_controldata.stdout.log \
    2> $LOG_FILE_PREFIX.pg_controldata.stderr.log
 
  echo "Удаляем папку '$PG_DATA_TEST_DIR', она больше не нужна"
  rm -r $PG_DATA_TEST_DIR
  echo "pg_backup validate: temporary directory '$PG_DATA_TEST_DIR' deleted"
 
  TIME_END=$(date +%s) # время в Unixtime
  TIME_ELAPSED=$(elapsed $TIME_START $TIME_END)
  LOG_FILE=$LOG_FILE_PREFIX.validate-success.log
  echo "Total size: $DIR_SIZE" > $LOG_FILE
  echo "Validate duration: $TIME_ELAPSED (day:hh:mm:ss)" >> $LOG_FILE
  echosucc "pg_backup validate: success, duration: $TIME_ELAPSED (day:hh:mm:ss)"
  exit 0
 
elif test "${1:-}" != "create"; then
  echoinfo "Usage: $0 COMMAND"
  echo "COMMAND - one of: create, validate, restore"
  exit 2
fi
 
# -----------------------------------------------------------------------------------------------------------------------
echoinfo "pg_backup: creating started"
BASE_NAME=${BACKUP_DIR}/$(date +%Y-%m-%d.%H%M%S).$(hostname).pg_backup
COMPRESS_THREADS=$(echo "$(nproc) / 2.5 + 1" | bc)
 
# для многопоточного режима используется максимальная степень сжатия 5, которая была получена опытным путём
# это баланс между потреблением CPU и памяти, размером сжатого файла, скоростью записи на сетевой диск, с учётом нагрузки другими процессами
COMPRESS_LEVEL=$COMPRESS_THREADS
test "$COMPRESS_LEVEL" -gt 5 && COMPRESS_LEVEL=5
 
echo 'Проверяем необходимость бекапирования WAL файлов'
# зависит от текущего дня, настройки параметра archive_mode и роли СУБД primary/standby
IS_BACKUP_WAL=$(psql --username=$PG_USERNAME --no-password --dbname=postgres --quiet --no-psqlrc --pset=null=¤ --tuples-only --no-align \
                     --command="select extract(doy from now())::int % ${BACKUP_WAL_DOY_DIVIDER} = 0 --cast to int for Postgres v12
                                       or setting = 'off' or (pg_is_in_recovery() and setting = 'on')
                                  from pg_settings where name = 'archive_mode'")
 
if test "$IS_BACKUP_WAL" = "f"; then
  echo 'Создаём физическую резервную копию (без WAL файлов)'
  COMMAND="${PG_BIN_DIR}/pg_basebackup --username=${PG_USERNAME} --no-password --wal-method=none --checkpoint=fast --format=tar --pgdata=-"
  if test "$GPG_ENCRYPT" = 0; then
    FILE="${BASE_NAME}.tar.zst"
    ($COMMAND | zstd -q -T${COMPRESS_THREADS} -${COMPRESS_LEVEL} -o $FILE) 2> $BASE_NAME.stderr.log
  else
    FILE="${BASE_NAME}.tar.zst.gpg"
    ($COMMAND | zstd -q -T${COMPRESS_THREADS} -${COMPRESS_LEVEL} \
              | gpg -c --passphrase=${GPG_PASSPHRASE} --batch --compress-algo=none -o $FILE) 2> $BASE_NAME.stderr.log
  fi
  SIZE=$(du -sh "$FILE" | grep -oP '^\S+')
  echoinfo "Создан файл '$FILE' (size: $SIZE)"
else
  echo 'Создаём физическую резервную копию (с WAL файлами)'
  PG_MAJOR_VER=$(echo "$PG_BIN_DIR" | grep -oP '\-\K\d+(?=/)')
  OPT_COMPRESS=1 # gzip support only
  if test "$PG_MAJOR_VER" -ge 15; then
    # в библиотеке libzstd многопоточность поддерживается с версии 1.5.0
    LIBZSTD_VER=$(rpm -q libzstd | grep -oP '^libzstd-\K\d+\.\d+')
    test -z "$LIBZSTD_VER" && echoerr "pg_backup: cannot get libzstd version, it is installed?" && exit 1
    OPT_COMPRESS="server-zstd:level=1"
    test $(echo "$LIBZSTD_VER >= 1.5" | bc -l) = 1 && OPT_COMPRESS="server-zstd:level=${COMPRESS_LEVEL},workers=${COMPRESS_THREADS}"
  fi
  mkdir -p ${BASE_NAME}
  ${PG_BIN_DIR}/pg_basebackup --username=${PG_USERNAME} --no-password --compress=${OPT_COMPRESS} --checkpoint=fast --format=tar \
                              --pgdata=${BASE_NAME} \
                           2> $BASE_NAME.stderr.log
 
  FILES="${BASE_NAME}/base.tar ${BASE_NAME}/pg_wal.tar"
  for FILE in $FILES; do
    if test -f "$FILE"; then
      if test "$GPG_ENCRYPT" = 0; then
        echo "Сжимаем '$FILE'"
        if test "$PG_MAJOR_VER" -ge 15; then
          zstd -c -q -T${COMPRESS_THREADS} -${COMPRESS_LEVEL} $FILE -o $FILE.zst 2> $BASE_NAME.stderr.log
        else
          pigz -c -q -p ${COMPRESS_THREADS} -${COMPRESS_LEVEL} -o $FILE.gz 2> $BASE_NAME.stderr.log
        fi
      else
        echo "Сжимаем и шифруем '$FILE'"
        if test "$PG_MAJOR_VER" -ge 15; then
          (zstd -c -q -T${COMPRESS_THREADS} -${COMPRESS_LEVEL} $FILE \
             | gpg -c --passphrase=${GPG_PASSPHRASE} --batch --compress-algo=none -o $FILE.zst.gpg) 2> $BASE_NAME.stderr.log
        else
          (pigz -c -q -p ${COMPRESS_THREADS} -${COMPRESS_LEVEL} $FILE \
             | gpg -c --passphrase=${GPG_PASSPHRASE} --batch --compress-algo=none -o $FILE.gz.gpg) 2> $BASE_NAME.stderr.log
        fi
      fi
      rm -f $FILE
    elif test -f "$FILE.zst"; then
      if test "$GPG_ENCRYPT" = 1; then
        echo "Шифруем '$FILE.zst'"
        gpg -c --passphrase=${GPG_PASSPHRASE} --batch --compress-algo=none $FILE.zst 2> $BASE_NAME.stderr.log
        rm -f $FILE.zst
      fi
    elif test -f "$FILE.gz"; then
      if test "$GPG_ENCRYPT" = 1; then
        echo "Шифруем '$FILE.gz'"
        gpg -c --passphrase=${GPG_PASSPHRASE} --batch --compress-algo=none $FILE.gz 2> $BASE_NAME.stderr.log
        rm -f $FILE.gz
      fi
    else
      echoerr "Файл '$FILE' или '$FILE.zst' или '$FILE.gz' не найден" && exit 1
    fi
  done
  SIZE=$(du -sh "$BASE_NAME" | grep -oP '^\S+')
  echoinfo "Создана папка '$BASE_NAME' (total size: $SIZE)"
fi
 
# создаём логическую резервную копию (deprecated)
# ${PG_BIN_DIR}/pg_dumpall --username=${PG_USERNAME} --no-password | zstd -q -T${COMPRESS_THREADS} -${COMPRESS_LEVEL} -o ${BASE_NAME}.sql.zst
 
TIME_END=$(date +%s) # время в Unixtime
TIME_ELAPSED=$(elapsed $TIME_START $TIME_END)
 
echosucc "pg_backup: created, duration: $TIME_ELAPSED (day:hh:mm:ss)"
 
# -----------------------------------------------------------------------------------------------------------------------
# удаляем архивные резервные копии старше N дней (папки и файлы рекурсивно)
echo "pg_backup: deleting backup files older than ${BACKUP_AGE_DAYS} days"
find ${BACKUP_DIR} -mindepth 1 -mtime +${BACKUP_AGE_DAYS} -delete
echosucc "pg_backup: old backup files deleted"
 
# -----------------------------------------------------------------------------------------------------------------------
# удаляем архивные WAL файлы старше N дней (сортировка по дате модификации)
echo "pg_backup: detect oldest kept WAL file for ${BACKUP_AGE_DAYS} days"
WAL_OLD_FILE=$(find ${WAL_DIR} -maxdepth 1 -mtime +${BACKUP_AGE_DAYS} -type f ! -size 0 \
                               ! -name "*.history" ! -name "*.history.*" -printf "%T@ %f\n" \
               | sort -n | tail -1 | cut -d" " -f2)
if test -z "${WAL_OLD_FILE}"; then
  echowarn "pg_backup: old WAL file is not found"
else
  echo "pg_backup: WAL old file is ${WAL_OLD_FILE}"
  WAL_OLD_FILE_EXT=$(echo "${WAL_OLD_FILE}" | grep -oP '\.[^.]+$') # compressed files support (.gz, .zst, .lz4)
 
  BEFORE_WAL_DIR_SIZE=$(du -sh "${WAL_DIR}" | grep -oP '^\S+')
  ${PG_BIN_DIR}/pg_archivecleanup -x "${WAL_OLD_FILE_EXT}" "${WAL_DIR}" "${WAL_OLD_FILE}" 2> ${WAL_DIR}/pg_archivecleanup.stderr.log
 
  AFTER_WAL_DIR_SIZE=$(du -sh "${WAL_DIR}" | grep -oP '^\S+')
  echo "pg_backup: WAL dir size reducing: ${BEFORE_WAL_DIR_SIZE} (before cleanup) -> ${AFTER_WAL_DIR_SIZE} (after cleanup)"
  echosucc "pg_backup: old WAL files deleted"
fi
 
exit 0
