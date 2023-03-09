# TODO

1. Исправить [ошибку](https://github.com/rin-nas/postgresql-patterns-library/issues/4) для PostgreSQL v12: `[0A000] ERROR: DROP INDEX CONCURRENTLY must be first action in transaction`
1. Доработать запрос `select * from db_audit.ddl_log`, чтобы при отсутствии прав доступа к объектам не выдавал ошибку
1. Доработать `db_audit.ddl_objects`, чтобы корректно показывал дату создания и обновления для `CREATE VIEW` и `CREATE OR REPLACE VIEW`.
   С `CREATE [OR REPLACE] FUNCTION/PROCEDURE` уже сложнее, т.к. нужно ещё учитывать параметры функции. Добавить колонку `transaction_id`.
1. Автоочистка таблиц. 
   1. Команды с опцией `IF [NOT] EXISTS` (например, DROP TABLE IF EXISTS ...), которые создают только 1 событие `ddl_command_start`, не выполняются, т.к. объект уже [не] существует. 
   В этом случае достаточно хранить только 1000 последних записей, остальные нужно удалять. 
   В функции `db_audit.ddl_command_start_log()` нужно добавить условие: если `top_queries` содержит `IF [NOT] EXISTS`, то выполнять команду удаления.
   1. В триггерной функции `db_audit.ddl_command_end_log()` в SQL запрос автоочистки добавить `limit 1000` в оба SELECT подзапроса
1. В `db_audit.ddl_start_log` добавить колонку `transactions_delta` для отображения прошедшего времени между предыдущей и следующей транзакцией
1. Сделать представление `db_audit.ddl_objects_deleted`. Иногда нужно смотреть историю удалённых объектов.


## Автоочистка таблицы

```sql

--explain
select id --, count(*), min(created_at)
from db_audit.ddl_log as s
where s.event = 'ddl_command_start'
  and not exists(select s.*
                 from db_audit.ddl_log as e
                 where e.transaction_id = s.transaction_id
                   and e.transaction_start_at = s.transaction_start_at
                 and e.event != 'ddl_command_start'
                 )
order by id desc
offset 1000
limit 1000
```
