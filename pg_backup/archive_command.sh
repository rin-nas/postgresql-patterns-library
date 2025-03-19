#!/bin/bash

# заглушка, т.к. для archive_mode = 'on' требуется перезагрузка СУБД
# exit 0

# проверяем, скрипт должен запускаться с двумя параметрами
test "$#" -ne 2 && echo "Error: 2 number of parameters expected, $# given" >&2 && exit 2

FILE_SRC="$2"
FILE_DST="/mnt/backup_db/archive_wal/cluster/$1.zst"

test ! -f "$FILE_SRC" && echo "Error: file '$FILE_SRC' does not exist!" >&2 && exit 1
test   -f "$FILE_DST" && exit

# кол-во потоков сжатия
ZSTD_THREADS=$(echo "$(nproc) / 4 + 1" | bc)

# кол-во файлов в очереди на архивирование
ARCHIVE_STATUS_DIR=$(dirname $FILE_SRC)/archive_status
WAL_FILES_QUEUE=$(find "$ARCHIVE_STATUS_DIR" -maxdepth 1 -type f -name "*.ready" -printf "." | wc --bytes)

# чем больше файлов в очереди, тем меньше степень сжатия (но больше скорость сжатия и размер сжатого файла)
STEP=3
# не ставьте большой уровень компрессии, это приводит к большому потреблению CPU, а экономия на размере файла несущественная
ZSTD_LEVEL=$(echo "(9 * ${STEP} - ${WAL_FILES_QUEUE}) / ${STEP}" | bc)
test "$ZSTD_LEVEL" -lt 1 && ZSTD_LEVEL=1

# архивируем файл (без -B1M используются не все ядра из-за небольшого размера файла)
ionice -c2 -n7 nice -n19 zstd -q -f -${ZSTD_LEVEL} -T${ZSTD_THREADS} -B1M "$FILE_SRC" -o "$FILE_DST"
