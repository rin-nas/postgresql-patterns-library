# Удобное цветное приглашение командной строки в `psql`

## Пример снимка экрана основного PostgreSQL

![psqlrc primary](psqlrc.primary.png)

## Пример снимка экрана резервного PostgreSQL

![psqlrc standby](psqlrc.standby.png)

## Что отображается

1. дата и время с часовой зоной
1. версия мажорная и минорная
1. роль сервера: основной мастер `primary` или резервный реплика `standby`
   1. для `primary` внутри круглых скобок количество реплик в статусе `streaming`
   1. для `standby` внутри круглых скобок название или IP primary сервера
1. пользователь
1. хост
1. порт
1. база данных

## Поддержка внешнего ПО

Используется пейджер [`pspg`](https://github.com/okbob/pspg), если он установлен. Иначе используется [`less`](https://en.wikipedia.org/wiki/Less_(Unix)).

## Как установить

* Документация: https://postgrespro.ru/docs/postgresql/16/app-psql#APP-PSQL-FILES-PSQLRC
* Файл с конфигурацией: [`psqlrc`](psqlrc)

## Ссылки по теме

* [Удобное цветное приглашение командной строки в `bash`](../bashrc)
