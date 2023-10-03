# Как в PostgreSQL журналировать DDL команды в таблицу БД?
# How log DDL queries to table in PostgreSQL?

DDL команды обычно логируются в общем большом файловом журнале. У этого подхода следующие недостатки:
1. Там полно SELECT и DML команд, отыскать там DDL непросто. DDL запросы ещё могут сохраняться в Graylog, но отыскать там DDL тоже непросто.
1. Там нет чётко выделенного идентификатора объекта БД и события, только тело DDL команды.
1. Файловые журналы обычно хранятся несколько недель и потом автоматически удаляются.

**Логирование DDL команд *в отдельной таблице БД* позволяет:**
1. Усилить безопасность БД:
    * сохранять легальные изменения схемы БД администраторами БД (DBA), включая ручные (неавтоматические) миграции БД
    * выявить нелегальные изменения схемы БД: прямое выполнения DDL команд мимо миграторов БД; SQL injection
1. Сохранять следующие события:
    * Создание, удаление, модификация объектов БД (schema, table, view, column, sequence, index, type, function, procedure, domain), включая изменение владельца. При удалении сохраняется информация о всех удалённых зависимых объектах.
    * Наделение и отзыв прав доступа к объектам БД
    * Создание, удаление, модификация пользователей и ролей, включая изменение атрибутов и пароля.
1. Иметь возможность получить и предоставить данные по запросу коллег при возникновении инцидентов, включая нестабильность работы БД. При этом будет возможность получить точную дату-время начала и окончания, а так же длительность выполнения DDL запросов в транзакции.
1. Знать дату-время создания и обновления объектов БД (к сожалению, в БД такая информация в системных таблицах отсутствует), чтобы потом автоматически их удалять через 1 месяц после создания из схем:
    * `migration` — здесь хранятся таблицы с данными для возможности для отката ранее накаченных миграций БД
    * `unused` — здесь временно хранятся неиспользуемые и уже ненужные объекты БД перед их окончательным удалением
1. Выявить DDL запросы в бизнес-логике приложения (такие запросы должны выполняться под отдельным пользователем?).
1. Для отдела информационной безопасности появляется возможность интеграции с [SIEM](https://ru.wikipedia.org/wiki/SIEM) в качестве источника данных.

# Ограничения

Событие `ddl_command_start` для запросов `DROP INDEX CONCURRENTLY …` не журналируется.

# Cтатистические SQL запросы с примерами

```sql
select tag, 
       event, 
       count(*) as total
from db_audit.ddl_log
group by 1, 2
order by 1, 2;
```

| tag | event | total |
| :--- | :--- | :--- |
| ALTER FUNCTION | ddl\_command\_start | 15 |
| ALTER FUNCTION | ddl\_command\_end | 15 |
| ALTER SCHEMA | ddl\_command\_start | 2 |
| ALTER SCHEMA | ddl\_command\_end | 2 |
| ALTER SEQUENCE | ddl\_command\_start | 4 |
| ALTER SEQUENCE | ddl\_command\_end | 4 |
| ALTER TABLE | ddl\_command\_start | 79 |
| ALTER TABLE | ddl\_command\_end | 79 |
| ALTER TABLE | sql\_drop | 4 |
| ALTER TYPE | ddl\_command\_start | 6 |
| ALTER TYPE | ddl\_command\_end | 6 |
| ALTER VIEW | ddl\_command\_start | 2 |
| ALTER VIEW | ddl\_command\_end | 2 |
| COMMENT | ddl\_command\_start | 167 |
| COMMENT | ddl\_command\_end | 167 |
| CREATE FUNCTION | ddl\_command\_start | 34 |
| CREATE FUNCTION | ddl\_command\_end | 34 |
| CREATE INDEX | ddl\_command\_start | 53 |
| CREATE INDEX | ddl\_command\_end | 55 |
| CREATE PROCEDURE | ddl\_command\_start | 5 |
| CREATE PROCEDURE | ddl\_command\_end | 5 |
| CREATE SCHEMA | ddl\_command\_start | 2 |
| CREATE SCHEMA | ddl\_command\_end | 2 |
| CREATE TABLE | ddl\_command\_start | 23258 |
| CREATE TABLE | ddl\_command\_end | 13831 |
| CREATE TABLE AS | ddl\_command\_start | 8 |
| CREATE TABLE AS | ddl\_command\_end | 8 |
| CREATE TRIGGER | ddl\_command\_start | 20 |
| CREATE TRIGGER | ddl\_command\_end | 20 |
| CREATE TYPE | ddl\_command\_start | 2 |
| CREATE TYPE | ddl\_command\_end | 2 |
| CREATE VIEW | ddl\_command\_start | 6 |
| CREATE VIEW | ddl\_command\_end | 8 |
| DROP FUNCTION | ddl\_command\_start | 3 |
| DROP FUNCTION | sql\_drop | 3 |
| DROP INDEX | ddl\_command\_start | 10 |
| DROP INDEX | sql\_drop | 10 |
| DROP PROCEDURE | ddl\_command\_start | 1 |
| DROP PROCEDURE | sql\_drop | 1 |
| DROP SCHEMA | ddl\_command\_start | 1 |
| DROP SCHEMA | sql\_drop | 1 |
| DROP TABLE | ddl\_command\_start | 32167 |
| DROP TABLE | sql\_drop | 132 |
| DROP TRIGGER | ddl\_command\_start | 16 |
| DROP TRIGGER | sql\_drop | 1 |
| DROP TYPE | ddl\_command\_start | 2 |
| DROP TYPE | sql\_drop | 2 |
| DROP VIEW | ddl\_command\_start | 1 |
| DROP VIEW | sql\_drop | 4 |
| GRANT | ddl\_command\_start | 5 |
| GRANT | ddl\_command\_end | 5 |
| REFRESH MATERIALIZED VIEW | ddl\_command\_start | 17534 |
| REFRESH MATERIALIZED VIEW | ddl\_command\_end | 17534 |

```sql
select tag,
       lower(object_type) as object_type,
       count(*) as total
from db_audit.ddl_log
where event != 'ddl_command_start'
group by 1, 2
order by 1, 2;
```

| tag | object\_type | total |
| :--- | :--- | :--- |
| ALTER FUNCTION | function | 15 |
| ALTER SCHEMA | schema | 2 |
| ALTER SEQUENCE | sequence | 4 |
| ALTER TABLE | table | 77 |
| ALTER TABLE | table column | 3 |
| ALTER TABLE | table constraint | 3 |
| ALTER TYPE | type | 6 |
| ALTER VIEW | view | 2 |
| COMMENT | function | 5 |
| COMMENT | procedure | 3 |
| COMMENT | schema | 2 |
| COMMENT | table | 13 |
| COMMENT | table column | 132 |
| COMMENT | type | 7 |
| COMMENT | view | 5 |
| CREATE FUNCTION | function | 34 |
| CREATE INDEX | index | 55 |
| CREATE PROCEDURE | procedure | 5 |
| CREATE SCHEMA | schema | 2 |
| CREATE TABLE | index | 15 |
| CREATE TABLE | sequence | 28 |
| CREATE TABLE | table | 13989 |
| CREATE TABLE AS | table | 8 |
| CREATE TRIGGER | trigger | 20 |
| CREATE TYPE | type | 2 |
| CREATE VIEW | view | 8 |
| DROP FUNCTION | function | 3 |
| DROP INDEX | index | 10 |
| DROP PROCEDURE | procedure | 1 |
| DROP SCHEMA | schema | 1 |
| DROP TABLE | default value | 6 |
| DROP TABLE | index | 34 |
| DROP TABLE | sequence | 2 |
| DROP TABLE | table | 18 |
| DROP TABLE | table constraint | 10 |
| DROP TABLE | toast table | 10 |
| DROP TABLE | trigger | 4 |
| DROP TABLE | type | 48 |
| DROP TRIGGER | trigger | 1 |
| DROP TYPE | type | 2 |
| DROP VIEW | rule | 1 |
| DROP VIEW | type | 2 |
| DROP VIEW | view | 1 |
| GRANT | sequence | 1 |
| GRANT | table | 4 |
| REFRESH MATERIALIZED VIEW | materialized view | 17536 |
