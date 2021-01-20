VACUUM VERBOSE ANALYZE {table};

DROP TABLE IF EXISTS {table}_{JiraTaskId};
-- или, если нужно удалить временную таблицу позже, то переносим в другую схему
ALTER TABLE IF EXISTS {table}_{JiraTaskId} SET SCHEMA migration;
