# Инсталляция сервиса архивирования log файлов PostgreSQL

## Инсталляция и настройка
```bash
# создаём файлы
sudo nano /etc/systemd/system/pg_archive_log.timer && \
sudo nano /etc/systemd/system/pg_archive_log.service
 
# активируем
sudo systemctl daemon-reload \
  && sudo systemctl enable pg_archive_log.timer \
  && sudo systemctl enable pg_archive_log
 
# запускаем
sudo systemctl start pg_archive_log.timer && \
sudo systemctl start pg_archive_log
 
# проверяем статус
sudo systemctl status pg_archive_log.timer && \
sudo systemctl status pg_archive_log
 
# получаем список активных таймеров, для pg_archive_log.timer д.б. указана дата-время следующего запуска!
systemctl list-timers
```

**Файлы**
