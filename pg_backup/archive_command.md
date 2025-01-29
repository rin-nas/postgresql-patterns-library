# PostgreSQL файл archive_command.sh

## Введение

[Документация](https://postgrespro.ru/docs/postgresql/16/runtime-config-wal#RUNTIME-CONFIG-WAL-ARCHIVING)

ℹ При архивировании WAL файлы сжимаются (52–62% от исходного размера, даже если включен параметр wal_compression). Это позволяет экономить место на сетевом диске и уменьшить нагрузку на ввод-вывод.

⚠ Удаление неактуальных WAL файлов сделано в сервисе резервного копирования, см. "[Инсталляция сервиса резервного копирования PostgreSQL](README.md)"

## Инсталляция и настройка

**Инсталляция**
```bash
# создайте файл archive_command.sh
sudo mkdir -p /mnt/backup_db/ && sudo chown postgres:postgres /mnt/backup_db/ \
  && sudo su - postgres -c "mkdir -p /mnt/backup_db/archive_wal/cluster/ && chmod 700 /mnt/backup_db/archive_wal/{,cluster/}" \
  && sudo su - postgres -c "nano ~/archive_command.sh && chmod 700 ~/archive_command.sh && bash -n ~/archive_command.sh" \
  && sudo su - postgres -c "nano \$PGDATA/postgresql.conf"
 
# pg_hba.conf and postgresql.conf syntax check
test -z "$(psql --user=postgres --quiet --no-psqlrc --pset=null=¤ --tuples-only --no-align \
                --command='select * from pg_hba_file_rules where error is not null; select * from pg_file_settings where error is not null')"
 
sudo systemctl restart postgresql-16
sudo systemctl status postgresql-16
```

**Использование в postgresql.conf**
```ini
archive_mode = 'on' # для изменения этого параметра нужна перезагрузка СУБД
archive_command = '/var/lib/pgsql/archive_command.sh "%f" "%p"'
archive_timeout = 600
```

Файл [`/var/lib/pgsql/archive_command.sh`](archive_command.sh)
