# pg_basebackup progress bar, copy speed, estimated duration, estimated finish datetime

При копировании БД через `pg_basebackup` SQL запрос [`pg_basebackup_progress_bar.sql`](pg_basebackup_progress_bar.sql) показывает:

| Колонка | Пример значения | Описание | 
| :- | :- | :- |
| pretty\_backup\_streamed | 991 GB | сколько уже скопировано |
| pretty\_backup\_total | 2592 GB | сколько всего скопировать нужно |
| query\_start | 2023-03-20 10:20:39.691673 +03:00 | дата-время начала копирования |
| duration | 4 hours 34 mins 40.451258 secs | длительность копирования |
| progress\_percent | 38.221 | сколько в процентах уже скопировано |
| bytes\_per\_second | 64536680 | скорость копирования (байт в секунду) |
| estimated\_duration | 11 hours 58 mins 38.786409 secs | вычисляет (прогноз) сколько времени осталось на копирование |
| estimated\_query\_end | 2023-03-20 22:19:18.478082 +03:00 | вычисляет (прогноз) когда именно закончится копирование (дата и время) |
