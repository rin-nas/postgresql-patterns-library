VACUUM VERBOSE ANALYZE {table};

DROP TABLE IF EXISTS {table}_{JiraTaskId};
-- или переносим в другую схему, если временная таблица является резервной копией и нужно удалить её позже
ALTER TABLE IF EXISTS {table}_{JiraTaskId} SET SCHEMA migration;
