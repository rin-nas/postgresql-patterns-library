# Инсталляция сервиса архивирования WAL файлов PostgreSQL

## Введение

Для непрерывного архивирования [WAL файлов](https://postgrespro.ru/docs/postgresql/16/continuous-archiving) **в реальном времени** применяется [pg_receivewal](https://postgrespro.ru/docs/postgresql/16/app-pgreceivewal), а не [archive_command](https://postgrespro.ru/docs/postgresql/16/runtime-config-wal#GUC-ARCHIVE-COMMAND).

Сервис работает только с СУБД мастером, использует отдельный слот репликации и выглядит как ещё одна постоянно отстающая асинхронная реплика.

ℹ При архивировании WAL файлы сжимаются (≈ 66% от исходного размера, даже если включен параметр [wal_compression](https://postgrespro.ru/docs/postgresql/16/runtime-config-wal#GUC-WAL-COMPRESSION)). Это позволяет экономить место на сетевом диске и уменьшить нагрузку на ввод-вывод.

⚠ Удаление неактуальных WAL файлов сделано в сервисе резервного копирования!

Преимущества сервиса:
1. Архивирование WAL файлов в реальном времени. Гарантируется, что ни одна транзакция не будет потеряна.

Недостатки сервиса:
1. Однопоточный режим работы
1. Устаревшее сжатие в gzip (по сравнению с zstd)

Выводы: сервис хорошо подходит для небольших нагрузок с медленной и долгой записью каждого WAL файла

## Инсталляция и настройка

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
 
 
sudo systemctl status pg_receivewal@12
sudo systemctl status pg_receivewal@14
sudo systemctl status pg_receivewal@16
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
    #on_restart:     /bin/bash -c 'sudo /bin/systemctl restart pg_receivewal@14' # закомментировано, т.к. это сделано в настройках pg_receivewal@.service через PartOf=
    #on_start:       /bin/bash -c 'sudo /bin/systemctl start pg_receivewal@14'   # закомментировано, т.к. это сделано в настройках pg_receivewal@.service через PartOf=
    #on_stop:        /bin/bash -c 'sudo /bin/systemctl stop pg_receivewal@14'    # закомментировано, т.к. это сделано в настройках pg_receivewal@.service через PartOf=
```

Файлы 
* [`/etc/systemd/system/pg_receivewal@.service`](pg_receivewal@.service)
* [`/etc/sudoers.d/permit_pgreceivewal`](permit_pgreceivewal)

**Systemd special symbols**
* does not expand glob patterns like `*` (run command inside a shell)
* interprets several `%` prefixes as specifiers (escape `%` with `%%`)
* parses `\` before some characters (escape `\` with `\\`)

## Что осталось доделать в сервисе?

1. Протестировать, что сервис перезагружается при перезагрузке Patroni / PostgreSQL.
1. Протестировать, что Patroni / PostgreSQL не перезагружается при перезагрузке серсиса.
1. Протестировать, что архивирование возобновляется при переезде мастера на другой узел.

## Ссылки по теме

1. https://www.cybertec-postgresql.com/en/never-lose-a-postgresql-transaction-with-pg_receivewal/
1. SystemD
   1. https://www.freedesktop.org/software/systemd/man/latest/systemd.service.html
   1. https://www.freedesktop.org/software/systemd/man/latest/systemd.unit.html
   1. https://www.youtube.com/watch?v=4s3mi-16vgI
