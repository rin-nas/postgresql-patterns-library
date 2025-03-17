# Инсталляция сервиса архивирования log файлов PostgreSQL

## Описание

Systemd сервис, который запускается 1 раз в сутки.
1. удаляет файлы старше N дней
2. удаляет файлы нулевого размера старше K дней
3. архивирует несжатые файлы старше М дней в формат `zstd`, если размер файла > S килобайт

## Предусловия
```ini
log_destination = 'csvlog' #опционально
log_directory = '/var/log/postgresql/16' #папка /var/log должна быть в отдельном разделе ФС
log_filename = 'postgresql-%Y-%m-%d.log'
```

## Инсталляция и настройка

```bash
# создаём файлы
sudo nano /etc/systemd/system/pg_archive_log.timer && \
sudo nano /etc/systemd/system/pg_archive_log.service
 
# активируем и добавляем в автозагрузку
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
1. [`/etc/systemd/system/pg_archive_log.timer`](pg_archive_log.timer)
2. [`/etc/systemd/system/pg_archive_log.service`](pg_archive_log.service)
