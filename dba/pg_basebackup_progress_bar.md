# pg_basebackup progress bar, copy speed, estimated duration, estimated finish datetime

При копировании БД через `pg_basebackup` SQL запрос [`pg_basebackup_progress_bar.sql`](pg_basebackup_progress_bar.sql) показывает:
1. сколько уже скопировано в байтах и всего сколько скопировать нужно
1. сколько в процентах уже скопировано
1. скорость копирования (байт в секунду)
1. вычисляет (прогноз) сколько времени осталось на копирование
1. вычисляет (прогноз) когда именно закончится копирование (дата и время)

## Пример результата запроса

| | |
| :- | :- |
| **pretty\_backup\_streamed** | 991 GB |
| **pretty\_backup\_total** | 2592 GB |
| **query\_start** | 2023-03-20 10:20:39.691673 +03:00 |
| **duration** | 4 hours 34 mins 40.451258 secs |
| **progress\_percent** | 38.221 |
| **bytes\_per\_second** | 64536680 |
| **estimated\_duration** | 11 hours 58 mins 38.786409 secs |
| **estimated\_query\_end** | 2023-03-20 22:19:18.478082 +03:00 |

