# Инсталляция сервиса резервного копирования PostgreSQL

## Как это работает?

На каждом сервере СУБД по расписанию (обычно 1 раз в сутки) запускается сервис для создания резервных копий СУБД.

Резервные копии создаются только с мастер СУБД, а реплики игнорируются.

Если рез. копии создавать с одной из реплик, то есть риск значительного отставания (часы и дни). Это можно упустить (человеческий фактор) или не сразу возможно ликвидировать отставание и тогда будет создана неактуальная резервная копия!

> [!NOTE]
> Резервная копия сжимается в формат `zstd` (16–25% от исходного размера файлов СУБД). Это позволяет экономить место на сетевом диске и уменьшить нагрузку на ввод-вывод.

> [!CAUTION]
> Внимание!
> WAL файлы в резервную копию не копируются. 
> Для возможности восстановления СУБД из резервной копии должно быть настроено [непрерывное архивирование WAL файлов](https://postgrespro.ru/docs/postgresql/16/continuous-archiving) 
через [archive_command](https://postgrespro.ru/docs/postgresql/16/runtime-config-wal#GUC-ARCHIVE-COMMAND) 
или [pg_receivewal](https://postgrespro.ru/docs/postgresql/16/app-pgreceivewal).

## Настройка создания резервных копий СУБД

**Инсталляция сервиса**
```bash
# создаём файлы
sudo su - postgres -c "nano ~/.pgpass && chmod 600 ~/.pgpass" # в файле нужно сохранить пароль для пользователя bkp_replicator
sudo su - postgres -c "nano ~/pg_backup.sh && chmod 700 ~/pg_backup.sh && bash -n ~/pg_backup.sh"
sudo su - postgres -c "nano ~/pg_backup.conf && chmod 600 ~/pg_backup.conf && bash -n ~/pg_backup.conf"

sudo nano /etc/systemd/system/pg_backup.service && \
sudo nano /etc/systemd/system/pg_backup.timer

# активируем и добавляем в автозагрузку
sudo systemctl daemon-reload && \
sudo systemctl enable pg_backup.timer && \
sudo systemctl enable pg_backup

# проверяем работоспособность (отладка)
# time sudo su - postgres -c "~/pg_backup.sh"  # сделает резервную копию СУБД, выведет сообщения на экран

# запускаем
sudo systemctl start pg_backup.timer && \
sudo systemctl start pg_backup # сделает резервную копию СУБД только на мастере, НЕ выведет сообщения на экран

# проверяем статус
sudo systemctl status pg_backup.timer && \
sudo systemctl status pg_backup
 
# получаем список активных таймеров, для pg_backup.timer д.б. указана дата-время следующего запуска!
systemctl list-timers
```

Файлы
* [`/etc/systemd/system/pg_backup.service`](pg_backup.service)
* [`/etc/systemd/system/pg_backup.timer`](pg_backup.timer)
* [`/var/lib/pgsql/pg_backup.sh`](pg_backup.sh)
* [`/var/lib/pgsql/pg_backup.conf`](pg_backup.conf)

## Ссылки по теме
* [PostgreSQL: архивирование WAL файлов (archive_command)](archive_command.md)
* [PostgreSQL: восстановление WAL файлов (restore_command)](restore_command.md)
