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

### Автономная СУБД

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
[postgres@rmukhtarov-redos1 ~]$ psql demo
Started at:       2026-06-03 16:57:18+03 (1 day 21:45:52 ago)
Config loaded at: 2026-06-05 00:01:06+03 (14:42:04 ago)
Data directory:   /var/lib/pgpro/ent-17/data
Server role:      primary
WAL send (0):     
Archive mode:     off
Current database: demo (size: 8700 kB)
Installed extens: pgpro_axe 1.1.0.1, pgpro_metastore 1.1, plpgsql 1.0.1
Short SQL:        :W - who am i, :A - stats activity groups

psql (18.3, server 17.9)
Type "help" for help.


2026-06-05 14:43:10+03:00  Postgres Pro (enterprise) 17.9.2  postgres@[local]:5432/demo
=# \d+
                                    List of relations
 Schema │   Name   │ Type  │  Owner   │ Persistence │ Access method │ Size  │ Description 
────────┼──────────┼───────┼──────────┼─────────────┼───────────────┼───────┼─────────────
 public │ my_table │ table │ postgres │ permanent   │ heap          │ 16 kB │ ¤
(1 row)


2026-06-05 14:48:59+03:00  Postgres Pro (enterprise) 17.9.2  postgres@[local]:5432/demo
=# 
```

### Кластерная СУБД

#### С применением `.psqlrc`, мастер

```
postgres@sdm18-1:~$ psql
Started at:       2026-05-06 10:36:04+00 (30 days 01:10:49 ago)
Config loaded at: 2026-05-06 10:36:17+00 (30 days 01:10:36 ago)
Data directory:   /pgdata/keeper-sdm18-test-shard-1-1/postgres
Server role:      primary
WAL send (1):     biha_node_2  biha_replication_user@192.168.22.141:57560  physical persistent  quorum streaming  (lag: 1ms, 128 bytes)
Archive mode:     on (timeout: 1800)
Archive command:  /usr/bin/pg_probackup3 archive-push -B /backups/sdm  --instance shard-1 --wal-file-path=%p --wal-file-name=%f --log-level-console=debug -j 1 --compress-algorithm none --compress-level 1
Restore command:  
Current database: postgres (size: 125 MB)
Installed extens: pg_stat_statements 1.12, pgstattuple 1.5, plpgsql 1.0.1, shardman 0.2.106
Short SQL:        :W - who am i, :A - stats activity groups

psql (18.3)
Type "help" for help.


2026-06-05 14:46:52+03:00  Postgres Pro (shardman) 18.3.3  postgres@[local]:5432/postgres
=# 
```

#### С применением `.psqlrc`, реплика

```
postgres@sdm18-4:~$ psql
Started at:       2026-05-06 10:36:16+00 (30 days 01:10:07 ago)
Config loaded at: 2026-05-06 10:36:23+00 (30 days 01:10:00 ago)
Data directory:   /pgdata/keeper-sdm18-test-shard-1-2/postgres
Server role:      replica
WAL receive (1):  biha_node_2  biha_replication_user@sdm18-1:5432  streaming  not paused  (lag: 1s 158ms, 296 bytes)
WAL send (0):     
Archive mode:     on (timeout: 1800)
Archive command:  /usr/bin/pg_probackup3 archive-push -B /backups/sdm  --instance shard-1 --wal-file-path=%p --wal-file-name=%f --log-level-console=debug -j 1 --compress-algorithm none --compress-level 1
Restore command:  
Current database: postgres (size: 125 MB)
Installed extens: pg_stat_statements 1.12, pgstattuple 1.5, plpgsql 1.0.1, shardman 0.2.106
Short SQL:        :W - who am i, :A - stats activity groups

psql (18.3)
Type "help" for help.


2026-06-05 14:46:23+03:00  Postgres Pro (shardman) 18.3.3  postgres@[local]:5432/postgres
=# 
```

## Ссылки по теме

* [Удобное цветное приглашение командной строки в `bash`](../bashrc)
* https://wiki.postgresql.org/wiki/Psqlrc
* [Как использовать `pspg`, видео на русском языке](https://pgconf.ru/talk/1589147)
