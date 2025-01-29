# PostgreSQL файл restore_command.sh

## Введение

[Документация](https://postgrespro.ru/docs/postgresql/16/runtime-config-wal#RUNTIME-CONFIG-WAL-ARCHIVE-RECOVERY)

ℹ Поддерживается восстановление архивных [WAL файлов](https://postgrespro.ru/docs/postgresql/16/continuous-archiving): несжатых и сжатых в форматах `gzip`, `zstd`, `lz4`.

## Инсталляция и настройка

**Инсталляция**
```bash
# создайте файл restore_command.sh
sudo su - postgres -c "nano ~/restore_command.sh && chmod 700 ~/restore_command.sh && bash -n ~/restore_command.sh" \
  && sudo su - postgres -c "nano \$PGDATA/postresql.conf"

# pg_hba.conf and postgresql.conf syntax check
test -z "$(psql --user=postgres --quiet --no-psqlrc --pset=null=¤ --tuples-only --no-align \
                --command='select * from pg_hba_file_rules where error is not null; select * from pg_file_settings where error is not null')"

sudo systemctl reload postgresql-16
sudo systemctl status postgresql-16
```

**Использование в postgresql.conf**
```ini
restore_command = '/var/lib/pgsql/restore_command.sh "%f" "%p"'
```

Файл [`/var/lib/pgsql/restore_command.sh`](restore_command.sh)
