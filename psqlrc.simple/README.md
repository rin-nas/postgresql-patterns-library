# Удобное приглашение командной строки в `psql` (Convenient command line prompt in `psql`)

## Введение

Функциональность предназначена для администраторов СУБД PostgreSQL и его форков.

## Что отображается при запуске `psql`

1. дата и время, когда был запущен сервер (и сколько времени прошло)
1. дата и время, когда в последний раз сервер загружал файлы конфигурации (и сколько времени прошло)
1. директория с данными
1. роль сервера: основной (мастер) `primary` или резервный (реплика) `replica`
1. названия серверов с портами, откуда принимаются WAL файлы и куда передаются

## Что отображается в командной строке `psql`

1. дата и время с часовой зоной
1. название и версия сервера
1. пользователь@хост:порт/база_данных

## Поддержка внешнего ПО

Используется пейджер [`pspg`](https://github.com/okbob/pspg), если он установлен. Иначе используется [`less`](https://en.wikipedia.org/wiki/Less_(Unix)).

## Как установить

* Требования к версиям: `psql 12+`, `PostgreSQL 12+`
* Документация: https://postgrespro.ru/docs/postgresql/current/app-psql#APP-PSQL-FILES-PSQLRC
* Файл конфигурацией: [`~/.psqlrc`](.psqlrc)


```bash
nano ~/.psqlrc
```

## Примеры

### Aвтономная СУБД

#### Без применения `.psqlrc` 

```
postgres@rmukhtarov-redos1 root]$ psql demo --no-psqlrc
psql (18.3, server 17.9)
Type "help" for help.

demo=# \d+
                                    List of relations
 Schema |   Name   | Type  |  Owner   | Persistence | Access method | Size  | Description 
--------+----------+-------+----------+-------------+---------------+-------+-------------
 public | my_table | table | postgres | permanent   | heap          | 16 kB | 
(1 row)

demo=#  
```

#### С применением `.psqlrc`
```
postgres@rmukhtarov-redos1 root]$ psql demo
Started at:       2026-06-03 16:57:18+03 (1 day 07:08:25 ago)
Config loaded at: 2026-06-05 00:01:06+03 (00:04:37 ago)
Data directory:   /var/lib/pgpro/ent-17/data
Server role:      primary
WAL send (0):     
psql (18.3, server 17.9)
Type "help" for help.


2026-06-05 00:05:43+03:00  Postgres Pro (enterprise) 17.9.2  postgres@[local]:5432/demo
=# \d+
                                    List of relations
 Schema │   Name   │ Type  │  Owner   │ Persistence │ Access method │ Size  │ Description 
────────┼──────────┼───────┼──────────┼─────────────┼───────────────┼───────┼─────────────
 public │ my_table │ table │ postgres │ permanent   │ heap          │ 16 kB │ ¤
(1 row)


2026-06-05 00:05:53+03:00  Postgres Pro (enterprise) 17.9.2  postgres@[local]:5432/demo
=# 
```

### Кластерная СУБД

#### С применением `.psqlrc`, мастер

```
postgres@sdm18-1:~$ psql
Started at:       2026-05-06 10:36:04+00 (29 days 10:32:52 ago)
Config loaded at: 2026-05-06 10:36:17+00 (29 days 10:32:39 ago)
Data directory:   /pgdata/keeper-sdm18-test-shard-1-1/postgres
Server role:      primary
WAL send (1):     biha_node_2  biha_replication_user@192.168.22.141:57560  physical persistent  quorum streaming  0ms  0 bytes
psql (18.3)
Type "help" for help.


2026-06-05 00:08:55+03:00  Postgres Pro (shardman) 18.3.3  postgres@[local]:5432/postgres
=# 
```

#### С применением `.psqlrc`, реплика

```
postgres@sdm18-4:~$ psql
Started at:       2026-05-06 10:36:16+00 (29 days 10:33:23 ago)
Config loaded at: 2026-05-06 10:36:23+00 (29 days 10:33:16 ago)
Data directory:   /pgdata/keeper-sdm18-test-shard-1-2/postgres
Server role:      replica
WAL receive (1):  biha_node_2  biha_replication_user@sdm18-1:5432  streaming  0ms  0 bytes
WAL send (0):     
psql (18.3)
Type "help" for help.


2026-06-05 00:09:38+03:00  Postgres Pro (shardman) 18.3.3  postgres@[local]:5432/postgres
=# 
```

## Ссылки по теме

* [Удобное цветное приглашение командной строки в `bash`](../bashrc)
* https://wiki.postgresql.org/wiki/Psqlrc
* [Как использовать `pspg`, видео на русском языке](https://pgconf.ru/talk/1589147)
