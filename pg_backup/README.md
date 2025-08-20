# Инсталляция сервиса резервного копирования PostgreSQL

## Как это работает?

На каждом сервере СУБД по расписанию (обычно 1 раз в сутки) запускается [systemd](https://en.wikipedia.org/wiki/Systemd) сервис для создания резервных копий СУБД.

Резервные копии создаются так:
* Если [Patroni](https://patroni.readthedocs.io/en/latest/) или [jq](https://jqlang.org/) не инсталлирован, то только с сервера СУБД мастер.
* Иначе только с одного сервера СУБД в каждом ЦОДе. Приоритет выбора сервера: синхронная реплика, мастер, асинхронная реплика (с отставанием не более 1000 МБ).

> [!NOTE]
> Резервная копия сжимается в формат [`zstd`](https://github.com/facebook/zstd) (16–25% от исходного размера файлов СУБД). Это позволяет экономить место на сетевом диске и уменьшить нагрузку на ввод-вывод.

> [!CAUTION]
> Внимание!
> 1. Наличие WAL файлов в резервной копии зависит от настройки [`archive_mode`](https://postgrespro.ru/docs/postgresql/17/runtime-config-wal#GUC-ARCHIVE-MODE) и текущей роли сервера (мастер, реплика).
> 2. Для возможности восстановления СУБД из резервной копии, созданной без WAL файлов, должно быть настроено [непрерывное архивирование WAL файлов](https://postgrespro.ru/docs/postgresql/16/continuous-archiving) 
через [`archive_command`](https://postgrespro.ru/docs/postgresql/16/runtime-config-wal#GUC-ARCHIVE-COMMAND) 
или [`pg_receivewal`](https://postgrespro.ru/docs/postgresql/16/app-pgreceivewal).
> 3. Следует учесть [ограничения создания резервной копии с реплики](https://postgrespro.ru/docs/postgresql/16/app-pgbasebackup)!

## Настройка создания резервных копий СУБД

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

**Шаг 2. Выполнить на каждом сервере СУБД Linux (Bash)**
```bash
sudo -i
 
AUTH_USER=$(who -m | cut -f1 -d' ') && \
HOME_DIR=$(eval echo ~$AUTH_USER) && \
cd ~postgres
 
# создаём файлы (1)
nano -c .pgpass # в файле нужно сохранить пароль для пользователя bkp_replicator
(cp --update $HOME_DIR/pg_install/pg_backup.sh   . || nano -c pg_backup.sh) && \
(cp --update $HOME_DIR/pg_install/pg_backup.conf . || nano -c pg_backup.conf) && \
(cp --update $HOME_DIR/pg_install/archive_command.sh . || nano -c archive_command.sh) && \
(cp --update $HOME_DIR/pg_install/restore_command.sh . || nano -c restore_command.sh)
# выставляем нужные права и владельца
chmod 600 .pgpass pg_backup.conf && \
chmod 700 {pg_backup,{archive,restore}_command}.sh && \
chown postgres:postgres .pgpass {pg_backup,{archive,restore}_command}.sh pg_backup.conf
 
# создаём файлы (2)
(cp --update $HOME_DIR/pg_install/pg_backup.timer   /etc/systemd/system || nano -c /etc/systemd/system/pg_backup.timer) && \
(cp --update $HOME_DIR/pg_install/pg_backup.service /etc/systemd/system || nano -c /etc/systemd/system/pg_backup.service) && \
(cp --update $HOME_DIR/pg_install/pg_backup_validate.timer   /etc/systemd/system || nano -c /etc/systemd/system/pg_backup_validate.timer) && \
(cp --update $HOME_DIR/pg_install/pg_backup_validate.service /etc/systemd/system || nano -c /etc/systemd/system/pg_backup_validate.service) && \
systemctl daemon-reload # активируем
 
# добавляем в автозагрузку
systemctl enable pg_backup.timer && \
systemctl enable pg_backup.service && \
systemctl enable pg_backup_validate.timer && \
systemctl enable pg_backup_validate.service
 
# проверяем работоспособность (отладка)
sudo -i -u postgres -- ./pg_backup.sh ExecCondition  # будем ли создавать или проверять резервную копию с текущего сервера СУБД (см. код возврата)?
sudo -i -u postgres -- ./pg_backup.sh                # создаст резервную копию текущего сервера СУБД (и выведет сообщения на экран)
sudo -i -u postgres -- ./pg_backup.sh validate       # проверит восстанавливаемость резервной копии СУБД (и выведет сообщения на экран)
 
# запускаем; сделает резервную копию СУБД, если условие ExecCondition выполнится (НЕ выведет сообщения на экран)
systemctl start pg_backup.timer && \
systemctl start pg_backup.service && \
systemctl start pg_backup_validate.timer && \
systemctl start pg_backup_validate.service
 
# проверяем статус (1)
systemctl status pg_backup.timer && \
systemctl status pg_backup.service
 
# проверяем статус (2)
systemctl status pg_backup_validate.timer && \
systemctl status pg_backup_validate.service
 
# получаем список активных таймеров, д.б. указана дата-время следующего запуска!
systemctl list-timers | grep -P 'NEXT|pg_backup'
```

Файлы
* [`/etc/systemd/system/pg_backup.timer`](pg_backup.timer)
* [`/etc/systemd/system/pg_backup.service`](pg_backup.service)
* [`/etc/systemd/system/pg_backup_validate.timer`](pg_backup_validate.timer)
* [`/etc/systemd/system/pg_backup_validate.service`](pg_backup_validate.service)
* [`/var/lib/pgsql/pg_backup.sh`](pg_backup.sh)
* [`/var/lib/pgsql/pg_backup.conf`](pg_backup.conf)
* [`/var/lib/pgsql/archive_command.sh`](archive_command.sh)
* [`/var/lib/pgsql/restore_command.sh`](restore_command.sh)

## Ссылки по теме
* [PostgreSQL: копирование WAL файлов в архив (archive_command)](archive_command.md)
* [PostgreSQL: восстановление WAL файлов из архива (restore_command)](restore_command.md)
