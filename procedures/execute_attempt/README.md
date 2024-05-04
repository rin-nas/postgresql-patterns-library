# Миграции БД: шаблон транзакции

* В БД имеются параметры, ограничивающие выполнение SQL запросов.
* В случае превышения ограничения БД терминирует "проблемный" SQL запрос.
* Эти параметры можно установить отдельно для сервера, роли, соединения, транзакции.

Параметры

* `lock_timeout` — максимальная длительность ожидания захвата блокировки. Не путать с длительностью уже захваченной блокировки!
* `statement_timeout` — максимальная длительность выполнения SQL запроса

```sql
START TRANSACTION;
 
    SET LOCAL lock_timeout TO '1s';
    SET LOCAL statement_timeout TO '30s';

    -- здесь ваш код миграции, например
    drop trigger {trigger} ON {table};
 
--ROLLBACK;
COMMIT;
```

Запускаем транзакцию и …

# Миграция не накатывается

Ошибка: `SQLSTATE[55P03]: Lock not available: 7 ERROR: canceling statement due to lock timeout`

Почему?

* Был превышен таймаут ожидания захвата блокировки ресурса БД

Что делать?

* Выполнить `ROLLBACK`. Накатить (откатить) повторно. Ошибка.
* Выполнить `ROLLBACK`. Накатить (откатить) повторно. Так много раз или приходите позже.
* Если не помогает, то разбираться, какие SQL запросы держат блокировку и можно ли от неё избавиться хотя бы на время выполнения мирации.


# Миграция: автоматизация повторного наката

Рутинную работу по повторному накату (откату) из-за ошибки lock timeout можно автоматизировать
Имеется готовое решение в виде SQL процедуры [`execute_attempt()`](execute_attempt.sql), в параметр которой нужно передать проблемный DDL запрос.

Пример 1
```sql
call execute_attempt($$
    drop trigger {trigger} ON {table};
$$);
```

Пример 2
```sql
call execute_attempt('alter table person_email column email type varchar(320)');
```

Пример 3
```sql
call execute_attempt(
    'ALTER TABLE person_email ADD COLUMN is_accepted BOOLEAN DEFAULT FALSE NOT NULL', --query
    '100ms', --lock_timeout
    50 --max_attempts
);
```
