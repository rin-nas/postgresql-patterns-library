# Отзываем привилегии у псевдо роли PUBLIC

[Псевдо роль PUBLIC](https://postgrespro.ru/docs/postgresql/16/ddl-priv) не видна, но про неё следует знать. 
Это групповая роль, в которую включены все остальные роли. 
Это означает, что все роли по умолчанию будут иметь привилегии, наследуемые от PUBLIC.

Роль PUBLIC по умолчанию имеет следующие привилегии:

**для всех баз данных:**
* CONNECT — это означает что любая созданная роль сможет подключаться к базам данных, но не путайте с привилегией LOGIN;
* TEMPORARY — любая созданная роль сможет создавать временные объекты во всех база данных и объекты эти могут быть любого размера;

**для схемы public:**
* CREATE (создание объектов) — любая роль может создавать объекты в этой схеме (только для PostgreSQL ≤ v14);
* USAGE (доступ к объектам) — любая роль может использовать объекты в этой схеме;

**для схемы pg_catalog и information_schema:**
* USAGE (доступ к объектам) — любая роль может обращаться к таблицам системного каталога;

**для всех функций:**
* EXECUTE (выполнение) — любая роль может выполнять любую функцию. Ещё нужны ещё права USAGE на ту схему, в которой функция находится, и права к объектам к которым обращается функция.

Для увеличения безопасности у роли PUBLIC отбирают некоторые привилегии, чтобы отнять их у всех пользователей.

Отзываем у роли PUBLIC все привилегии
```sql
\connect {dbname}

-- отнимаем привилегии для уже созданных объектов
REVOKE ALL ON DATABASE {dbname} FROM PUBLIC; -- отнимаем привилегии CREATE, CONNECT, TEMPORARY
REVOKE ALL ON SCHEMA public FROM PUBLIC; -- отнимаем привилегии CREATE, USAGE (применимо к текущей БД!)

-- отнимаем привилегии для создаваемых объектов в будущем (применимо к текущей БД!)
alter default privileges revoke all on tables from PUBLIC;
alter default privileges revoke all on sequences from PUBLIC;
alter default privileges revoke all on routines from PUBLIC;
alter default privileges revoke all on types from PUBLIC;
alter default privileges revoke all on schemas from PUBLIC;

-- смотрим на изменённые привилегии по умолчанию (“describe default privileges”)
\ddp
```

Выдаём привилегии только конкретным групповым ролям (TODO)
```sql
GRANT CREATE ON SCHEMA public TO app_owner_role;
```
