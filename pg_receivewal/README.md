# Инсталляция сервиса архивирования WAL файлов PostgreSQL

Для архивирования WAL файлов в реальном времени применяется [pg_receivewal](https://postgrespro.ru/docs/postgresql/14/app-pgreceivewal), а не [archive_command](https://postgrespro.ru/docs/postgresql/14/runtime-config-wal#GUC-ARCHIVE-COMMAND).
Таки образом гарантируется, что ни одна транзакция не будет потеряна.

**Инсталляция сервиса**

```bash
# создаём файлы
sudo su - postgres -c "nano ~/.pgpass && chmod 0600 ~/.pgpass" # в файле нужно сохранить пароль для пользователя bkp_replicator
sudo nano /etc/systemd/system/pg_receivewal@.service # содержимое файла см. ниже
 
sudo systemctl daemon-reload
sudo systemctl enable pg_receivewal@14
sudo systemctl start  pg_receivewal@14
sudo systemctl status pg_receivewal@14
```

Файл [`/etc/systemd/system/pg_receivewal@.service`](pg_receivewal@.service)
