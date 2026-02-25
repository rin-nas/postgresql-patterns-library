# Восстановление PostgreSQL из резервной копии (инструкция)

## Восстановление СУБД из физической резервной копии

Официальная документация:
* [Восстановление ведущего сервера (мастера) СУБД](https://postgrespro.ru/docs/postgresql/18/continuous-archiving#BACKUP-PITR-RECOVERY)
* [Восстановление резервного сервера (реплики) СУБД](https://postgrespro.ru/docs/postgresql/18/warm-standby#STANDBY-SERVER-SETUP)

### Общие начальные команды для восстановления мастера или реплики

Инсталлируйте PostgreSQL, при необходимости.

Выполните команды:
```
# проверьте, что СУБД остановлена
sudo systemctl stop postgresql-16
sudo systemctl status postgresql-16

# войдите под пользователем postgres
sudo -i -u postgres

# расшифруйте и распакуйте необходимый архив с резервной копией СУБД (поддерживается zst, lz4, gz)
# на экране будет отображаться прогресс работы в процентах, скорость работы в мегабайтах/секунду, текущая и оставшаяся длительность работы

# архив в виде одного файла (без WAL файлов)
./pg_backup.sh restore /mnt/mnt/backup_db/active_full/cluster/2025-08-29.143318.sc-inf-db-te11.pg_backup.tar.zst.gpg $PGDATA

# или архив в виде директории (с WAL файлами)
./pg_backup.sh restore /mnt/mnt/backup_db/active_full/cluster/2025-08-29.143540.sc-inf-db-te11.pg_backup $PGDATA

# проверьте целостность СУБД (опционально)
PG_MAJOR_VERSION=$(echo $PGDATA | grep -oP '/\K\d+(?=/)')
time /usr/pgsql-${PG_MAJOR_VERSION}/bin/pg_verifybackup --no-parse-wal --exit-on-error $PGDATA

# создайте файл restore_command.sh
nano ~/restore_command.sh && chmod 700 ~/restore_command.sh
```

### Команды для восстановления мастера

```
sudo -i -u postgres
cd $PGDATA && touch recovery.signal && nano postgresql.conf
```

Файл $PGDATA/postgresql.conf
```
restore_command = '/var/lib/pgsql/restore_command.sh "%f" "%p"'
# recovery.conf
recovery_target_timeline = 'latest'
```

### Команды для восстановления реплики

```
sudo -i -u postgres
cd $PGDATA && touch standby.signal && nano postgresql.conf
nano /var/lib/pgsql/pgpass && chmod 600 /var/lib/pgsql/pgpass # ранее был /tmp/pgpass
```

Файл $PGDATA/postgresql.conf
```
restore_command = '/var/lib/pgsql/restore_command.sh "%f" "%p"'
# recovery.conf
primary_conninfo = 'user=ptr_replicator passfile=/var/lib/pgsql/pgpass host={IP_db_primary} port=5432 sslmode=prefer application_name=$(hostname) gssencmode=prefer channel_binding=prefer' #EDIT_ME!
primary_slot_name = '$(hostname | tr "-" "_")' #EDIT_ME!
recovery_target_timeline = 'latest'
```

Файл /var/lib/pgsql/pgpass (ранее был /tmp/pgpass)
```
# https://github.com/rin-nas/postgresql-patterns-library/blob/
master/.pgpass
# Сервер:Порт:База_данных:Имя_пользователя:Пароль
*:*:*:ptr_replicator:MyPassword
```

На СУБД мастере создайте слот репликации с именем из настройки primary_slot_name
```
psql --username=postgres --quiet --pset=null=¤ --variable=ON_ERROR_STOP=1 \
     --command="SELECT * FROM pg_create_physical_replication_slot('{primary_slot_name}'); SELECT * FROM pg_replication_slots;"
```

### Общие финальные команды для восстановления мастера или реплики

```
sudo systemctl start postgresql-16
sudo systemctl status postgresql-16
sudo su - postgres -c "tail -n1000 \$PGDATA/log/postgresql-$(date +%Y-%m-%d).csv | pspg --csv" # в журнале ошибок проверяем их отсутствие
psql -U postgres -q -c "\l+" # получаем список СУБД с их размерами
```

## Воссоздание (а не восстановление) СУБД из логической резервной копии

```bash
#!/bin/bash
# при необходимости, сохраните пароль в файле ~/.pgpass, но не в этом файле!
LOG_DIR='/mnt/backup_db/active_full/cluster/' # EDIT ME!
ARCHIVE='/mnt/backup_db/active_full/cluster/2024-04-16.11-18-26.sp-ek-db-pr03.sql.zst' # EDIT ME!
# ВНИМАНИЕ! в psql флаг --single-transaction использовать нельзя из-за возможных ошибок при выполнении
# посмотреть прогресс выполнения процесса pv: sudo pv -d PID
"time" --verbose --output="${LOG_DIR}/psql.zstd.time.log" \
pv "${ARCHIVE}" \
   | zstd -dcq 2> "${LOG_DIR}/zstd.stderr.log" \
   | psql --echo-errors \
          --log-file="${LOG_DIR}/psql.log" \
                  2> "${LOG_DIR}/psql.stderr.log"
```

## Ссылки по теме
1. https://github.com/rin-nas/postgresql-patterns-library/blob/master/.pgpass
2. https://github.com/rin-nas/postgresql-patterns-library/blob/master/experiments/pg_dump_restore.md
