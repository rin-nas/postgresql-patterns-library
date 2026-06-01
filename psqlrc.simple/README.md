# Удобное приглашение командной строки в `psql` (Convenient command line prompt in `psql`)

## Введение

Функциональность предназначена для администраторов СУБД PostgreSQL и его форков.
Необходимо использовать учётную запись суперпользователя (`postgres`), иначе может работать не полностью (из-за нехватки прав доступа к объектам СУБД).

## Что отображается при запуске `psql`

1. дата и время, когда был запущен сервер (и сколько времени прошло)
1. дата и время, когда в последний раз сервер загружал файлы конфигурации (и сколько времени прошло)
1. роль сервера: основной (мастер) `primary` или резервный (реплика) `replica`

## Что отображается в командной строке `psql`

1. дата и время с часовой зоной
1. версия сервера: основная (мажорная) и дополнительная (минорная)
1. пользователь
1. хост
1. порт
1. база данных

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

### Без применения `.psqlrc`

```
[postgres@rmukhtarov-redos1 ~]$ psql demo --no-psqlrc
psql (18.3, server 17.9)
Type "help" for help.

demo=# \d+
                                                             List of relations
  Schema  |         Name          |   Type   |  Owner   | Persistence | Access method |    Size    |              Description               
----------+-----------------------+----------+----------+-------------+---------------+------------+----------------------------------------
 bookings | airplanes             | view     | postgres | permanent   |               | 0 bytes    | Airplanes
 bookings | airplanes_data        | table    | postgres | permanent   | heap          | 16 kB      | Airplanes (internal multilingual data)
 bookings | airports              | view     | postgres | permanent   |               | 0 bytes    | Airports
 bookings | airports_data         | table    | postgres | permanent   | heap          | 1288 kB    | Airports (internal multilingual data)
 bookings | axedemo_flights       | view     | postgres | permanent   |               | 0 bytes    | 
 bookings | boarding_passes       | table    | postgres | permanent   | heap          | 839 MB     | Boarding passes
 bookings | bookings              | table    | postgres | permanent   | heap          | 246 MB     | Bookings
 bookings | flights               | table    | postgres | permanent   | heap          | 5928 kB    | Flights
 bookings | flights_flight_id_seq | sequence | postgres | permanent   |               | 8192 bytes | 
 bookings | routes                | table    | postgres | permanent   | heap          | 552 kB     | Routes
 bookings | seats                 | table    | postgres | permanent   | heap          | 120 kB     | Seats
 bookings | segments              | table    | postgres | permanent   | heap          | 933 MB     | Flight segment (leg)
 bookings | tickets               | table    | postgres | permanent   | heap          | 876 MB     | Tickets
 bookings | timetable             | view     | postgres | permanent   |               | 0 bytes    | Detailed info about flights
(14 rows)

demo=# 
```

### С применением `.psqlrc`
```
[postgres@rmukhtarov-redos1 ~]$ psql demo
Started at:       2026-05-28 19:11:54+03 (1 day 03:03:17 ago)
Config loaded at: 2026-05-29 15:34:16+03 (06:40:55 ago)
Server role:      primary
WAL send (0):     
psql (18.3, server 17.9)
Type "help" for help.


2026-05-29 22:15:11+03:00  Postgres Pro (enterprise) 17.9.2  postgres@[local]:5432/demo
=# \d+
                                                             List of relations
  Schema  │         Name          │   Type   │  Owner   │ Persistence │ Access method │    Size    │              Description               
──────────┼───────────────────────┼──────────┼──────────┼─────────────┼───────────────┼────────────┼────────────────────────────────────────
 bookings │ airplanes             │ view     │ postgres │ permanent   │ ¤             │ 0 bytes    │ Airplanes
 bookings │ airplanes_data        │ table    │ postgres │ permanent   │ heap          │ 16 kB      │ Airplanes (internal multilingual data)
 bookings │ airports              │ view     │ postgres │ permanent   │ ¤             │ 0 bytes    │ Airports
 bookings │ airports_data         │ table    │ postgres │ permanent   │ heap          │ 1288 kB    │ Airports (internal multilingual data)
 bookings │ axedemo_flights       │ view     │ postgres │ permanent   │ ¤             │ 0 bytes    │ ¤
 bookings │ boarding_passes       │ table    │ postgres │ permanent   │ heap          │ 839 MB     │ Boarding passes
 bookings │ bookings              │ table    │ postgres │ permanent   │ heap          │ 246 MB     │ Bookings
 bookings │ flights               │ table    │ postgres │ permanent   │ heap          │ 5928 kB    │ Flights
 bookings │ flights_flight_id_seq │ sequence │ postgres │ permanent   │ ¤             │ 8192 bytes │ ¤
 bookings │ routes                │ table    │ postgres │ permanent   │ heap          │ 552 kB     │ Routes
 bookings │ seats                 │ table    │ postgres │ permanent   │ heap          │ 120 kB     │ Seats
 bookings │ segments              │ table    │ postgres │ permanent   │ heap          │ 933 MB     │ Flight segment (leg)
 bookings │ tickets               │ table    │ postgres │ permanent   │ heap          │ 876 MB     │ Tickets
 bookings │ timetable             │ view     │ postgres │ permanent   │ ¤             │ 0 bytes    │ Detailed info about flights
(14 rows)


2026-05-29 22:15:13+03:00  Postgres Pro (enterprise) 17.9.2  postgres@[local]:5432/demo
=# 
```

### С применением `.psqlrc`, мастер

```
student:~$ psql -p 5432
Started at:       2026-05-29 19:45:59+03 (02:32:28 ago)
Config loaded at: 2026-05-29 22:05:34+03 (00:12:53 ago)
Server role:      primary
WAL send (1):     ¤:-1
psql (16.11 (Ubuntu 16.11-1.pgdg24.04+1))
Type "help" for help.


2026-05-29 22:18:26+03:00  PostgreSQL 16.11  student@[local]:5432/student
=# 
```

### С применением `.psqlrc`, реплика

```
student:~$ psql -p 5433
Started at:       2026-05-29 20:23:32+03 (01:52:56 ago)
Config loaded at: 2026-05-29 20:23:32+03 (01:52:56 ago)
Server role:      replica
WAL receive (1):  /var/run/postgresql:5432
WAL send (0):     
psql (16.11 (Ubuntu 16.11-1.pgdg24.04+1))
Type "help" for help.


2026-05-29 22:16:27+03:00  PostgreSQL 16.11  student@[local]:5433/student
=#
```

## Ссылки по теме

* [Удобное цветное приглашение командной строки в `bash`](../bashrc)
* https://wiki.postgresql.org/wiki/Psqlrc
* [Как использовать `pspg`, видео на русском языке](https://pgconf.ru/talk/1589147)
