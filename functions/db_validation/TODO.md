# TODO Валидация схемы БД

1. Рефакторинг
   1. ✅ Вынести валидатор в отдельную схему `db_validation`, а функцию переименовать в `schema_validate()`. 
   1. ✅ Конфигурацию хранить в отдельной служебной таблице `db_validation.schema_validate_config`.
   1. Распилить валидатор на отдельные view / функции.
1. Наличие описания объектов БД
   1. Значение в `COMMENT ON COLUMN {table}.{column}` не должно быть пустым и не должно совпадать с названием колонки.
      Добавить в исключения колонку с названием `email`, `guid` (независимо от регистра).
   1. Добавить проверку наличия описаний (`comment on ...`) для БД, схем, представлений (view), типов, функций, процедур, триггеров. В миграциях БД забывают это делать.
1. Названия объектов БД
   1. Названия объектов БД д.б. только в нижнем регистре (Postgres makes everything lower case unless you double quote it).
   1. Название колонки для первичного несоставного ключа должно заканчиваться на `id` или `guid` (сделать настраиваемым)
   1. Название колонки `guid` должно иметь тип `uuid` (сделать настраиваемым)
   1. Название таблицы или колонки не может начинаться на `id_`, оно может так заканчиваться (сделать настраиваемым)
   1. Названия таблиц типа reviewed_resume д.б. невалидными, первое слово д.б. существительным, а не глаголом
   1. Добавить проверку именования последовательностей по шаблону `{table}_{column}_seq` (сделать настраиваемым). Некоторые фреймворки закладываются на эти названия. Для получения названия последовательности правильно использовать функцию `pg_get_serial_sequence('{table}', '{column}')`
1. Индексы
   1. ✅ Добавить проверку на наличие невалидных (битых) индексов. Сейчас для таких индексов возвращается ошибка "Отсутствует индекс для внешнего ключа".
   1. Добавить проверку уникальных индексов, чтобы все колонки из индекса были с ограничением `NOT NULL`. Иначе ограничение уникальности не работает и нужно делать [по другому](https://github.com/rin-nas/postgresql-patterns-library/tree/master#%D0%BA%D0%B0%D0%BA-%D1%81%D0%B4%D0%B5%D0%BB%D0%B0%D1%82%D1%8C-%D1%81%D0%BE%D1%81%D1%82%D0%B0%D0%B2%D0%BD%D0%BE%D0%B9-%D1%83%D0%BD%D0%B8%D0%BA%D0%B0%D0%BB%D1%8C%D0%BD%D1%8B%D0%B9-%D0%B8%D0%BD%D0%B4%D0%B5%D0%BA%D1%81-%D0%B3%D0%B4%D0%B5-%D0%BE%D0%B4%D0%BD%D0%BE-%D0%B8%D0%B7-%D0%BF%D0%BE%D0%BB%D0%B5%D0%B9-%D0%BC%D0%BE%D0%B6%D0%B5%D1%82-%D0%B1%D1%8B%D1%82%D1%8C-null).
   1. Добавить параметр для игнорирования индексов `indexes_ignore_regexp`. Пример: `^pgcompact_index_\d+$`.
   1. При обнаружении избыточных индексов рекомендовать удалять индексы с названием по маске `(_ccnew$|^pgcompact_index_\d+$)`, а не индексы с другими названиями
   1. B-деревья подходят для индексирования только скалярных данных. В массивах должен быть GIN индекс вместо btree.
   1. Добавить проверку на вероятно избыточный индекс, если для `field` есть `lower(field)`, `upper(field)`, `date(field)`. Рекомендовать удалить индекс на `field`!
   1. Обнаруживать (и рекомендовать удалять, а не выдавать ошибку) такие избыточные индексы:
      1. `CREATE UNIQUE INDEX ON paid_services.snapshot_package_limit USING btree (order_item_id, service_id, sort(uniq(zone_ids)))`
      1. `CREATE UNIQUE INDEX ON paid_services.snapshot_package_limit USING btree (order_item_id, service_id, zone_ids)`
1. Кроме ошибок нехватает рекоментаций, которые можно возвращать в результате работы функции валидации:
   1. Для текстовых колонок `TEXT (VARCHAR)` без ограничения длины и с отсутствием ограничения `check(...)` рекомендовать делать валидацию `check(length(col) between X and Y)`.
   1. Для колонок типа `json[b]` рекомендовать делать валидацию для верхнего уровня.
   1. CASCADE использовать в миграциях опасно. 
      Удаление может рекурсивно пойти по FK и удалить существующие объекты БД и записи в таблицах.
      Рекомендовать выстроить цепочку удаления объектов в правильной последовательности.
1. Типы колонок
   1. Вместо устаревшего `TIMESTAMP` (WITHOUT TIME ZONE) нужно использовать `TIMESTAMPTZ` (TIMESTAMP WITH TIME ZONE)
   1. Вместо устаревшего `CHAR(n) / VARCHAR(n)` нужно использовать `TEXT (VARCHAR)`. To restrict length, just enforce `CHECK` constraint!
   1. Вместо проблемного `MONEY` нужно использовать `NUMERIC` and store currency in another column
   1. Вместо устаревшего `SERIAL` нужно использовать `[BIG]INT GENERATED`
   1. Вместо `JSON` рекомендовать использовать `JSONB`
   1. Запретить использовать колонку с типом `varchar`. Нужно использовать тип `text` с ограничением, например: `check(length(col) between 0 and 100)`
   1. В текстовое поле нельзя записать `null` или пустую строку на выбор (когда нет ни одного ограничения типа `check` на колонку), д.б. только 1 способ. Пример проблемной миграции: `alter table {table} add {column} varchar(10);`
   5. Для колонки `updated_at` (название задать в конфиге) должен быть триггер, который устанавливает значение `now()` при создании или обновлении записи
6. Взять идеи из 
   1. [DBA: находим бесполезные индексы](https://habr.com/ru/company/tensor/blog/488104/)
   1. https://github.com/ankane/strong_migrations
   1. https://github.com/kristiandupont/schemalint/tree/master/src/rules
   1. https://github.com/IMRSVDataLabs/imrsv-schema-linter
   1. https://gitlab.com/depesz/pgWikiDont/-/tree/master/
   1. https://www.google.com/search?q=postgresq+schema+linter - ещё ссылки здесь
1. Объекты БД в одной схеме должны принадлежать одному владельцу (опциональная проверка), см. [`pg_object_owner.sql`](../views/pg_object_owner.sql)
1. Добавить проверку для заперщения возможности вставки в таблицу (название не заканчивается на `_log` или `_history`) дубликатов строк, если есть PK на колонку id и нет UK без id. В этой проверке не участвуют колонка с PK, колонки с датой, датой-временем.
1. Добавить проверку при наличии расширения https://github.com/okbob/plpgsql_check/
1. Добавить проверку отсутствия триггерных функций, которые нигде не используются. Пример: удалили триггер, который вызывал триггерную функцию. Теперь функция нигде не используется.
1. Добавить проверку отсутствия дубликатов ограничений таблицы (`has_not_duplicate_constraint`), которые могут получиться при повторных накатах миграции БД:
   ```sql
   with s as (
      SELECT con.conrelid::regclass                                                   as table_name,
             array_length(array_agg(pg_get_constraintdef(con.oid, true)), 1)          as def_count,
             array_length(array_agg(distinct pg_get_constraintdef(con.oid, true)), 1) as def_uniq_count,
             array_agg(pg_get_constraintdef(con.oid, true)) as def
      FROM pg_constraint as con
      WHERE connamespace::regnamespace not in ('pg_catalog', 'information_schema')
        and con.conrelid != 0
      GROUP BY con.conrelid::regclass
   )
   select s.table_name, t.*
   from s
   cross join lateral (
       select u.value,
              count(*) as duplicate_count
       from unnest(s.def) as u(value)
       group by u.value
       having count(*) > 1
   ) as t
   where def_count != def_uniq_count;
   ```
1. Добавить проверку: если для последовательностей процент достижения своего максимального значения > N%, то рекоментовать сменить `int` на `bigint`.
   Ссылки по теме: 
   [1](https://stackoverflow.com/questions/54795701/migrating-int-to-bigint-in-postgressql-without-any-downtime),
   [2](http://zemanta.github.io/2021/08/25/column-migration-from-int-to-bigint-in-postgresql/),
   [3](https://engineering.silverfin.com/pg-zero-downtime-bigint-migration/).
   ```sql
   select schemaname as schema,
          sequencename as sequence_name,
          data_type,
          used_percent
   from pg_sequences
   cross join round(last_value * 100.0 / max_value, 2) as used_percent
   where last_value is not null /*null means access denied*/ and used_percent > 33
   order by used_percent desc;
   ```

# TODO валидация потенциальных ошибок в SQL запросах

К валидатору схемы БД это не относится. Собираю на будущее для другого валидатора.

1) Вместо `NOT IN(...)` [лучше](https://github.com/rin-nas/postgresql-patterns-library/blob/master/README.md#%D0%9F%D0%BE%D1%87%D0%B5%D0%BC%D1%83-%D0%B7%D0%B0%D0%BF%D1%80%D0%BE%D1%81-%D1%81-%D0%BF%D0%BE%D0%B4%D0%B7%D0%B0%D0%BF%D1%80%D0%BE%D1%81%D0%BE%D0%BC-%D0%B2-NOT-IN-%D0%B2%D0%BE%D0%B7%D0%B2%D1%80%D0%B0%D1%89%D0%B0%D0%B5%D1%82-0-%D0%B7%D0%B0%D0%BF%D0%B8%D1%81%D0%B5%D0%B9) использовать `NOT EXISTS(...)`

2) Возможные ошибки с `timestamp[tz]` в границах значений.

Неправильно:
```sql
SELECT sum(amount)
FROM transactions
WHERE transaction_timestamp
BETWEEN ('2023-02-05 00:00' AND '2023-02-06 00:00');
```

Правильно:
```sql
SELECT sum(amount)
FROM transactions
WHERE transaction_timestamp >= '2023-02-05 00:00'
AND transaction_timestamp < '2023-02-06 00:00';
```

3) Несколько DDL запросов для одного объекта БД лучше объединять в 1 запрос, если позволяет синтаксис.
4) Несколько DDL запросов для разных объектов БД лучше собирать в группу. Т.е. д.б. группа из DDL запросов и группа из DML запросов.
5) Группу из DDL запросов лучше размещать после группы из DML запросов, так будет меньше длительность эксклюзивной блокировки таблиц.
6) Длительность выполнения группы DDL запросов д.б. < 3 секунд.
7) Обнаруживать звёздочку в месте перечисления колонок в SELECT запросе, рекомендовать её заменить на явное перечисление колонок
8) Если в запросе присутствует `LIMIT` и `OFFSET`, но отсутствует `ORDER BY`, то рекомендовать добавить его.
9) Запретить `UPDATE` запросы без `WHERE`, т.к. он блокирует все строки таблицы. При одновременном выполнении этого запроса в разных транзакциях возникают взаимоблокировки.

# Ссылки

* https://fosdem.org/2023/schedule/event/postgresql_dont_do_this/attachments/slides/5948/export/events/attachments/postgresql_dont_do_this/slides/5948/DontDoThis.pdf
