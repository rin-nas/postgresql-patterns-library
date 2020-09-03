-- Запросы выполнять НЕ в транзакции!
 
VACUUM VERBOSE ANALYZE {table};
 
-- сначала выполняем все тяжёлые вычисления
-- подготавливаем в таблице данные для последующего обновления: id, поля со старыми и/или новыми данными (при необходимости)
-- или подготавливаем в таблице данные для последующего удаления: id и все остальные поля
-- таблица является резервной копией для возможности отката
DROP TABLE IF EXISTS {table}_{JiraTaskId};
CREATE TABLE {table}_{JiraTaskId} AS
SELECT id/*значения в колонке id должны быть уникальными!*/, ...
FROM {table}, ...
WHERE ...;
 
CREATE UNIQUE INDEX {table}_{JiraTaskId}_uniq_id ON {table}_{JiraTaskId} (id);
 
--SELECT * FROM {table}_{JiraTaskId} ORDER BY id LIMIT 100; -- для отладки
 
