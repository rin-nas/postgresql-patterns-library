
-- валидация БД v3_rabota
insert into db_validation.schema_validate_config (
    checks, schemas_ignore_regexp, schemas_ignore, tables_ignore_regexp, tables_ignore
)
values
(
    array['has_pk_uk', 'has_not_redundant_index', 'has_index_for_fk', 'has_table_comment', 'has_column_comment']::db_validation.schema_validate_checks[],
    null,
    null --array['unused', 'migration', 'test']::regnamespace[],
    '(?<![a-z])(te?mp|test|unused|backups?|deleted)(?![a-z])',
    null --array['public._migration_versions']::regclass[]
);

-- TEST
table db_validation.schema_validate_config;
