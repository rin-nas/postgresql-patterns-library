#!/bin/bash

find /mnt/log/postgresql/12/pg_log -type f -name "postgresql*" -mtime +30 -exec rm -rf {} \;

FILES_FOR_COMPRESSION=`find /mnt/log/postgresql/12/pg_log -type f -size +0k -mtime +1 \( -name "postgresql*.log" -o -name "postgresql*.csv" \)`

for file in $FILES_FOR_COMPRESSION
do
    ionice -c2 -n7 nice -n19 pzstd -5 --quiet --rm $file
    chown postgres:postgres $file.zst
done
