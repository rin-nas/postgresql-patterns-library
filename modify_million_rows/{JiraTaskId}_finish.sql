VACUUM VERBOSE ANALYZE {table};

DROP TABLE IF EXISTS {table}_{JiraTaskId};
-- или, если нужно удалить временную таблицу позже, переносим её в другую схему
ALTER TABLE IF EXISTS {table}_{JiraTaskId} SET SCHEMA migration;
