
create type db_validation.schema_validate_checks as enum ('has_pk_uk', 'has_not_redundant_index', 'has_index_for_fk', 'has_table_comment', 'has_column_comment');

comment on type db_validation.schema_validate_checks is $$
Проверки в валидаторе качества схемы БД:
    has_pk_uk               - наличие первичного или уникального индекса в таблице
    has_not_redundant_index - отсутствие избыточных индексов в таблице
    has_index_for_fk        - наличие индексов для ограничений внешних ключей в таблице
    has_table_comment       - наличие описания для таблицы
    has_column_comment      - наличие описания для колонки
$$;

-- alter type db_validation.schema_validate_checks owner to alexan;

------------------------------------------------------------------------------------------------------------------------

drop table if exists db_validation.schema_validate_config;

create table db_validation.schema_validate_config (
    id int generated always as identity primary key,

    checks db_validation.schema_validate_checks[] check(cardinality(db_validation.array_unique(checks)) = cardinality(checks)
                                                        and cardinality(checks) > 0),

    schemas_ignore_regexp text check (schemas_ignore_regexp != ''
                                      and trim(schemas_ignore_regexp) = schemas_ignore_regexp
                                      and db_validation.is_regexp(schemas_ignore_regexp)),

    schemas_ignore regnamespace[] check(cardinality(db_validation.array_unique(schemas_ignore)) = cardinality(schemas_ignore)
                                        and cardinality(schemas_ignore) > 0),

    tables_ignore_regexp  text check (tables_ignore_regexp != ''
                                      and trim(tables_ignore_regexp) = tables_ignore_regexp
                                      and db_validation.is_regexp(tables_ignore_regexp) ),

    tables_ignore  regclass[] check(cardinality(db_validation.array_unique(tables_ignore)) = cardinality(tables_ignore)
                                    and cardinality(tables_ignore) > 0),

    --TODO
    /*table_columns_ignore text[] check(cardinality(depers.array_unique(table_columns_ignore)) = cardinality(table_columns_ignore)
                                      and cardinality(table_columns_ignore) > 0),*/

    created_at timestamptz(0) not null default now() check (created_at <= now()::timestamptz(0)),
    updated_at timestamptz(0) not null default now() check (updated_at <= now()::timestamptz(0)),
    check (created_at <= updated_at)
);

comment on table db_validation.schema_validate_config is 'Конфигурация валидатора качества схемы БД для текущей БД';
comment on column db_validation.schema_validate_config.id is 'ID';
comment on column db_validation.schema_validate_config.checks is $$
Список проверок (массив строк)
* Если передан null - то все возможные проверки
* Если передан пустой массив - то ни одной проверки
$$;
comment on column db_validation.schema_validate_config.schemas_ignore_regexp is 'Регулярное выражение со схемами, которые нужно проигнорировать';
comment on column db_validation.schema_validate_config.schemas_ignore is $$
Список схем, которые нужно проигнорировать
В список схем автоматически добавляются служебные схемы "information_schema" и "pg_catalog", указывать их явно не нужно
$$;
comment on column db_validation.schema_validate_config.tables_ignore_regexp is 'Регулярное выражение с таблицами (с указанием схемы), которые нужно проигнорировать';
comment on column db_validation.schema_validate_config.tables_ignore is 'Список таблиц в формате {schema}.{table}, которые нужно проигнорировать';

-- alter table db_validation.schema_validate_config owner to alexan;
