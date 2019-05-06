Ссылки с примерами SQL запросов

1. Хабр
   1. https://m.habr.com/en/company/yandex/blog/435880/ — Изменение схемы таблиц PostgreSQL без долгих блокировок. Лекция Яндекса
   1. https://habr.com/post/228023/ — Работа с геолокациями в режиме highload (Задача поиска ближайшего соседа)
   1. https://habr.com/post/280912/ — Полезные трюки PostgreSQL
1. http://cwestblog.com/2018/10/27/postgresql-query-hierarchical-data-without-recursion/
1. http://cwestblog.com/2018/10/29/postgresql-recursively-query-hierarchical-data/
1. http://www.pateldenish.com/2018/11/postgres-11-partitioning.html
1. https://use-the-index-luke.com/no-offset — Как правильно делать постраничную навигацию без OFFSET
1. https://www.jooq.org/sakila — БД, для которой есть примеры SQL запросов в документации MySQL
1. https://pgloader.io/ —  Continuous Migration from your current database to PostgreSQL
1. https://tapoueh.org/blog/2013/08/understanding-window-functions/ — Understanding Window Functions
1. https://blog.jooq.org/2014/04/29/nosql-no-sql-how-to-calculate-running-totals/ — How to Calculate Running Totals
1. https://hashrocket.com/blog/posts/faster-json-generation-with-postgresql — генерация JSON 
1. https://hashrocket.com/blog/posts/exploring-postgres-gin-index — Exploring the Postgres Gin index
1. https://tapoueh.org/blog/2018/05/postgresql-data-types-point/ (см. запрос с итоговыми суммами и диаграммами внизу)
1. [задача параллельной многопроцессной обработки очереди](http://dklab.ru/chicken/nablas/53.html), обсуждение на [форуме](https://www.sql.ru/forum/681777/obsuzhdaem-blokirovki-pg-try-advisory-lock)
1. https://pgday.ru/files/pgmaster14/max.boguk.query.optimization.pdf
1. https://pgday.ru/presentation/232/5964945ea4142.pdf
1. http://tatiyants.com/how-to-navigate-json-trees-in-postgres-using-recursive-ctes/
1. https://wiki.postgresql.org/wiki/Category:Performance_Snippets
1. https://postgres.cz/wiki/PostgreSQL_SQL_Tricks
1. https://pgday.ru/ru/2016/papers/62 Where is the space, Postgres?

SQL_CALC_FOUND_ROWS

quote_like
```sql
create function quote_like(text) returns text
    immutable
    strict
    language sql
as
$$
SELECT replace(replace(replace($1, '\', '\\'), '_', '\_'), '%', '\%');
$$;
```

quote_regexp
```sql
create function quote_regexp(text) returns text
    stable
    language plpgsql
as
$$
BEGIN
    RETURN REGEXP_REPLACE($1, '([[\](){}.+*^$|\\?-])', '\\\1', 'g');
END;
$$;
```
