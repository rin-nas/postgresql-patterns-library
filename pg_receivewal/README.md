# Инсталляция сервиса архивирования WAL файлов PostgreSQL

Для архивирования WAL файлов **в реальном времени** применяется [pg_receivewal](https://postgrespro.ru/docs/postgresql/14/app-pgreceivewal), а не [archive_command](https://postgrespro.ru/docs/postgresql/14/runtime-config-wal#GUC-ARCHIVE-COMMAND).
Таки образом гарантируется, что ни одна транзакция не будет потеряна.

Удаление неактуальных WAL файлов сделано в сервисе резервного копирования!

**Инсталляция сервиса**

```bash
# создаём файлы
sudo su - postgres -c "nano ~/.pgpass && chmod 600 ~/.pgpass" # в файле нужно сохранить пароль для пользователя bkp_replicator
sudo nano /etc/systemd/system/pg_receivewal@.service
 
# PostgreSQL v12
sudo systemctl daemon-reload \
  && sudo systemctl enable pg_receivewal@12 \
  && sudo systemctl restart pg_receivewal@12
 
# PostgreSQL v14
sudo systemctl daemon-reload \
  && sudo systemctl enable pg_receivewal@14 \
  && sudo systemctl restart pg_receivewal@14
 
# PostgreSQL v16
sudo systemctl daemon-reload \
  && sudo systemctl enable pg_receivewal@16 \
  && sudo systemctl restart pg_receivewal@16
 
sudo systemctl status pg_receivewal@14
```

**Интеграция с Patroni**

```bash
# разрешаем перезапускать сервис под пользователем postgres без пароля
sudo nano /etc/sudoers.d/permit_pgreceivewal
sudo su postgres -c "sudo /bin/systemctl restart pg_receivewal@14" # тестируем перезапуск
 
# редактируем конфигурацию Patroni
patrionictl -c /etc/patroni/patrini.yml edit-config
# добавляем в секцию postgresql:
postgresql:
  callbacks:
    on_role_change: /bin/bash -c 'sudo /bin/systemctl restart pg_receivewal@14'
    on_restart:     /bin/bash -c 'sudo /bin/systemctl restart pg_receivewal@14'
    on_start:       /bin/bash -c 'sudo /bin/systemctl start pg_receivewal@14'
    on_stop:        /bin/bash -c 'sudo /bin/systemctl stop pg_receivewal@14'
```

Файлы 
* [`/etc/systemd/system/pg_receivewal@.service`](pg_receivewal@.service)
* [`/etc/sudoers.d/permit_pgreceivewal`](permit_pgreceivewal)

**Systemd special symbols**
* does not expand glob patterns like `*` (run command inside a shell)
* interprets several `%` prefixes as specifiers (escape `%` with `%%`)
* parses `\` before some characters (escape `\` with `\\`)

## Ссылки по теме

1. https://postgrespro.ru/docs/postgresql/14/app-pgreceivewal
1. https://www.cybertec-postgresql.com/en/never-lose-a-postgresql-transaction-with-pg_receivewal/
1. https://postgrespro.ru/docs/postgresql/14/continuous-archiving#BACKUP-PITR-RECOVERY
1. SystemD
   1. https://www.freedesktop.org/software/systemd/man/latest/systemd.service.html
   1. https://www.freedesktop.org/software/systemd/man/latest/systemd.unit.html
   1. https://www.youtube.com/watch?v=4s3mi-16vgI
