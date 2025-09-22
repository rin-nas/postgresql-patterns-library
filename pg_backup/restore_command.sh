#!/bin/bash
 
# проверяем, скрипт должен запускаться с двумя параметрами
test "$#" -ne 2 && echo "Error: 2 number of parameters expected, $# given" >&2 && exit 2
 
FILE_SRC="/mnt/backup_db/archive_wal/cluster/$1"
FILE_DST="$2"
 
test -f "$FILE_SRC"         && (cp "$FILE_SRC"         "$FILE_DST"         ; exit)
test -f "$FILE_SRC.partial" && (cp "$FILE_SRC.partial" "$FILE_DST.partial" ; exit)
 
test -f "$FILE_SRC.lz4"         && (lz4 -dkf "$FILE_SRC.lz4"         "$FILE_DST"         ; exit)
test -f "$FILE_SRC.partial.lz4" && (lz4 -dkf "$FILE_SRC.partial.lz4" "$FILE_DST.partial" ; exit)
 
test -f "$FILE_SRC.zst"         && (zstd -dkf "$FILE_SRC.zst"         -o "$FILE_DST"         ; exit)
test -f "$FILE_SRC.partial.zst" && (zstd -dkf "$FILE_SRC.partial.zst" -o "$FILE_DST.partial" ; exit)
 
# gzip DEPRECATED
test -f "$FILE_SRC.gz"         && (gzip -dkc "$FILE_SRC.gz"         > "$FILE_DST"         ; exit)
test -f "$FILE_SRC.partial.gz" && (gzip -dkc "$FILE_SRC.partial.gz" > "$FILE_DST.partial" ; exit)
 
# pg_receivewal support, https://www.postgresql.org/docs/current/app-pgreceivewal.html
test -f "$FILE_SRC.gz.partial"  && (gzip -dkc "$FILE_SRC.gz.partial"  >  "$FILE_DST.partial" ; exit)
test -f "$FILE_SRC.lz4.partial" && (lz4  -dkf "$FILE_SRC.lz4.partial"    "$FILE_DST.partial" ; exit)
test -f "$FILE_SRC.zst.partial" && (zstd -dkf "$FILE_SRC.zst.partial" -o "$FILE_DST.partial" ; exit)
