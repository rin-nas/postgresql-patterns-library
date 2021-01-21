VACUUM VERBOSE ANALYZE {table};

DROP TABLE IF EXISTS {table}_{JiraTaskId};
-- или, если временная таблица является резервной копией нужно удалить её позже, то переносим в другую схему
ALTER TABLE IF EXISTS {table}_{JiraTaskId} SET SCHEMA migration;
