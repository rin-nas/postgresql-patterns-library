Ссылки с примерами SQL запросов

# Хабр

   1. **https://m.habr.com/en/company/yandex/blog/435880/** — Изменение схемы таблиц PostgreSQL без долгих блокировок. Лекция Яндекса (дать пример оптимизации миграции Version20190516085945.php)
   1. https://habr.com/post/228023/ — Работа с геолокациями в режиме highload (Задача поиска ближайшего соседа)
   1. https://habr.com/post/280912/ — Полезные трюки PostgreSQL
   1. https://habr.com/ru/company/postgrespro/blog/448368/ — SQL: задача о рабочем времени. [Лучшее решение](https://habr.com/ru/company/postgrespro/blog/448368/#comment_20187570).
   1. https://habr.com/ru/company/0/blog/316304/ Как заставить PostgreSQL считать быстрее
   1. https://m.habr.com/ru/post/468463/ - Улучшение производительности Zabbix + PostgreSQL при помощи партиционирования и индексирования
   1. https://m.habr.com/ru/company/otus/blog/472364/ - PostgreSQL и настройки согласованности записи для каждого конкретного соединения
   1. https://m.habr.com/ru/post/481556/ - Очередь задач в PostgreSQL

# GitHub
   1. https://github.com/dataegret/pg-utils Useful DBA tools by Data Egret
   1. https://github.com/pgexperts/pgx_scripts/ A collection of useful little scripts for database analysis and administration, created by our team at PostgreSQL Experts
   1. https://github.com/k1aus/parallelsql - A sql extenstion that parallizes sql queries using dblink
   1. https://github.com/ioguix/pgsql-bloat-estimation - Queries to mesure statistical bloat in btree indexes and tables for PostgreSQL
   1. https://github.com/lesovsky/uber-scripts - Scripts for Linux system administrators
   1. https://github.com/NikolayS/postgres_dba - The missing set of useful tools for Postgres DBA
   1. https://github.com/NikolayS/awesome-postgres - links

# StackOverflow
   1. https://stackoverflow.com/questions/28550679/what-is-the-difference-between-lateral-and-a-subquery-in-postgresql
   1. https://stackoverflow.com/questions/8443716/postgres-unique-constraint-for-array
   1. https://stackoverflow.com/questions/20215724/need-foreign-key-as-array
   1. https://dba.stackexchange.com/questions/11329/monitoring-progress-of-index-construction-in-postgresql

# Other
   1. https://www.citusdata.com/blog/2018/02/22/seven-tips-for-dealing-with-postgres-locks/
   1. http://cwestblog.com/2018/10/27/postgresql-query-hierarchical-data-without-recursion/
   1. http://cwestblog.com/2018/10/29/postgresql-recursively-query-hierarchical-data/
   1. http://www.pateldenish.com/2018/11/postgres-11-partitioning.html
   1. https://use-the-index-luke.com/no-offset — Как правильно делать постраничную навигацию без OFFSET
   1. https://www.jooq.org/sakila — БД, для которой есть примеры SQL запросов в документации MySQL
   1. https://pgloader.io/ —  Continuous Migration from your current database to PostgreSQL
   1. https://tapoueh.org/blog/2013/08/understanding-window-functions/ — Understanding Window Functions
   1. https://blog.jooq.org/2014/04/29/nosql-no-sql-how-to-calculate-running-totals/ — How to Calculate Running Totals
   1. https://hashrocket.com/blog/posts/faster-json-generation-with-postgresql — генерация JSON 
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
   1. http://akorotkov.github.io/blog/2016/06/17/faceted-search/
   1. http://sqlfiddle.postgrespro.ru/ - песочница
   1. https://www.percona.com/blog/2019/07/22/automatic-index-recommendations-in-postgresql-using-pg_qualstats-and-hypopg/
   1. https://tech.binary.com/parallel-query-without-parallel-query/
   1. https://tech.binary.com/lock-contention-in-postgres/ (интересный способ уменьшить блокировки)

# TODO
Рассказать, как Postgresql можно обойтись без SQL_CALC_FOUND_ROWS и почему это лучше

# UPDATE/DELETE million rows ideas

```
LOOP
  UPDATE table SET flag=0 
  WHERE id IN (
      SELECT id 
      FROM table 
      WHERE flag <> 0 
      LIMIT 50000
      FOR UPDATE OF table SKIP LOCKED
  );
   
  IF NOT FOUND THEN
      UPDATE table SET flag=0 
      WHERE id IN (
          SELECT id 
          FROM table 
          WHERE flag <> 0 
          LIMIT 50000
          --FOR UPDATE OF table SKIP LOCKED
      );
  END IF;

  EXIT WHEN NOT FOUND;

  VACUUM ANALYSE table;
END LOOP;

```
1. https://postgrespro.ru/docs/postgresql/11/logical-replication
1. https://blog.codacy.com/how-to-update-large-tables-in-postgresql/
1. https://dba.stackexchange.com/questions/41059/optimizing-bulk-update-performance-in-postgresql

1. https://m.habr.com/en/company/lanit/blog/351160/ - PostgreSQL. Ускоряем деплой в семь раз с помощью «многопоточки»
1. https://habr.com/ru/post/481610/ - PostgreSQL Antipatterns: обновляем большую таблицу под нагрузкой
