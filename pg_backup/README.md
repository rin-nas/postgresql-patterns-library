# Инсталляция сервиса резервного копирования PostgreSQL

## Функциональность
1. Создание полной резервной копии СУБД
1. Удаление старых резервных копий и WAL файлов из архива
1. Валидация корректности и восстанавливаемости резервной копии СУБД
1. Проверка необходимости запуска команд (п. 1-3) с текущего сервера кластера СУБД
1. Восстановление резервной копии СУБД

## Требования
* GNU/Linux
* PostgreSQL ≥ v14
* Bash ≥ 4.4

## Как это работает?

На каждом сервере СУБД по расписанию запускаются [systemd](https://en.wikipedia.org/wiki/Systemd) сервисы:
1. Создание резервной копии СУБД (обычно 1 раз в сутки)
1. Валидация резервной копий СУБД (обычно 1 раз в неделю)

Условие запуска сервисов:
* Если [Patroni](https://patroni.readthedocs.io/en/latest/) или [jq](https://jqlang.org/) не инсталлирован, то только с сервера СУБД мастер.
* Иначе только с одного сервера СУБД в каждом ЦОДе. Приоритет выбора сервера: синхронная реплика, мастер, асинхронная реплика (с отставанием не более 1000 МБ).

> [!NOTE]
> Резервная копия сжимается (10–30% от исходного размера файлов СУБД) и шифруется. Это позволяет экономить место на сетевом диске, уменьшить нагрузку на ввод-вывод, увеличить безопасность.

> [!CAUTION]
> Внимание!
> 1. Наличие WAL файлов в резервной копии зависит от текущего дня (по умолчанию каждый 5-й день), настройки [`archive_mode`](https://postgrespro.ru/docs/postgresql/17/runtime-config-wal#GUC-ARCHIVE-MODE) и текущей роли сервера (мастер, реплика).
> 1. Для возможности восстановления СУБД из резервной копии, созданной без WAL файлов, должно быть настроено [непрерывное архивирование WAL файлов](https://postgrespro.ru/docs/postgresql/16/continuous-archiving) 
через [`archive_command`](https://postgrespro.ru/docs/postgresql/16/runtime-config-wal#GUC-ARCHIVE-COMMAND) 
или [`pg_receivewal`](https://postgrespro.ru/docs/postgresql/16/app-pgreceivewal).
> 1. Следует учесть [ограничения создания резервной копии с реплики](https://postgrespro.ru/docs/postgresql/16/app-pgbasebackup)!

## Инсталляция

**Шаг 1. Выполнить на терминальном сервере Windows (PowerShell)**
```powershell
# создаём папку и переходим в неё
$path = "$home\pg_install"; mkdir -force $path; cd $path
 
# создаём файлы
# ВНИМАНИЕ! кодировка файлов должна быть UTF8 без BOM, переносы строк в формате Unix (LF)
C:\"Program Files"\Notepad++\notepad++.exe `
  pg_backup.sh pg_backup.conf `
  pg_backup.timer pg_backup.service `
  pg_backup_validate.timer pg_backup_validate.service `
  archive_command.sh restore_command.sh
 
# замените xx на код АС (или ФП?), yy на код среды (ps, nt, if, te), NN на порядковый номер
$db_hosts='sp-xx-db-yyNN', 'sp-xx-db-yyNN', 'sc-xx-db-yyNN', 'sc-xx-db-yyNN'
 
# копируем локальную папку с файлами на удалённые серверы СУБД в домашнюю папку (Windows -> Linux)
foreach ($db_host in $db_hosts) {
  Write-Host "`n$db_host" -ForegroundColor white -BackgroundColor blue
  pscp -r $path ${env:username}@${db_host}:
}
```

**Шаг 2. Выполнить на каждом сервере СУБД Linux (Bash) - создаём файлы**
```bash
sudo -i
 
AUTH_USER=$(who -m | cut -f1 -d' ') && \
HOME_DIR=$(eval echo ~$AUTH_USER) && \
cd ~postgres
 
# создаём файлы (1)
nano -c .pgpass # в файле нужно сохранить пароль для пользователя bkp_replicator
(cp --update --backup $HOME_DIR/pg_install/pg_backup.sh   . || nano -c pg_backup.sh) && \
(cp --update --backup $HOME_DIR/pg_install/pg_backup.conf . || nano -c pg_backup.conf) && \
(cp --update --backup $HOME_DIR/pg_install/archive_command.sh . || nano -c archive_command.sh) && \
(cp --update --backup $HOME_DIR/pg_install/restore_command.sh . || nano -c restore_command.sh)
# выставляем нужные права и владельца
chmod 600 .pgpass pg_backup.conf && \
chmod 700 {pg_backup,{archive,restore}_command}.sh && \
chown postgres:postgres .pgpass {pg_backup,{archive,restore}_command}.sh pg_backup.conf
 
# проверяем работоспособность (отладка), выводим сообщения на экран
sudo -i -u postgres -- ./pg_backup.sh ExecCondition  # будем ли создавать или проверять резервную копию с текущего сервера СУБД (см. код возврата)?
sudo -i -u postgres -- ./pg_backup.sh create         # создаст резервную копию текущего сервера СУБД
sudo -i -u postgres -- ./pg_backup.sh validate       # проверит корректность и восстанавливаемость резервной копии СУБД
sudo -i -u postgres -- ./pg_backup.sh restore SOURCE_BACKUP_FILE_OR_DIR TARGET_PG_DATA_DIR  # восстановит резервную копию СУБД
 
# создаём файлы (2)
(cp --update --backup $HOME_DIR/pg_install/pg_backup.timer   /etc/systemd/system || nano -c /etc/systemd/system/pg_backup.timer) && \
(cp --update --backup $HOME_DIR/pg_install/pg_backup.service /etc/systemd/system || nano -c /etc/systemd/system/pg_backup.service) && \
(cp --update --backup $HOME_DIR/pg_install/pg_backup_validate.timer   /etc/systemd/system || nano -c /etc/systemd/system/pg_backup_validate.timer) && \
(cp --update --backup $HOME_DIR/pg_install/pg_backup_validate.service /etc/systemd/system || nano -c /etc/systemd/system/pg_backup_validate.service) && \
systemctl daemon-reload # активируем
```

**Шаг 3. Выполнить на каждом сервере СУБД Linux (Bash) - запускаем pg_backup**
```bash
# добавляем в автозагрузку
systemctl enable pg_backup.timer && \
systemctl enable pg_backup.service
 
# запускаем; сделает резервную копию СУБД, если условие ExecCondition выполнится
systemctl start pg_backup.timer && \
systemctl start pg_backup.service
 
# проверяем статус
systemctl status pg_backup.timer && \
systemctl status pg_backup.service
 
# получаем список активных таймеров, д.б. указана дата-время следующего запуска!
systemctl list-timers | grep -P 'NEXT|pg_backup'
```

**Шаг 4. Выполнить на каждом сервере СУБД Linux (Bash) - запускаем pg_backup_validate**
```bash
# добавляем в автозагрузку
systemctl enable pg_backup_validate.timer && \
systemctl enable pg_backup_validate.service
 
# запускаем; проверит корректность и восстанавливаемость резервной копии СУБД, если условие ExecCondition выполнится
systemctl start pg_backup_validate.timer && \
systemctl start pg_backup_validate.service
 
# проверяем статус
systemctl status pg_backup_validate.timer && \
systemctl status pg_backup_validate.service
 
# получаем список активных таймеров, д.б. указана дата-время следующего запуска!
systemctl list-timers | grep -P 'NEXT|pg_backup'
```

Файлы
1. [`/etc/systemd/system/pg_backup.timer`](pg_backup.timer)
1. [`/etc/systemd/system/pg_backup.service`](pg_backup.service)
1. [`/etc/systemd/system/pg_backup_validate.timer`](pg_backup_validate.timer)
1. [`/etc/systemd/system/pg_backup_validate.service`](pg_backup_validate.service)
1. [`/var/lib/pgsql/pg_backup.sh`](pg_backup.sh)
1. [`/var/lib/pgsql/pg_backup_test.sh`](pg_backup_test.sh)
1. [`/var/lib/pgsql/pg_backup.conf`](pg_backup.conf)
1. [`/var/lib/pgsql/archive_command.sh`](archive_command.sh)
1. [`/var/lib/pgsql/restore_command.sh`](restore_command.sh)

## Ссылки по теме
* [PostgreSQL: копирование WAL файлов в архив (archive_command)](archive_command.md)
* [PostgreSQL: восстановление WAL файлов из архива (restore_command)](restore_command.md)
