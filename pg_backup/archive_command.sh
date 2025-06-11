#!/bin/bash
 
# заглушка, т.к. при изменении значения параметра archive_mode требуется перезагрузка СУБД
# exit 0
 
function log() {
  # echo $(date --rfc-3339=ns) $(hostname -s) $(basename "$SRC_FILE") "$1" &>> "$WAL_DIR/archive_wal.log"
  return 0
}
 
WAL_DIR="/mnt/backup_db/archive_wal/cluster"
SRC_FILE="$(pwd)/$2"         # откуда будем читать WAL файл
DST_FILE="$WAL_DIR/$1.zst"   # куда будем сохранять WAL файл
LOCK_FILE="$WAL_DIR/$1.lock" # этот файл создаётся перед архиваций WAL файла и удаляется после
 
log "check"
 
# скрипт должен запускаться с двумя параметрами
test "$#" -ne 2 && echo "Error: 2 number of parameters expected, $# given" >&2 && exit 2
test ! -f "$SRC_FILE" && echo "Error: WAL file '$SRC_FILE' does not exist!" >&2 && exit 1
test   -f "$DST_FILE" && test ! -f "$LOCK_FILE" && log "exists" && exit 0
 
log "does not exist"
 
: <<'COMMENT'
  Для надёжности архивирование WAL файлов могут настроить на мастере и репликах через параметр archive_mode=always.
  Запрещаем от разных экземпляров СУБД конкурентную запись WAL файлов в общие сетевые папки.
  Например, в основном и резервном ЦОДе могут быть разные сетевые папки.
  Дополнительные файлы и проверки нужны для решения проблемы переполнения диска или недоступности сетевого соединения,
  когда WAL файл может не записаться совсем или записаться только частично.
COMMENT
 
SRV_FILE="$WAL_DIR/archive_server.$(hostname -s)" # сервер, на котором планируется архивирование WAL файла
touch -m "$SRV_FILE" || exit # создаём файл или обновляем дату модификации файла, если файл существует
 
# разрешаем архивацию WAL файла только при наличии жёстких связанных ссылок (единый inode) между файлами $SRV_FILE и $LOCK_FILE
# для отладки и просмотра кол-ва жёстких ссылок на файл используйте утилиту stat (не используйте ls, она кеширует информацию)
if ln -T "$SRV_FILE" "$LOCK_FILE" &> /dev/null; then
  # если удалось создать файл $LOCK_FILE, то только этот (основной) процесс будет архивировать WAL файл (первая попытка)
  log "locked now"
elif test "$SRV_FILE" -ef "$LOCK_FILE"; then
  # если файлы имеют одинаковый inode, то только этот (основной) процесс будет архивировать WAL файл (повторная попытка)
  log "locked already"
else
  # иначе архивировать WAL файл пытается конкурирующий процесс, ждём несколько секунд завершения работы основного процесса
  for i in {1..75}; do
    log "waiting i=$i"
    sleep 0.2
    test -f "$DST_FILE" && test ! -f "$LOCK_FILE" && log "appeared" && exit 0
  done
  # не дождались, значит основной процесс сломался, WAL файл мог сохраниться только частично
  # передаём управление другому конкурирующему процессу, который станет основным (при повторном вызове этого скрипта)
  rm -f "$DST_FILE" && rm -f "$LOCK_FILE" # очерёдность удаления файлов важна
  MESSAGE="waiting timeout, deleted, unlocked"
  log "$MESSAGE"
  echo "Error: WAL file '$DST_FILE' $MESSAGE" >&2
  exit 1
fi
 
# кол-во потоков сжатия
ZSTD_THREADS=$(echo "$(nproc) / 4 + 1" | bc)
 
# подсчитываем кол-во WAL файлов в очереди на архивирование
ARCHIVE_STATUS_DIR=$(dirname "$SRC_FILE")/archive_status
WAL_FILES_QUEUE=$(find "$ARCHIVE_STATUS_DIR" -maxdepth 1 -type f -name "*.ready" -printf "." | wc --bytes)
 
STEP=2
# чем больше WAL файлов в очереди, тем меньше степень сжатия (но больше скорость сжатия и размер сжатого файла)
# не ставьте большой уровень компрессии, это приводит к большому потреблению CPU, а экономия на размере файла несущественная
ZSTD_LEVEL=$(echo "(9 * ${STEP} - ${WAL_FILES_QUEUE}) / ${STEP}" | bc)
test "$ZSTD_LEVEL" -lt 1 && ZSTD_LEVEL=1
 
# архивируем WAL файл
# в zstd без флага -B1M используются не все ядра (из-за небольшого размера файла?)
COMMAND="zstd -q -f -${ZSTD_LEVEL} -T${ZSTD_THREADS} -B1M $SRC_FILE -o $DST_FILE"
test $ZSTD_LEVEL -gt 1 && COMMAND="ionice -c2 -n7 -- nice -n19 -- $COMMAND"
log "command: $COMMAND"
$COMMAND && rm -f "$LOCK_FILE" && log "saved, unlocked"