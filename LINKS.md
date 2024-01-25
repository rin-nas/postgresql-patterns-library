Ссылки с примерами SQL запросов

# Хабр

   1. **https://m.habr.com/en/company/yandex/blog/435880/** — Изменение схемы таблиц PostgreSQL без долгих блокировок. Лекция Яндекса (дать пример оптимизации миграции Version20190516085945.php)
   1. https://habr.com/post/228023/ — Работа с геолокациями в режиме highload (Задача поиска ближайшего соседа)
   1. https://habr.com/post/280912/ — Полезные трюки PostgreSQL
   1. https://habr.com/ru/company/postgrespro/blog/448368/ — SQL: задача о рабочем времени. [Лучшее решение](https://habr.com/ru/company/postgrespro/blog/448368/#comment_20187570).
   1. https://habr.com/ru/company/0/blog/316304/ Как заставить PostgreSQL считать быстрее
   1. https://m.habr.com/ru/post/468463/ - Улучшение производительности Zabbix + PostgreSQL при помощи партиционирования и индексирования
      1. https://github.com/Doctorbal/zabbix-postgres-partitioning
   1. https://m.habr.com/ru/company/otus/blog/472364/ - PostgreSQL и настройки согласованности записи для каждого конкретного соединения
   1. https://m.habr.com/ru/post/481556/ - Очередь задач в PostgreSQL
   1. https://m.habr.com/ru/post/483014/ - Очереди сообщений в PostgreSQL с использованием PgQ

# GitHub
   1. https://github.com/dataegret/pg-utils Useful DBA tools by Data Egret
   1. https://github.com/pgexperts/pgx_scripts/ A collection of useful little scripts for database analysis and administration, created by our team at PostgreSQL Experts
      1. index_bloat_checksql
      1. table_bloat_checksql
      1. fk_no_indexsql
      1. duplicate_indexes_fuzzysql
      1. needed_indexessql
      1. unneeded_indexessql
   1. https://github.com/k1aus/parallelsql - A sql extenstion that parallizes sql queries using dblink
      1. https://tech.binary.com/parallel-query-without-parallel-query/
      1. https://chumaky.team/blog/postgres-parallel-jobs
   1. https://github.com/ioguix/pgsql-bloat-estimation - Queries to mesure statistical bloat in btree indexes and tables for PostgreSQL
   1. https://github.com/lesovsky/uber-scripts - Scripts for Linux system administrators
   1. https://github.com/NikolayS/postgres_dba - The missing set of useful tools for Postgres DBA
   1. https://github.com/NikolayS/awesome-postgres - links
   1. https://gist.github.com/david-sanabria/0d3ff67eb56d2750502aed4186d6a4a7 - `CREATE OR REPLACE FUNCTION base62_encode( long_number bigint ) RETURNS text`
   1. https://gist.github.com/matheusoliveira/9488951 - Simple PostgreSQL functions to manipulate json objects: json_append(), json_delete(), json_merge(), json_update(), json_lint(), json_unlint()
   1. https://medium.com/hootsuite-engineering/recursively-merging-jsonb-in-postgresql-efd787c9fad7
   1. https://github.com/glynastill/pg_jsonb_delete_op - Hstore style delete "-" operator for jsonb
   1. https://github.com/heroku/heroku-pg-extras - This plugin is used to obtain information about a Heroku Postgres instance, that may be useful when analyzing performance issues. This includes information about locks, index usage, buffer cache hit ratios and vacuum statistics.
   1. https://github.com/rvkulikov/pg-deps-management - Recursively backup all dependent views, then modify base tables, then recreate all backuped views
   1. https://github.com/sjstoelting/pgsql-tweaks - PostgreSQL Views and Functions
   1. https://github.com/theory/pgtap/ - unit testing framework for PostgreSQL
   1. https://github.com/dimitri/regresql - RegreSQL, Regression Testing your SQL queries
   1. https://github.com/cybertec-postgresql/pgfaceting - PostgreSQL extension to quickly calculate facet counts using inverted index built with roaring bitmaps
   1. https://github.com/PostgREST/postgrest - PostgREST is a standalone web server that turns your PostgreSQL database directly into a RESTful API.
   1. https://github.com/supabase/pg_jsonschema - PostgreSQL extension providing JSON Schema validation

# StackOverflow
   1. https://stackoverflow.com/questions/7923237/return-pre-update-column-values-using-sql-only
   1. https://stackoverflow.com/questions/11532550/atomic-update-select-in-postgres
   1. https://stackoverflow.com/questions/28550679/what-is-the-difference-between-lateral-and-a-subquery-in-postgresql
   1. https://stackoverflow.com/questions/8443716/postgres-unique-constraint-for-array
   1. https://dba.stackexchange.com/questions/11329/monitoring-progress-of-index-construction-in-postgresql
   1. https://stackoverflow.com/questions/34657669/find-rows-where-text-array-contains-value-similar-to-input
   1. https://stackoverflow.com/questions/3994556/eliminate-duplicate-array-values-in-postgres
   1. https://stackoverflow.com/questions/3942258/how-do-i-temporarily-disable-triggers-in-postgresql
   1. https://stackoverflow.com/questions/38112379/disable-postgresql-foreign-key-checks-for-migrations

# Other
   1. https://postgres.ai/blog/20211018-postgresql-lock-trees
   1. https://www.citusdata.com/blog/2018/02/22/seven-tips-for-dealing-with-postgres-locks/
   1. http://www.pateldenish.com/2018/11/postgres-11-partitioning.html
   1. https://use-the-index-luke.com/no-offset — Как правильно делать постраничную навигацию без OFFSET
   1. https://www.jooq.org/sakila — БД, для которой есть примеры SQL запросов в документации MySQL
   1. https://pgloader.io/ —  Continuous Migration from your current database to PostgreSQL
   1. https://tapoueh.org/blog/2013/08/understanding-window-functions/ — Understanding Window Functions
   1. https://blog.jooq.org/2014/04/29/nosql-no-sql-how-to-calculate-running-totals/ — How to Calculate Running Totals
   1. https://hashrocket.com/blog/posts/faster-json-generation-with-postgresql — генерация JSON 
   1. https://shusson.info/post/building-nested-json-objects-with-postgres — генерация JSON
   1. https://tapoueh.org/blog/2018/05/postgresql-data-types-point/ (см. запрос с итоговыми суммами и диаграммами внизу)
   1. [задача параллельной многопроцессной обработки очереди](http://dklab.ru/chicken/nablas/53.html), обсуждение на [форуме](https://www.sql.ru/forum/681777/obsuzhdaem-blokirovki-pg-try-advisory-lock)
   1. https://pgday.ru/files/pgmaster14/max.boguk.query.optimization.pdf (оптимизация запросов)
   1. https://pgday.ru/presentation/232/5964945ea4142.pdf Учим слона танцевать
рок-н-ролл (оптимизация запросов)
   1. http://tatiyants.com/how-to-navigate-json-trees-in-postgres-using-recursive-ctes/
   1. https://wiki.postgresql.org/wiki/Category:Performance_Snippets
   1. https://wiki.postgresql.org/wiki/Index_Maintenance
   1. https://postgres.cz/wiki/PostgreSQL_SQL_Tricks
   1. https://pgday.ru/ru/2016/papers/62 Where is the space, Postgres?
   1. https://pgcookbook.ru/index.html
   1. https://wiki.postgresql.org/wiki/ArrXor
   1. http://akorotkov.github.io/blog/2016/06/17/faceted-search/ Фасетный поиск 
   1. https://www.cybertec-postgresql.com/en/faceting-large-result-sets/ FACETING LARGE RESULT SETS IN POSTGRESQL
   1. https://postgrespro.ru/media/2016/11/08/pgconfeu-fts-2016.pdf Better Full Text Search in PostgreSQL
   1. https://www.percona.com/blog/2019/07/22/automatic-index-recommendations-in-postgresql-using-pg_qualstats-and-hypopg/
   1. https://tech.binary.com/lock-contention-in-postgres/ (интересный способ уменьшить блокировки)
   1. **https://dataedo.com/kb/query/** Useful queries for popular relational databases to explore schema. Database Data Dictionary Query Toolbox
   1. https://aws.amazon.com/ru/blogs/database/validating-database-objects-after-migration-using-aws-sct-and-aws-dms/ Validating database objects after migration using AWS SCT and AWS DMS
   1. http://morozovsk.blogspot.com/2011/07/array-function-arraydiff-in-postgresql.html `array_diff()` и `array_intersect()` и др.
   1. https://begriffs.com/posts/2017-08-27-deferrable-sql-constraints.html
   1. https://begriffs.com/posts/2017-10-21-sql-domain-integrity.html
   1. https://begriffs.com/posts/2018-03-20-user-defined-order.html
   1. https://ru.wikipedia.org/wiki/Дерево_Штерна_—_Броко
      * https://www.youtube.com/watch?v=qPeD87HJ0UA&ab_channel=InsightsintoMathematics The Stern-Brocot tree
      * https://wiki.postgresql.org/wiki/User-specified_ordering_with_fractions
      * https://github.com/begriffs/pg_rational
   1. https://begriffs.com/pdf/dec2frac.pdf
   1. YouTube: [Advanced SQL](https://www.youtube.com/playlist?list=PL1XF9qjV8kH12PTd1WfsKeUQU6e83ldfc) — Chapter #07 — [Video #57 — PL/SQL use case: spreadsheet evaluation](https://www.youtube.com/watch?v=s49M6oeqkok&list=PL1XF9qjV8kH12PTd1WfsKeUQU6e83ldfc&index=57&ab_channel=DatabaseSystemsResearchGroupatUT%C3%BCbingen)
   1. https://hakibenita.com/sql-anomaly-detection Simple Anomaly Detection Using Plain SQL (Детектирование аномалий)
   1. https://wiki.postgresql.org/wiki/Inlining_of_SQL_functions

# Databases
   1. [IP2Location™ LITE IP-COUNTRY Database](https://lite.ip2location.com/database/db1-ip-country)
   1. [Реестр российской системы и плана нумерации телефонных номеров по областям](https://opendata.digital.gov.ru/registry/numeric/) 

# Сервисы для выполнения SQL (песочница)
   1. http://sqlfiddle.postgrespro.ru/
   1. https://dbfiddle.uk/
   1. https://www.db-fiddle.com/
