# Коллекция готовых SQL запросов для PostgreSQL

## Содержание

**[Проектирование данных](#Проектирование-данных)**
   1. [Использование колонок с типом массив](#Использование-колонок-с-типом-массив)

**[Получение данных](#Получение-данных)**
   1. [Строки](#Строки)
      1. [Агрегатная функция конкатенации строк (аналог `group_concat()` в MySQL)](#Агрегатная-функция-конкатенации-строк-аналог-group_concat-в-MySQL)
      1. [Как проверить email на валидность?](#Как-проверить-email-на-валидность)
      1. [Как транслитерировать русские буквы на английские?](#Как-транслитерировать-русские-буквы-на-английские)
      1. [Как распарсить CSV строку в таблицу?](#Как-распарсить-CSV-строку-в-таблицу)
      1. [Как определить пол по ФИО (фамилии, имени, отчеству) на русском языке?](#Как-определить-пол-по-ФИО-фамилии-имени-отчеству-на-русском-языке)
      1. [Как заквотировать строку для использования в регулярном выражении?](#Как-заквотировать-строку-для-использования-в-регулярном-выражении)
      1. [Как заквотировать строку для использования в операторе LIKE?](#Как-заквотировать-строку-для-использования-в-операторе-LIKE)
   1. [JSON](#JSON)
      1. [Как получить записи, которые удовлетворяют условиям из JSON массива?](#Как-получить-записи-которые-удовлетворяют-условиям-из-JSON-массива)
      1. [Как сравнить 2 JSON и получить отличия?](#Как-сравнить-2-JSON-и-получить-отличия)
   1. [Массивы](#Массивы)
      1. [Агрегатная функция конкатенации (объединения) массивов](#Агрегатная-функция-конкатенации-(объединения)-массивов)
      1. [Как получить одинаковые элементы массивов (пересечение массивов)?](#Как-получить-одинаковые-элементы-массивов-пересечение-массивов)
      1. [Как получить уникальные элементы массива или отсортировать их?](#Как-получить-уникальные-элементы-массива-или-отсортировать-их)
   1. [Поиск по фразе (точный и неточный)](#Поиск-по-фразе-точный-и-неточный)
      1. [Как найти список строк, совпадающих со списком шаблонов?](#Как-найти-список-строк-совпадающих-со-списком-шаблонов)
      1. [Как получить названия сущностей по поисковой фразе с учётом начала слов (поисковые подсказки)?](#Как-получить-названия-сущностей-по-поисковой-фразе-с-учётом-начала-слов-поисковые-подсказки)
      1. [Как для слова с опечаткой (ошибкой) получить наиболее подходящие варианты слов для замены (исправление опечаток)?](#Как-для-слова-с-опечаткой-ошибкой-получить-наиболее-подходящие-варианты-слов-для-замены-исправление-опечаток)
   1. [Деревья и графы](#Деревья-и-графы)
      1. [Как получить список названий предков и наследников для каждого узла дерева (на примере регионов)?](#Как-получить-список-названий-предков-и-наследников-для-каждого-узла-дерева-на-примере-регионов)
      1. [Как получить циклические связи в графе?](#Как-получить-циклические-связи-в-графе)
      1. [Как защититься от циклических связей в графе?](#Как-защититься-от-циклических-связей-в-графе)
      1. [Как получить названия всех уровней сферы деятельности 4-го уровня?](#Как-получить-названия-всех-уровней-сферы-деятельности-4-го-уровня)
   1. [Оптимизация выполнения запросов](#Оптимизация-выполнения-запросов)
      1. [Как посмотреть на план выполнения запроса (EXPLAIN) в наглядном графическом виде?](#Как-посмотреть-на-план-выполнения-запроса-EXPLAIN-в-наглядном-графическом-виде)
      1. [Как ускорить SELECT запросы c сотнями и тысячами значениями в IN(...)?](#Как-ускорить-SELECT-запросы-c-сотнями-и-тысячами-значениями-в-IN)
      1. [Как использовать вывод EXPLAIN запроса в другом запросе?](#Как-использовать-вывод-EXPLAIN-запроса-в-другом-запросе)
   1. [Как получить записи-дубликаты по значению полей?](#Как-получить-записи-дубликаты-по-значению-полей)
   1. [Как получить время выполнения запроса в его результате?](#Как-получить-время-выполнения-запроса-в-его-результате)
   1. [Как разбить большую таблицу по N тысяч записей, получив диапазоны id?](#Как-разбить-большую-таблицу-по-N-тысяч-записей-получив-диапазоны-id)
   1. [Как выполнить следующий SQL запрос, если предыдущий не вернул результат?](#Как-выполнить-следующий-SQL-запрос-если-предыдущий-не-вернул-результат)
   1. [Как развернуть запись в набор колонок?](#Как-развернуть-запись-в-набор-колонок)
   1. [Как получить итоговую сумму для каждой записи в одном запросе?](#Как-получить-итоговую-сумму-для-каждой-записи-в-одном-запросе)
   1. [Как получить возраст по дате рождения?](#Как-получить-возраст-по-дате-рождения)
   1. [Как получить дату или дату и время в формате ISO-8601?](#Как-получить-дату-или-дату-и-время-в-формате-ISO-8601)
   1. [Как вычислить дистанцию между 2-мя точками на Земле по её поверхности в километрах?](#Как-вычислить-дистанцию-между-2-мя-точками-на-Земле-по-её-поверхности-в-километрах)
   1. [Как найти ближайшие населённые пункты относительно заданных координат?](#Как-найти-ближайшие-населённые-пункты-относительно-заданных-координат)
   1. [Как вычислить приблизительный объём данных для результата SELECT запроса?](#Как-вычислить-приблизительный-объём-данных-для-результата-SELECT-запроса)
  
**[Модификация данных (DML)](#Модификация-данных-DML)**
   1. [Как добавить или обновить записи одним запросом (UPSERT)?](#Как-добавить-или-обновить-записи-одним-запросом-UPSERT)
   1. [Как модифицировать данные в нескольких таблицах и вернуть id затронутых записей в одном запросе?](#Как-модифицировать-данные-в-нескольких-таблицах-и-вернуть-id-затронутых-записей-в-одном-запросе)
   1. [Как добавить запись с id, значение которого нужно сохранить ещё в другом поле в том же INSERT запросе?](#Как-добавить-запись-с-id-значение-которого-нужно-сохранить-ещё-в-другом-поле-в-том-же-INSERT-запросе)
   1. [Как сделать несколько последующих запросов с полученным при вставке id из первого запроса?](#Как-сделать-несколько-последующих-запросов-с-полученным-при-вставке-id-из-первого-запроса)
   1. [Как модифицировать данные в связанных таблицах одним запросом?](#Как-модифицировать-данные-в-связанных-таблицах-одним-запросом)
   1. [Как обновить запись так, чтобы не затереть чужие изменения, уже сделанные кем-то?](#Как-обновить-запись-так-чтобы-не-затереть-чужие-изменения-уже-сделанные-кем-то)

**[Модификация схемы данных (DDL)](#Модификация-схемы-данных-DDL)**
   1. [Как добавить колонку в существующую таблицу без её блокирования?](#Как-добавить-колонку-в-существующую-таблицу-без-её-блокирования)
   1. [Индексы](#Индексы)
      1. [Как сделать ограничение уникальности на колонку в существующей таблице без её блокирования?](#Как-сделать-ограничение-уникальности-на-колонку-в-существующей-таблице-без-её-блокирования)
      1. [Как сделать составной уникальный индекс, где одно из полей может быть null?](#Как-сделать-составной-уникальный-индекс-где-одно-из-полей-может-быть-null)
      1. [Как починить сломаный уникальный индекс, имеющий дубликаты?](#Как-починить-сломаный-уникальный-индекс-имеющий-дубликаты)
      1. [Как временно отключить индекс?](#Как-временно-отключить-индекс)
      1. [Как сделать компактный уникальный индекс на текстовое поле?](#Как-сделать-компактный-уникальный-индекс-на-текстовое-поле)

**[Администрирование](#Администрирование)**
   1. [Как получить список процессов (SQL запросов), выполняющихся сейчас?](#Как-получить-список-процессов-SQL-запросов-выполняющихся-сейчас)
   1. [Как остановить или завершить работу процессов?](#Как-остановить-или-завершить-работу-процессов)
   1. [Как получить список всех функций БД, включая триггерные процедуры?](#Как-получить-список-всех-функций-БД-включая-триггерные-процедуры)
   1. [Как получить список всех зависимостей (внешних ключей) между таблицами БД?](#Как-получить-список-всех-зависимостей-внешних-ключей-между-таблицами-БД)
   1. [Как получить статистику использования индексов?](#Как-получить-статистику-использования-индексов)
   1. [Как получить список установленных расширений (extensions)?](#Как-получить-список-установленных-расширений-extensions)
   1. [Как получить список таблиц с размером занимаемого места?](#Как-получить-список-таблиц-с-размером-занимаемого-места)
   1. [Как получить и изменить значения параметров конфигурации выполнения?](#Как-получить-и-изменить-значения-параметров-конфигурации-выполнения)
   1. [Как получить все активные в данный момент процессы автовакуумa и время их работы?](#Как-получить-все-активные-в-данный-момент-процессы-автовакуумa-и-время-их-работы)
   1. [Как узнать, почему время ответа от базы периодически падает?](#Как-узнать-почему-время-ответа-от-базы-периодически-падает)
   1. [Как обезопасить приложение от тяжёлых миграций, приводящих к блокированию запросов?](#Как-обезопасить-приложение-от-тяжёлых-миграций-приводящих-к-блокированию-запросов)
   1. [Simple index checking](#Simple-index-checking)
   1. [Как скопировать таблицы из одной базы данных в другую?](#Как-скопировать-таблицы-из-одной-базы-данных-в-другую)

## Проектирование данных

### Использование колонок с типом массив

В PostgreSQL есть тип данных [массив](https://postgrespro.ru/docs/postgresql/10/arrays) с богатым набором [операторов и функций](https://postgrespro.ru/docs/postgresql/10/functions-array) для работы с ним. Для ускорения выполнения запросов, которые используют условие по колонке с типом массив, используется [GIN индекс](https://postgrespro.ru/docs/postgresql/10/indexes-types).

При проектировании таблиц для хранения данных массивы позволяют избавиться от лишних таблиц. Например, необходимо хранить данные по пользователям, где у каждого пользователя может быть несколько адресов электронной почты. Вместо создания вспомогательной таблицы для хранения эл. адресов можно создать колонку emails с типом массив в основной таблице. Если необходимо, чтобы все email были уникальны в рамках всех записей по колонке emails, то можно сделать триггер с соответствующим ограничением. TODO - дать пример SQL кода.

## Получение данных

### Строки

#### Агрегатная функция конкатенации строк (аналог [group_concat()](https://dev.mysql.com/doc/refman/5.7/en/group-by-functions.html#function_group-concat) в MySQL)

```sql
SELECT STRING_AGG(DISTINCT s, ', ' ORDER BY s) AS field_alias FROM (VALUES ('b'), ('a'), ('b')) AS t(s); -- a, b

SELECT ARRAY_TO_STRING(ARRAY_AGG(DISTINCT s ORDER BY s), ', ') AS field_alias FROM (VALUES ('b'), ('a'), ('b')) AS t(s); -- a, b
```

#### Как проверить email на валидность?

Регулярное выражение взято и адаптировано [отсюда](https://github.com/rin-nas/regexp-patterns-library/)

```sql
create function is_email(email text)
    returns boolean
    language plpgsql
as $$
BEGIN
    return regexp_match($1, $REGEXP$
^
(?<![-!#$%&'*+/=?^_`{|}~@."\]\\a-zA-Zа-яА-ЯёЁ\d])
(?:
    [-!#$%&'*+/=?^_`{|}~a-zA-Z\d]+
  | [-!#$%&'*+/=?^_`{|}~а-яА-ЯёЁ\d]+
  | "(?:(?:[^"\\]|\\.)+)"
)
(?:
  \.
  (?:
      [-!#$%&'*+/=?^_`{|}~a-zA-Z\d]+
    | [-!#$%&'*+/=?^_`{|}~а-яА-ЯёЁ\d]+
    | "(?:[^"\\]|\\.)+"
  )
)*
@
(?:
    (?:
       (?: #домены 2-го и последующих уровней
         (?!-)
         (?:
             (?:[a-zA-Z\d]|-(?!-)){1,63}
           | (?:[а-яА-ЯёЁ\d]|-(?!-)){1,63}
         )
         (?<!-)
         \.
       )+
       (?:  #домен 1-го уровня
           [a-zA-Z]{2,63}
         | [а-яА-ЯёЁ]{2,63}
       )
    )\M
  | (?: #IPv4
      (?<!\d)
      (?!0+\.)
      (?:1?\d\d?|2(?:[0-4]\d|5[0-5]))(?:\.(?:1?\d\d?|2(?:[0-4]\d|5[0-5]))){3}
      (?!\d)
    )
  | \[ #IPv4 в квадратных скобках
    (?:
      (?<!\d)
      (?!0+\.)
      (?:1?\d\d?|2(?:[0-4]\d|5[0-5]))(?:\.(?:1?\d\d?|2(?:[0-4]\d|5[0-5]))){3}
      (?!\d)
    )
    \]
)
$
$REGEXP$, 'sx') is not null;

END;
$$;

SELECT is_email('test.@domain.com');
```

#### Как [транслитерировать](https://ru.wikipedia.org/wiki/%D0%A2%D1%80%D0%B0%D0%BD%D1%81%D0%BB%D0%B8%D1%82%D0%B5%D1%80%D0%B0%D1%86%D0%B8%D1%8F) русские буквы на английские?

```sql
create or replace function public.slugify(str text)
returns text
language plpgsql
as $$
declare
_out text;
begin
_out := translate(
trim(both ' ' from lower(str)),
'абвгдеёзийклмнопрстуфыэ',
'abvgdeeziyklmnoprstufye'
);
_out := replace(_out, 'ж', 'zh');
_out := replace(_out, 'х', 'kh');
_out := replace(_out, 'ц', 'ts');
_out := replace(_out, 'ч', 'ch');
_out := replace(_out, 'ш', 'sh');
_out := replace(_out, 'щ', 'sch');
_out := replace(_out, 'ь', '');
_out := replace(_out, 'ъ', '');
_out := replace(_out, 'ю', 'yu');
_out := replace(_out, 'я', 'ya');
_out := regexp_replace(_out, '[^a-z0-9]+', '-', 'g');
return _out;
end
$$;
```

#### Как распарсить CSV строку в таблицу?

[Выполнить SQL](https://www.db-fiddle.com/f/eqsGTTqAmH1QoQ8LL63jM/0) или [Выполнить SQL](http://sqlfiddle.postgrespro.ru/#!22/0/6439)
```sql
-- EXPLAIN --ANALYSE
WITH
    -- https://en.wikipedia.org/wiki/Comma-separated_values
    -- https://postgrespro.ru/docs/postgresql/10/sql-copy
    data AS (SELECT -- скопируйте сюда данные в формате CSV
                    ' 501 ; 8300000000000 ; ";Автономный ;"";округ""
  ""Ненецкий"";";test1
                      751;8600800000000; "  Автономный округ ""Ханты-Мансийский"", Район Советский" ;
                     1755;8700300000000;Автономный округ Чукотский, Район Билибинский
                     1725;7501900000000;Край Забайкальский, Район Петровск-Забайкальский

                  ;;
                       711;2302100000000;Край Краснодарский, Район Лабинский
                       729;2401600000000;Край Красноярский, Район Иланский
                       765;2700700000000;Край Хабаровский, Район Вяземский' AS csv),
    options AS (SELECT -- задайте символ, разделяющий столбцы в строках файла,
                       -- возможные вариаты: ';', ',', '\t' (табуляция)
                       ';' AS delimiter),
    prepared AS (SELECT REPLACE('(?: ([^"<delimiter>\r\n]*)         #1
                                   | \x20* ("(?:[^"]+|"")*") \x20*  #2
                                 ) (<delimiter>|[\r\n]+)', '<delimiter>', options.delimiter) AS parse_pattern
                 FROM options),
    parsed AS (
        SELECT * FROM (
            SELECT
                (SELECT ARRAY_AGG(
                    CASE WHEN LENGTH(field) > 1 AND
                              LEFT(field, 1) = '"' AND
                              RIGHT(field, 1) = '"' THEN REPLACE(SUBSTRING(field, 2, LENGTH(field) - 2), '""', '"')
                         ELSE NULLIF(TRIM(field), '')
                    END
                    ORDER BY num)
                 FROM unnest(string_to_array(t.row, E'\x01;\x02')) WITH ORDINALITY AS q(field, num)
                ) AS row
            FROM data, prepared,
                 regexp_split_to_table(
                     regexp_replace(data.csv || E'\n', prepared.parse_pattern, E'\\1\\2\x01\\3\x02', 'gx'),
                     '\x01[\r\n]+\x02'
                 ) AS t(row)
            ) AS t
        WHERE row IS NOT NULL AND array_to_string(row, '') != ''
    )
SELECT
    CASE WHEN row[1] ~ '^\d+$' THEN row[1]::integer ELSE NULL END AS id,
    row[2] AS kladr_id,
    row[3] AS ancestors
FROM parsed
```

#### Как определить пол по ФИО (фамилии, имени, отчеству) на русском языке?

* [gender_by_name.sql](gender_by_name/gender_by_name.sql)
* [tables.sql](gender_by_name/tables.sql)
* [gender_by_ending.csv](gender_by_name/gender_by_ending.csv)
* [person_name_dictionary.csv](gender_by_name/person_name_dictionary.csv)

#### Как заквотировать строку для использования в регулярном выражении?
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

#### Как заквотировать строку для использования в операторе LIKE?
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

### JSON

#### Как получить записи, которые удовлетворяют условиям из JSON массива?

```sql
SELECT * FROM (
    VALUES ('[{"id" : 1, "created_at" : "2003-07-01", "name": "Sony"}, {"id" : 2, "created_at" : "2008-10-27", "name": "Samsung"}]'::jsonb),
           ('[{"id" : 3, "created_at" : "2010-03-30", "name": "LG"},   {"id" : 4, "created_at" : "2018-12-09", "name": "Apple"}]'::jsonb)
) AS t
WHERE EXISTS(
          SELECT *
          FROM jsonb_to_recordset(t.column1) AS x(id int, created_at timestamp, name text)
          WHERE x.id IN (1, 3) AND x.created_at > '2000-01-01' AND name NOT LIKE 'P%'
      )
```

#### Как сравнить 2 JSON и получить отличия?

```sql
CREATE OR REPLACE FUNCTION jsonb_diff(l JSONB, r JSONB) RETURNS JSONB AS $json_diff$
    SELECT jsonb_object_agg(a.key, a.value)
    FROM (SELECT key, value FROM jsonb_each(l)) AS a(key,value)
    LEFT OUTER JOIN (SELECT key, value FROM jsonb_each(r)) b(key,value) ON a.key = b.key
    WHERE a.value != b.value OR b.key IS NULL;
$json_diff$
LANGUAGE sql;

SELECT jsonb_diff('{"a":1,"b":2}'::JSONB, '{"a":1,"b":null}'::JSONB);
```

### Массивы

#### Агрегатная функция конкатенации (объединения) массивов

```sql
CREATE AGGREGATE array_cat_agg(anyarray) (
    SFUNC     = array_cat
   ,STYPE     = anyarray
   ,INITCOND  = '{}'
);
SELECT id,  array_cat_agg(words::text[])
FROM (VALUES
             ('1', '{"foo","bar","zap","bing"}'),
             ('2', '{"foo"}'),
             ('1', '{"bar","zap"}'),
             ('2', '{"bing"}'),
             ('1', '{"bing"}'),
             ('2', '{"foo","bar"}')) AS t(id, words)
GROUP BY id;
```

#### Как получить одинаковые элементы массивов (пересечение массивов)?

```sql
-- для 2-х массивов
select array_agg(a) from unnest(array[1, 2, 3, 4, 5]) a where a = any(array[4, 5, 6, 7, 8]); -- {4,5}

-- для N массивов
select array_agg(a1)
from unnest(array[1, 2, 3, 4, 5]) a1
inner join unnest(array[3, 4, 5, 6, 7]) a2 on a1 = a2
inner join unnest(array[4, 5, 6, 7, 8]) a3 on a1 = a3; -- {4,5}
```

#### Как получить уникальные элементы массива или отсортировать их?

```sql
-- способ 1
SELECT ARRAY_AGG(DISTINCT a ORDER BY a) FROM UNNEST(ARRAY[1,2,3,2,1]) t(a); -- {1,2,3}

-- способ 2
SELECT ARRAY(SELECT DISTINCT UNNEST(ARRAY[1,2,3,2,1]) ORDER BY 1); -- {1,2,3}

-- готовая функция
CREATE FUNCTION array_unique(anyarray) RETURNS anyarray AS $$
SELECT array_agg(DISTINCT x) FROM unnest($1) t(x);
$$ LANGUAGE SQL IMMUTABLE;
```

### Поиск по фразе (точный и неточный)

#### Как найти список строк, совпадающих со списком шаблонов?
```sql
-- было
SELECT *
FROM (VALUES
      ('foo bar zap bing'),
      ('man foo'),
      ('bar zap'),
      ('bing'),
      ('foo bar')) AS t(words)
WHERE words LIKE '%bar%' OR words LIKE '%zap%' OR words LIKE '%fix%' OR words LIKE '%new%';

-- стало
SELECT *
FROM (VALUES
      ('foo bar zap bing'),
      ('man foo'),
      ('bar zap'),
      ('bing'),
      ('foo bar')) AS t(words)
WHERE words LIKE ANY (ARRAY['%bar%', '%zap%', '%fix%', '%new%']);
```

#### Как получить названия сущностей по поисковой фразе с учётом начала слов (поисковые подсказки)?

См. так же [полнотекстовый поиск](https://postgrespro.ru/docs/postgresql/11/textsearch).

```sql
CREATE INDEX /*CONCURRENTLY*/ IF NOT EXISTS t_name_trigram_index ON t USING GIN (lower(name) gin_trgm_ops);

WITH
normalize AS (
    SELECT ltrim(REGEXP_REPLACE(LOWER('бар '), '[^а-яёa-z0-9]+', ' ', 'gi')) AS query
),
vars AS (
    SELECT CONCAT('%', REPLACE(quote_like(trim(normalize.query)), ' ', '_%'), '%') AS query_like,
           CONCAT('(?<![а-яёa-z0-9])', REPLACE(quote_regexp(normalize.query), ' ', '(?:[^а-яёa-z0-9]+|$)')) AS query_regexp
    FROM normalize
)
SELECT 
  t.name,
  lower(t.name) LIKE RTRIM(normalize.query) AS is_leading
FROM t, vars, normalize
WHERE
  length(rtrim(normalize.query)) > 0 -- для скорости
  AND lower(t.name) LIKE vars.query_like -- для скорости
  AND lower(t.name) ~* vars.query_regexp -- для точности
ORDER BY 
  is_leading DESC,
  LENGTH(name), 
  name
LIMIT 100
```

#### Как для слова с опечаткой (ошибкой) получить наиболее подходящие варианты слов для замены (исправление опечаток)?

```sql
CREATE EXTENSION IF NOT EXISTS fuzzymatch;
CREATE EXTENSION IF NOT EXISTS pg_trgm;
 
CREATE INDEX /*CONCURRENTLY*/ IF NOT EXISTS custom_query_group_name_name_trigram_index ON public.custom_query_group_name USING GIN (lower(name) gin_trgm_ops);
CREATE INDEX /*CONCURRENTLY*/ IF NOT EXISTS sphinx_wordforms_word_trigram_index ON public.sphinx_wordforms USING GIN (lower(word) gin_trgm_ops);
 
SELECT COUNT(*) FROM sphinx_wordforms; -- 1,241,939 записей
 
-- drop function typos_correct(text, interval, boolean);

CREATE OR REPLACE FUNCTION typos_correct(
    words    text,
    timeout  interval,
    is_debug bool default false
)
RETURNS TABLE(
    word_num      bigint,
    word_from     text,
    is_mistake    bool,
    can_correct   bool,
    words_to      jsonb,
    words_details json
)
PARALLEL SAFE
ROWS 10
LANGUAGE SQL
STABLE
RETURNS NULL ON NULL INPUT
AS $BODY$
/*
Описание параметров на входе:
    words     Список слов, где разделителем является перенос строки \n.
              Первые 2 строки -- исходная фраза и фраза в другой раскладке клавиатуры.
              Остальные строки содержат по одному слову в исходной и другой раскладке клавиатуры.
    timeout   Максимальное время выполнения, при превышении которого обработка слов прерывается.
              В этом случае для некоторых слов из списка опечатки могут не исправиться.
    is_debug  Режим отладки, при котором возвращается доп. инфа в поле words_details.

Описание колонок таблицы на выходе:
    word_num        Порядковый номер слова из запроса
    word_from       Исходное слово/фраза
    is_mistake      Исходное слово содержит опечатку (не найдено в словарях)?
    can_correct     Можно исправить опечатку?
    words_to        Исправленные слова без опечатки
                    При однозначном исправлении всегда одно слово, иначе несколько
    words_details   Доп. информация в режиме отладки (если входящий параметр is_debug=true)
*/
-- EXPLAIN
WITH
    vars AS (
        -- 0.21 -- это минимум, чтобы исправить "вадитль" на "водитель"
        -- 0.15 -- это минимум, чтобы исправить "уёетчк" на "учетчик" (меньше уже нельзя, а то запрос работает медленно)
        SELECT set_config('pg_trgm.word_similarity_threshold', 0.15::text, TRUE)::real AS word_similarity_threshold,
               set_config('pg_trgm.similarity_threshold', 0.15::text, TRUE)::real AS similarity_threshold,
               string_to_array(words, E'\n')::text[] AS words_from,
               2 AS ins_cost,
               2 AS del_cost,
               1 AS sub_cost
    ),
    words AS (
        SELECT
            lower(q.word_from) AS word_from,
            q.word_num - 1 AS word_num,
            -- есть слово в словаре русского языка?
            NOT EXISTS(
                SELECT 1
                FROM sphinx_wordforms AS dict
                WHERE lower(dict.word) = lower(q.word_from)
                  AND mistake = FALSE
                  AND checked = TRUE
                LIMIT 1
            ) AND
            -- есть слово в названиях профессий?
            NOT EXISTS(
                SELECT 1
                FROM custom_query_group_name AS dict
                WHERE lower(dict.name) = lower(q.word_from)
                LIMIT 1
            ) AS is_mistake
        FROM unnest((SELECT words_from FROM vars)) WITH ORDINALITY AS q(word_from, word_num)
    )
    -- SELECT * FROM words_from; -- для отладки
    , result AS (
        SELECT *,
           to_jsonb(ARRAY((
               WITH t AS (
                   SELECT *,
                          round(extract(seconds FROM clock_timestamp() - now())::numeric, 4) AS execution_time,
                          ROW_NUMBER() OVER w AS position,
                          levenshtein_rank3 - LEAD(levenshtein_rank3) OVER w AS next_levenshtein_rank3_delta
                   FROM (
                            -- нельзя выносить подзапрос в WITH name AS (SELECT ...),
                            -- т.к. план запроса меняется, итоговый запрос выполняется в 2 раза медленнее!
                            SELECT q.word_num,
                                   q.word_from,
                                   t.name AS word_to,
                                   round(word_similarity(q.word_from, t.name)::numeric, 4) AS word_similarity_rank,
                                   round(similarity(q.word_from, t.name)::numeric, 4)      AS similarity_rank,
                                   levenshtein(q.word_from, t.name)                                             AS levenshtein_distance1,
                                   levenshtein(q.word_from, t.name, vars.ins_cost, vars.del_cost,vars.sub_cost) AS levenshtein_distance2,
                                   round(sqrt(levenshtein(q.word_from, t.name) *
                                              levenshtein(q.word_from, t.name, vars.ins_cost, vars.del_cost, vars.sub_cost))::numeric, 4) AS levenshtein_distance3, -- среднее геометрическое
                                   round((1 - sqrt(levenshtein(q.word_from, t.name) *
                                                   levenshtein(q.word_from, t.name, vars.ins_cost, vars.del_cost, vars.sub_cost)) / length(t.name))::numeric, 4) AS levenshtein_rank3
                            FROM custom_query_group_name AS t, vars
                            WHERE lower(t.name) % q.word_from -- используем GIN индекс!
                        ) AS t
                   WHERE TRUE
                     AND levenshtein_distance1 < 5 AND levenshtein_rank3 > 0.55
                       WINDOW w AS (ORDER BY levenshtein_distance1 ASC,
                           levenshtein_rank3 DESC,
                           word_similarity_rank DESC,
                           similarity_rank DESC)
                   ORDER BY levenshtein_distance1 ASC,
                            levenshtein_rank3 DESC,
                            word_similarity_rank DESC,
                            similarity_rank DESC
                   LIMIT 3
                   --LIMIT 10 -- для отладки
                   )
                   SELECT to_jsonb(tt.*) FROM (
                      SELECT *,
                             -- если у нескольких кандидатов подряд рейтинг отличается незначительно,
                             -- то это не точное исправление (автоисправлять нельзя, только предлагать варианты)
                             position = 1
                                 AND (next_levenshtein_rank3_delta IS NULL OR
                                 -- 0.03 -- это минимум, чтобы исправить "онолитик" на "аналитик"
                                 next_levenshtein_rank3_delta > 0.03) AS can_correct
                      FROM t
                      LIMIT 3
                      --LIMIT 10 -- для отладки
                   ) AS tt
        ))) AS json
    FROM words AS q
    WHERE clock_timestamp() - now() < timeout -- ограничиваем время выполнения запроса!
      AND q.is_mistake = TRUE
      -- первые 2 элемента -- это всегда исходный текст и текст в другой раскладке клавиатуры
      -- если один из этих элементов не является опечаткой, то прерываем цикл
      AND NOT EXISTS(SELECT * FROM words AS s WHERE s.word_num < 2 AND s.is_mistake = FALSE)
      -- если все отдельные слова не имеют опечаток, то прерываем цикл
      AND (SELECT COUNT(*) = 2 OR (COUNT(*) - 2) / 2 != COUNT(*) FILTER (WHERE s.word_num >= 2 AND s.is_mistake = FALSE) FROM words AS s)
    ORDER BY word_num ASC
)
SELECT w.word_num,
       w.word_from,
       w.is_mistake,
       COALESCE(r.json->0->>'can_correct' = 'true', FALSE) AS can_correct,
       CASE
           WHEN r.json->0->>'can_correct' = 'true' THEN to_jsonb(ARRAY[r.json->0->>'word_to'])
           ELSE (SELECT jsonb_agg(o->'word_to') FROM jsonb_array_elements(json) AS t(o))
       END AS words_to,
       CASE WHEN is_debug THEN jsonb_pretty(json)::json ELSE NULL END AS words_details
FROM words AS w
LEFT JOIN result AS r ON r.word_num = w.word_num
ORDER BY w.word_num
$BODY$;

-- Тестирование. Если какой-либо запрос не выполнится, то мы увидим текст ошибки.
--EXPLAIN
SELECT * FROM typos_correct(E'повар-пивовар\ngjdfh-gbdjdfh\nповар\nпивовар\ngjdfh\ngbdjdfh', '200ms'::interval, true);
SELECT * FROM typos_correct(E'бухалтер\n,e[fknth', '200ms'::interval, true);
SELECT * FROM typos_correct(E'моляр\nvjkzh', '200ms'::interval, true);
SELECT * FROM typos_correct(E'моляр\nvjkzh', '200ms'::interval, false);
SELECT * FROM typos_correct(E'моляр\nvjkzh', '200ms'::interval);
```
**Пример результата запроса**

word_num|word_from|is_mistake|can_correct|words_to|words_details
-------:|:--------|:---------|:----------|:-------------|:-------------
1 |вадитль|true|true|\["водитель"]|NULL
2 |дифектолог|true|false|\["дефектолог", "директолог", "диетолог"]|NULL
3 |формовшица|true|true|\["формовщица"]|NULL
4 |фрмовщица|true|true|\["формовщица"]|NULL
5 |бхугалтер|true|true|\["бухгалтер"]|NULL
6 |лктор|true|true|\["лектор"]|NULL
7 |дикто|true|true|\["диктор"]|NULL
8 |вра|true|true|\["врач"]|NULL
9 |прагромист|true|true|\["программист"]|NULL
10|затейник|false|false|NULL|NULL
11|смотритель|false|false|NULL|NULL
12|unknown|true|false|NULL|NULL

**Описание запроса**
1. Запрос так же подходит для получения поисковых подсказок (с учётом начала слов), если его немного модернизировать. Практики пока нет, а в теории нужно убрать ограничение по дистанции Левенштейна.
1. Запрос использует GIN индекс, поэтому работает быстро.
1. Среди пользователей, которые делают опечатки, есть те, которые делают грамматические ошибки. Поэтому, при расчёте расстояния Левенштейна, цена вставки и удаления буквы должна быть выше, чем замены. Цены операций являеются целочисленными числами, которые нам не очень подходят, поэтому приходится делать дополнительный расчёт.
1. Пороговые значения подобраны опытным путём.
1. Если у нескольких кандидатов подряд рейтинг отличается незначительно, то это не точное исправление (автоисправлять нельзя, только предлагать варианты)

Алгоритм исправления ошибок и опечаток основан поиске совпадающих триграмм (учитывается "похожесть" слова) и на вычислении расстояния [Левенштейна](https://ru.wikipedia.org/wiki/Расстояние_Левенштейна).
Точность исправления слова зависит в т.ч. от количества букв в слове.
Получать слова-кандидаты для исправления ошибок необходимо для `R > 0.55` и `D < 5`

Длина слова, букв (L) | Максимальная дистанция Левенштейна (D) | Доля R = (1 − (D ÷ L))
---:|--:|:--
2	|0	|1
3	|1	|0.6666
4	|1	|0.75
5	|2	|0.6
6	|2	|0.6666
7	|3	|0.5714
8	|3	|0.625
9	|3	|0.6666
10	|4	|0.6
11	|4	|0.6363
12	|4	|0.6666
13	|4	|0.6923
14 и более	|4	|0.7142

### Деревья и графы

#### Как получить список названий предков и наследников для каждого узла дерева (на примере регионов)?

![XPath-axes](XPath-axes.png)

```sql
SELECT
    id,
    nlevel(ltree_path) AS level,
    ltree_path AS id_path,
    (SELECT array_agg(st.name ORDER BY nlevel(st.ltree_path)) FROM region AS st WHERE st.ltree_path @> t.ltree_path AND st.ltree_path != t.ltree_path) AS ancestors,
    name AS self,
    (SELECT array_agg(st.name ORDER BY nlevel(st.ltree_path)) FROM region AS st WHERE st.ltree_path <@ t.ltree_path AND st.ltree_path != t.ltree_path) AS descendants
    --, t.*
FROM region AS t
WHERE nlevel(ltree_path) >= 2
ORDER BY nlevel(ltree_path) ASC, ancestors
LIMIT 1000;
```

#### Как получить циклические связи в графе?

```sql
WITH paths_with_cycle(depth, path) AS (
 WITH RECURSIVE search_graph(parent_id, child_id, depth, path, cycle) AS (
   SELECT g.parent_id, g.child_id, 1,
     ARRAY[g.parent_id],
     false
   FROM custom_query_group_relationship AS g
   UNION ALL
   SELECT g.parent_id, g.child_id, sg.depth + 1,
     path || g.parent_id,
     g.parent_id = ANY(path)
   FROM custom_query_group_relationship AS g, search_graph sg
   WHERE g.parent_id = sg.child_id AND cycle IS FALSE
 )
 SELECT depth, path FROM search_graph WHERE cycle IS TRUE
 ORDER BY depth
)
SELECT DISTINCT path FROM paths_with_cycle
WHERE depth = (SELECT MIN(depth) FROM paths_with_cycle)
```

#### Как защититься от циклических связей в графе?

SQL-запросы `WITH RECURSIVE...` должны иметь [защиту от зацикливания](https://stackoverflow.com/questions/51025607/prevent-infinite-loop-in-recursive-query-in-postgresql)! Когда запрос зациклится, он будет выполняться очень долго, съедая ресурсы БД. А ещё таких запросов будет много. Повезёт, если сработает защита самого PostgreSQL.

#### Как получить названия всех уровней сферы деятельности 4-го уровня?

```sql
SELECT ot1.name AS name_1, ot2.name as name_2, ot3.name as name_3, ot4.id as id
    FROM offer_trade ot4
    INNER JOIN offer_trade ot3 ON ot4.order_tree <@ ot3.order_tree AND nlevel(ot3.order_tree) = 3
    INNER JOIN offer_trade ot2 ON ot4.order_tree <@ ot2.order_tree AND nlevel(ot2.order_tree) = 2
    INNER JOIN offer_trade ot1 ON ot4.order_tree <@ ot1.order_tree AND nlevel(ot1.order_tree) = 1
```

### Оптимизация выполнения запросов

#### Как посмотреть на план выполнения запроса (EXPLAIN) в наглядном графическом виде?

1. [Postgres Explain Visualizer (Pev)](http://tatiyants.com/pev/) is a tool I wrote to make EXPLAIN output easier to grok. It creates a graphical representation of the query plan
1. [PostgreSQL's explain analyze made readable](https://explain.depesz.com/)

#### Как использовать вывод EXPLAIN запроса в другом запросе?

```sql
CREATE OR REPLACE FUNCTION json_explain(
    query TEXT,
    params TEXT[] DEFAULT ARRAY[]::text[]
) RETURNS SETOF JSON AS $$
BEGIN
    RETURN QUERY
    EXECUTE 'EXPLAIN ('
         || ARRAY_TO_STRING(ARRAY_APPEND(params, 'FORMAT JSON'), ',')
         || ')'
         || query;
END
$$ LANGUAGE plpgsql;

SELECT json_explain('SELECT * FROM pg_class', ARRAY['ANALYSE'])->0;
```

#### Как ускорить SELECT запросы c сотнями и тысячами значениями в IN(...)?

[Источник](http://highload.guide/blog/query_performance_postgreSQL.html)

```sql
-- было
SELECT * FROM t WHERE id < 1000 AND val IN(1, ..., 10000);

-- стало (способ 1)
SELECT * FROM t WHERE id IN (VALUES (1), ...(10000)) WHERE id < 1000;

-- стало (способ 2)
SELECT * FROM t JOIN (VALUES (1), ...(10000)) AS v(val) UGING(val) WHERE id < 1000;

```


### Как получить записи-дубликаты по значению полей?

```sql
-- через подзапрос с EXISTS этой же таблицы
SELECT
    ROW_NUMBER() OVER(PARTITION BY d.name ORDER BY d.id ASC) AS duplicate_num, -- номер дубля
    d.*
FROM person AS d
WHERE EXISTS(SELECT 1
             FROM person AS t
             WHERE t.name = d.name -- в идеале на это поле должен стоять индекс
                   -- если нет первичного ключа, замените "id" на "ctid"
                   AND d.id != t.id -- оригинал и дубликаты
                   -- AND d.id > t.id -- только дубликаты
            )
ORDER BY name, duplicate_num
```

```sql
-- получить ID записей, имеющих дубликаты по полю lower(name)
SELECT id_original, unnest(id_doubles) AS id_double
FROM (
    SELECT min(id) AS id_original,
           (array_agg(id order by id))[2:] AS id_doubles
    FROM skill
    GROUP BY lower(name)
    HAVING count(*) > 1
    ORDER BY count(*) DESC
) AS t;
```

```sql
-- получить ID записей, НЕ имеющих дубликаты по полю slugify(name)
SELECT max(id) AS id
FROM region
GROUP BY slugify(name)
HAVING count(*) = 1;
```

```sql
-- получить разные названия населённых пунктов с одинаковыми kladr_id
SELECT ROW_NUMBER() OVER(PARTITION BY kladr_id ORDER BY address ASC) AS duplicate_num, -- номер дубля
       *
FROM (
    SELECT kladr_id,
           unnest(array_agg(address)) AS address
    FROM d
    GROUP BY kladr_id
    HAVING count(*) > 1
) AS t
ORDER BY kladr_id, duplicate_num
```

### Как получить время выполнения запроса в его результате?

```sql
SELECT extract(seconds FROM clock_timestamp() - now()) AS execution_time FROM pg_sleep(1.5);
```

### Как разбить большую таблицу по N тысяч записей, получив диапазоны id?

Цель разбиения — уменьшить кол-во блокируемых записей при конкурентном доступе.

Применение:

1. индексирование данных в поисковых движках типа Sphinx, Solr, Elastic Search
2. ускорение выполнения запросов в PostgreSQL через их [распараллеливание](https://m.habr.com/company/lanit/blog/351160/)

```sql
WITH
-- отфильтровываем лишние записи и оставляем только колонку id
result1 AS (
    SELECT id
    FROM resume
    WHERE is_publish_status = TRUE
      AND is_spam = FALSE
),
-- для каждого id получаем номер пачки
result2 AS (
    SELECT
       id,
       ((row_number() OVER (ORDER BY id) - 1) / 100000)::integer AS part
    FROM result1
)
-- группируем по номеру пачки и получаем минимальное и максимальное значение id
SELECT
    MIN(id) AS min_id,
    MAX(id) AS max_id,
    -- ARRAY_AGG(id) AS ids, -- список id в пачке, при необходимости
    COUNT(id) AS total -- кол-во записей в пачке (для отладки, можно закомментировать эту строку)
FROM result2
GROUP BY part
ORDER BY 1;
```

Пример результата выполнения

№ | min_id | max_id | total
--:|--:|--:|--:
1 | 162655 | 6594323 | 100000 
2 | 6594329 | 6974938 | 100000 
3 | 6974949 | 7332884 | 100000 
... |  ... | ... | ... 
83 | 24276878 | 24427703 | 100000 
84 | 24427705 | 24542589 | 77587 

Далее можно последовательно или параллельно выполнять SQL запросы (SELECT, UPDATE) для каждого диапазона, например:

```sql
SELECT *
FROM resume
WHERE id BETWEEN 162655 AND 6594323
  AND is_publish_status = TRUE
  AND is_spam = FALSE;
```
Если условие в фильтрации данных тяжёлое, то лучше выбирать по спискам id для каждого диапазона, например:

```sql
SELECT *
FROM resume
WHERE id IN (/*список id через запятую*/);
```

### Как выполнить следующий SQL запрос, если предыдущий не вернул результат?

```sql
-- how to execute a sql query only if another sql query has no results
WITH r AS (
  SELECT * FROM film WHERE length = 120
)
SELECT * FROM r
UNION ALL
SELECT * FROM film
WHERE length = 130
AND NOT EXISTS (SELECT * FROM r)
```

### Как развернуть запись в набор колонок?

```sql
SELECT (a).*, (b).* -- unnesting the records again
FROM (
    SELECT
         a, -- nesting the first table as record
         b  -- nesting the second table as record
    FROM (VALUES (1, 'q'), (2, 'w')) AS a (id, name),
         (VALUES (7, 'e'), (8, 'r')) AS b (id, name)
) AS t;
```

### Как получить итоговую сумму для каждой записи в одном запросе?

```sql
SELECT
   array_agg(x) over () as frame,
   x,
   sum(x) over () as sum,
   x :: float / sum(x) over () as part
FROM generate_series(1, 4) as t (x);
```

### Как получить возраст по дате рождения?

```sql
SELECT EXTRACT(YEAR FROM age('1977-09-10'::date))
```

### Как получить дату или дату и время в формате ISO-8601?

```sql
-- format date or timestamp to ISO 8601
SELECT trim(both '"' from to_json(birthday)::text),
       trim(both '"' from to_json(created_at)::text)
FROM (
    SELECT '1977-10-09'::date AS birthday, now() AS created_at
) AS t
```

Пример результата выполнения:

birthday   | created_at
--         | --
1977-10-09 | 2019-10-24T13:34:38.858211+00:00


### Как вычислить дистанцию между 2-мя точками на Земле по её поверхности в километрах?

Если есть модуль [earthdistance](https://postgrespro.ru/docs/postgresql/10/earthdistance), то `(point(lon1, lat1) <@> point(lon2, lat2)) * 1.609344 AS distance_km`.
Иначе `gc_dist(lat1, lon1, lat2, lon2) AS distance_km`.

```sql
create or replace function gc_dist(
    lat1 double precision, lon1 double precision,
    lat2 double precision, lon2 double precision
) returns double precision
    language plpgsql
AS $$
    -- https://en.wikipedia.org/wiki/Haversine_formula
    -- http://www.movable-type.co.uk/scripts/latlong.html
    DECLARE R INT = 6371; -- km, https://en.wikipedia.org/wiki/Earth_radius
    DECLARE dLat double precision = (lat2-lat1)*PI()/180;
    DECLARE dLon double precision = (lon2-lon1)*PI()/180;
    DECLARE a double precision = sin(dLat/2) * sin(dLat/2) +
                                 cos(lat1*PI()/180) * cos(lat2*PI()/180) *
                                 sin(dLon/2) * sin(dLon/2);
    DECLARE c double precision = 2 * asin(sqrt(a));
BEGIN
    RETURN R * c;
EXCEPTION
-- если координаты совпадают, то получим исключение, а падать нельзя
WHEN numeric_value_out_of_range
    THEN RETURN 0;
END;
$$;

-- select * from pg_available_extensions where installed_version is not null;

with t as (
    SELECT 37.61556 AS msk_x, 55.75222 AS msk_y, -- координаты центра Москвы
           30.26417 AS spb_x, 59.89444 AS spb_y, -- координаты центра Санкт-Петербурга
           1.609344 AS mile_to_kilometre_ratio
)
select (point(msk_x, msk_y) <@> point(spb_x, spb_y)) * mile_to_kilometre_ratio AS dist1_km,
       gc_dist(msk_y, msk_x, spb_y, spb_x) AS dist2_km
from t;
```
Пример результата выполнения:

dist1_km1 | dist2_km
--:       | --:
633.045646835722 | 633.0469500660282

### Как найти ближайшие населённые пункты относительно заданных координат?

```sql
-- координаты (долготу, широту) лучше сразу хранить не в 2-х отдельных полях, а в одном поле с типом point
create index if not exists region_point_idx on region using gist(point(map_center_x, map_center_y));

--explain
with t as (
    SELECT 37.61556 AS msk_x, 55.75222 AS msk_y, -- координаты центра Москвы
           1.609344 AS mile_to_kilometre_ratio
)
select (point(msk_x, msk_y) <@> point(map_center_x, map_center_y)) * mile_to_kilometre_ratio AS dist_km,
       name
from region, t
order by (select point(msk_x, msk_y) from t) <-> point(map_center_x, map_center_y)
limit 10;
```

См. так же https://tapoueh.org/blog/2018/05/postgresql-data-types-point/

### Как вычислить приблизительный объём данных для результата SELECT запроса?

```sql
SELECT pg_size_pretty(SUM(OCTET_LENGTH(t::text) + 1))
FROM (
    -- сюда нужно поместить ваш запрос, например:
    SELECT * FROM region LIMIT 50000
) AS t
```

## Модификация данных (DML)

### Как добавить или обновить записи одним запросом (UPSERT)?

См. [INSERT... ON CONFLICT DO NOTHING/UPDATE и ROW LEVEL SECURITY](https://habr.com/post/264281/) (Habr)

### Как модифицировать данные в нескольких таблицах и вернуть id затронутых записей в одном запросе?

```sql
WITH
updated AS (
    UPDATE table1
    SET x = 5, y = 6 WHERE z > 7
    RETURNING id
),
inserted AS (
    INSERT INTO table2 (x, y, z) VALUES (5, 7, 10)
    RETURNING id
)
SELECT 'table1_updated' AS action, id
FROM updated
UNION ALL
SELECT 'table2_inserted' AS action, id
FROM inserted;
```

### Как добавить запись с id, значение которого нужно сохранить ещё в другом поле в том же INSERT запросе?

По материалам [Stackoverflow: Reference value of serial column in another column during same INSERT](https://stackoverflow.com/questions/12433075/reference-value-of-serial-column-in-another-column-during-same-insert/12433285). А вообще это ошибка проектирования (нарушение нормальной формы)!

```sql
WITH t AS (
   SELECT nextval(pg_get_serial_sequence('region', 'id')) AS id
)
INSERT INTO region (id, ltree_path, ?r)
SELECT id,
       CAST(?s || '.' || id AS ltree) AS ltree_path,
       ?l
FROM t
RETURNING ltree_path
```

### Как сделать несколько последующих запросов с полученным при вставке id из первого запроса?

```sql
DO $$
DECLARE t1Id integer;
BEGIN
  INSERT INTO t1 (a, b) VALUES ('a', 'b') RETURNING id INTO t1Id;
  INSERT INTO t2 (c, d, t1_id) VALUES ('c', 'd', t1Id);
END $$;
```

### Как модифицировать данные в связанных таблицах одним запросом?

При сохранении сущностей возникает задача сохранить данные не только в основную таблицу БД, но ещё в связанные. В запросе ниже "старые" связи будут удалены, "новые" — добавлены, а существующие останутся без изменений. Счётчики полей id serial зря не увеличатся. Приведён пример сохранения регионов вакансии.

```sql
WITH
    -- у таблицы vacancy_region должен быть уникальный ключ vacancy_id+region_id
    -- сначала удаляем все не переданные (несуществующие) регионы размещения для вакансии
    -- для ?l в конец массива идентификаторов регионов нужно добавить 0, чтобы запросы не сломались
    deleted AS (
        DELETE FROM vacancy_region
        WHERE vacancy_id = ?0
        AND region_id NOT IN (?l1)
        -- AND ROW(region_id, some_field) NOT IN (ROW(3, 'a'), ROW(8, 'b'), ...) -- пример для случая, если уникальный ключ состоит из нескольких полей
        RETURNING id
    ),
    -- потом добавляем все регионы размещения для вакансии
    -- несуществующие id регионов и дубликаты будут проигнорированы, ошибки не будет
    -- select нужен, чтобы запрос не сломался по ограничениям внешний ключей, если в списке region_id есть "леваки", они просто проигнорируются
    inserted AS (
        INSERT INTO vacancy_region (vacancy_id, region_id)
        SELECT ?0 AS vacancy_id, id AS region_id FROM region WHERE id IN (?l1)
        ON CONFLICT DO NOTHING
        RETURNING id
    )
SELECT
    -- последовательность пречисления полей важна: сначала удаление, потом добавление, иначе будет ошибка
    (SELECT COUNT(*) FROM deleted) AS deleted, -- количество удалённых записей
    (SELECT COUNT(*) FROM inserted) AS updated -- количество добавленных записей
```

### Как обновить запись так, чтобы не затереть чужие изменения, уже сделанные кем-то?
```sql
WITH u AS (
    UPDATE t 
    SET description = 'new text' 
    WHERE id=123 
    AND updated_at = '2019-11-08 00:58:33'
    --AND md5(t::text) = '1BC29B36F623BA82AAF6724FD3B16718' -- если нет колонки updated_at, вычисляем хеш от всей строки
    RETURNING *
)
SELECT true AS is_updated, updated_at
FROM u
UNION ALL
SELECT false AS is_updated, updated_at
WHERE id = 123 AND NOT EXISTS (SELECT * FROM u)
```

## Модификация схемы данных (DDL)

### Как добавить колонку в существующую таблицу без её блокирования?

См. [Stackoverflow](https://ru.stackoverflow.com/questions/721985/%D0%9A%D0%B0%D0%BA-%D0%B4%D0%BE%D0%B1%D0%B0%D0%B2%D0%B8%D1%82%D1%8C-%D0%BF%D0%BE%D0%BB%D0%B5-%D0%B2-%D0%B1%D0%BE%D0%BB%D1%8C%D1%88%D1%83%D1%8E-%D1%82%D0%B0%D0%B1%D0%BB%D0%B8%D1%86%D1%83-postgresql-%D0%B1%D0%B5%D0%B7-%D0%B1%D0%BB%D0%BE%D0%BA%D0%B8%D1%80%D0%BE%D0%B2%D0%BA%D0%B8) 

TODO — попробовать написать запрос обновления значения поля пачками на SQL, см. [DO](https://postgrespro.ru/docs/postgrespro/9.5/sql-do)

При добавлении в большую таблицу новой колонки со строковым значением вместо типа `VARCHAR(...)` используйте `TEXT`, иначе будет блокировка таблицы!

### Индексы

#### Как сделать ограничение уникальности на колонку в существующей таблице без её блокирования?

Запускать эти запросы нужно НЕ в транзакции, вручную последовательно. Если при выполнении любого запроса произойдёт ошибка, то нужно выполнить все запросы заново.

```sql
-- в случае неудачи построения индекса в конкурентном режиме создаётся "нерабочий" индекс и его нужно удалить
DROP INDEX CONCURRENTLY IF EXISTS person_uniq_auth_id;

-- takes a long time, but doesn’t block queries
CREATE UNIQUE INDEX CONCURRENTLY person_uniq_auth_id ON person (auth_id);

-- blocks queries, but only very briefly
ALTER TABLE person ADD CONSTRAINT person_uniq_auth_id UNIQUE USING INDEX person_uniq_auth_id;
```

#### Как добавить новый индекс в существующую таблицу без её блокирования?

См. [CREATE INDEX CONCURRENTLY](https://www.postgresql.org/docs/9.5/static/sql-createindex.html#SQL-CREATEINDEX-CONCURRENTLY)

#### Как сделать составной уникальный индекс, где одно из полей может быть null?

```sql
create table test (
    a varchar NOT NULL,
    b varchar default null
);

-- решение 1 (Более предпочтительное решение. Если есть внешние ключи на колонки a и b, то дополнительных индексов делать уже не нужно)
create unique index on test (b, a) where b is not null;
create unique index on test (a) where b is null;

-- решение 2 (Менее предпочтительное решение, т.к. есть зависимость от типа данных, но один индекс компактнее двух)
create unique index on test(a, coalesce(b, '')) -- для чисел вместо '' напишите 0
```

#### Как починить сломаный уникальный индекс, имеющий дубликаты?

Чиним битый уникальный индекс на поле `skill.name`

```sql
-- EXPLAIN
WITH
skill AS (
   SELECT min(id) AS id_original,
          (array_agg(id order by id))[2:] AS id_doubles
   FROM skill
   GROUP BY lower(name)
   HAVING count(*) > 1
),

repair_resume_work_skill AS (
    -- собираем связи с дублями в таблицу
    SELECT t.resume_id, t.work_skill_id AS id_double, skill.id_original
    FROM skill
    INNER JOIN resume_work_skill AS t ON t.work_skill_id = ANY (skill.id_doubles)
),
deleted_resume_work_skill AS (
   -- удаляем связи с дублями из таблицы
   DELETE FROM resume_work_skill
   USING repair_resume_work_skill AS t
   WHERE resume_work_skill.resume_id = t.resume_id
     AND resume_work_skill.work_skill_id = t.id_double
   RETURNING id
),
inserted_resume_work_skill AS (
   -- добавляем новые правильные связи, при этом такая связь уже может существовать
   INSERT INTO resume_work_skill (resume_id, work_skill_id)
   SELECT t.resume_id, t.id_original FROM repair_resume_work_skill AS t
   ON CONFLICT DO NOTHING
   RETURNING id
),

-- удаляем дубликаты
deleted_skill AS (
   DELETE FROM skill
   USING skill AS t
   WHERE skill.id = ANY (t.id_doubles)
   RETURNING id
)

         SELECT 'resume_work_skill' AS table_name, 'deleted'  AS action, COUNT(*) FROM deleted_resume_work_skill
UNION ALL SELECT 'resume_work_skill' AS table_name, 'inserted' AS action, COUNT(*) FROM inserted_resume_work_skill

UNION ALL SELECT 'skill' AS table_name, 'deleted' AS action, COUNT(*) FROM deleted_skill
;

-- удаляем битый индекс и создаём новый уникальный индекс
DROP INDEX IF EXISTS skill.uniq_skill_name;
CREATE UNIQUE INDEX IF NOT EXISTS uniq_skill_name ON skill (lower(name));
```

#### Как временно отключить индекс?

Способ 1
```sql
--Is it possible to temporarily disable an index in Postgres?
update pg_index set indisvalid = false where indexrelid = 'test_pkey'::regclass
```

Способ 2
```sql
begin;
drop index foo_ndx;
explain analyze select * from foo;
rollback;
```

#### Как сделать компактный уникальный индекс на текстовое поле?
```sql
-- для поля с типом TEXT
-- md5, приведённый к типу uuid занимает 16 байт вместо 36 (32+4) байт
create unique index on table_name (cast(md5(lower(column_name)) as uuid));

-- для поля с типом TEXT
-- в этом индексе будут учитываться слова (буквы, цифры, точка, дефис) и их позиции в тексте, 
-- но не будет учитываться регистр слов и любые другие символы
create unique index on table_name (cast(md5(cast(to_tsvector('simple', column_name) as text)) as uuid));

-- для поля с типом JSONB
create unique index on partner__partners (cast(md5(lower(cast(column_name as text))) as uuid));
```

## Администрирование

### Как получить список процессов (SQL запросов), выполняющихся сейчас?
В PHPStorm есть возможность настроить для результата запроса значения в колонке `application_name`и вписать туда ПО и свою фамилию для своих SQL запросов. Для этого нужно открыть окно "Data Sources and Drivers", выбрать нужное соединение с БД из секции "Project Data Sources", перейти на вкладку "Advanced", отсортировать таблицу по колонке "Name", для "Name" равному "Application Name", изменить значение в колонке "Value" на что-то типа"PhpStorm Petrov Ivan" (строго на английском языке).

```sql
SELECT pid, application_name, query, NOW() - query_start AS elapsed
FROM pg_stat_activity
ORDER BY elapsed DESC;
```

### Как остановить или завершить работу процессов?

```sql
-- Остановить все процессы, работающие более 1 часа, сигналом SIGINT
SELECT pg_cancel_backend(pid), application_name, query, NOW() - query_start AS elapsed
FROM pg_stat_activity
WHERE NOW() - query_start > (60*60)::text::interval
ORDER BY elapsed DESC

-- Принудительно завершить работу всех процессов, работающих более 1 часа, сигналом SIGTERM, если не помогает SIGINT
SELECT pg_terminate_backend(pid), application_name, query, NOW() - query_start AS elapsed
FROM pg_stat_activity
WHERE NOW() - query_start > (60*60)::text::interval
ORDER BY elapsed DESC
```

### Как получить список всех функций БД, включая триггерные процедуры?

```sql
SELECT n.nspname AS "Schema",
       p.proname AS "Name",
       CASE WHEN p.proretset THEN 'setof ' ELSE '' END
       || pg_catalog.format_type(p.prorettype, NULL) AS "Result data type",
       CASE WHEN proallargtypes IS NOT NULL
           THEN pg_catalog.array_to_string(
               ARRAY(SELECT CASE
                            WHEN p.proargmodes[s.i] = 'i' THEN ''
                            WHEN p.proargmodes[s.i] = 'o' THEN 'OUT '
                            WHEN p.proargmodes[s.i] = 'b' THEN 'INOUT '
                            END || CASE
                                   WHEN COALESCE(p.proargnames[s.i], '') = '' THEN ''
                                   ELSE p.proargnames[s.i] || ' '
                                   END || pg_catalog.format_type(p.proallargtypes[s.i], NULL)
                     FROM
                                 pg_catalog.generate_series(1, pg_catalog.array_upper(p.proallargtypes, 1)) AS s(i)
               ), ', '
           ) ELSE pg_catalog.array_to_string(
           ARRAY(SELECT CASE
                        WHEN COALESCE(p.proargnames[s.i+1], '') = '' THEN ''
                        ELSE p.proargnames[s.i+1] || ' '
                        END || pg_catalog.format_type(p.proargtypes[s.i], NULL)
                 FROM
                             pg_catalog.generate_series(0, pg_catalog.array_upper(p.proargtypes, 1)) AS s(i)
           ), ', '
       )
       END AS "Argument data types",
       CASE WHEN p.provolatile = 'i' THEN 'immutable'
       WHEN p.provolatile = 's' THEN 'stable'
       WHEN p.provolatile = 'v' THEN 'volatile'
       END AS "Volatility",
       r.rolname AS "Owner",
       l.lanname AS "Language",
       p.prosrc AS "Source code",
       pg_catalog.obj_description(p.oid, 'pg_proc') AS "Description"
FROM pg_catalog.pg_proc p
    LEFT JOIN pg_catalog.pg_namespace n ON n.oid = p.pronamespace
    LEFT JOIN pg_catalog.pg_language l ON l.oid = p.prolang
    JOIN pg_catalog.pg_roles r ON r.oid = p.proowner
WHERE p.prorettype <> 'pg_catalog.cstring'::pg_catalog.regtype
      AND (p.proargtypes[0] IS NULL
           OR p.proargtypes[0] <> 'pg_catalog.cstring'::pg_catalog.regtype)
      AND NOT p.proisagg
      AND pg_catalog.pg_function_is_visible(p.oid)
      AND r.rolname <> 'pgsql';
```

### Как получить список всех зависимостей (внешних ключей) между таблицами БД?

Запрос возвращает колонки `from_table`, `from_cols`, `to_table`, `to_cols` и другие.

Для какой-либо таблицы можно получить:

* список исходящих связей (таблицы, которые зависят от текущей таблицы)
* список входящих связей (таблицы, от которых зависит текущая таблица)

[Источник](https://stackoverflow.com/questions/1152260/postgres-sql-to-list-table-foreign-keys/36800049#36800049)

```sql
SELECT
    c.conname AS constraint_name,
    (SELECT n.nspname FROM pg_namespace AS n WHERE n.oid=c.connamespace) AS constraint_schema,

    tf.name AS from_table,
    (
        SELECT STRING_AGG(QUOTE_IDENT(a.attname), ', ' ORDER BY t.seq)
        FROM
            (
                SELECT
                    ROW_NUMBER() OVER (ROWS UNBOUNDED PRECEDING) AS seq,
                    attnum
                FROM UNNEST(c.conkey) AS t(attnum)
            ) AS t
            INNER JOIN pg_attribute AS a ON a.attrelid=c.conrelid AND a.attnum=t.attnum
    ) AS from_cols,

    tt.name AS to_table,
    (
        SELECT STRING_AGG(QUOTE_IDENT(a.attname), ', ' ORDER BY t.seq)
        FROM
            (
                SELECT
                    ROW_NUMBER() OVER (ROWS UNBOUNDED PRECEDING) AS seq,
                    attnum
                FROM UNNEST(c.confkey) AS t(attnum)
            ) AS t
            INNER JOIN pg_attribute AS a ON a.attrelid=c.confrelid AND a.attnum=t.attnum
    ) AS to_cols,

    CASE confupdtype WHEN 'r' THEN 'restrict' WHEN 'c' THEN 'cascade' WHEN 'n' THEN 'set null' WHEN 'd' THEN 'set default' WHEN 'a' THEN 'no action' ELSE NULL END AS on_update,
    CASE confdeltype WHEN 'r' THEN 'restrict' WHEN 'c' THEN 'cascade' WHEN 'n' THEN 'set null' WHEN 'd' THEN 'set default' WHEN 'a' THEN 'no action' ELSE NULL END AS on_delete,
    CASE confmatchtype::text WHEN 'f' THEN 'full' WHEN 'p' THEN 'partial' WHEN 'u' THEN 'simple' WHEN 's' THEN 'simple' ELSE NULL END AS match_type,  -- In earlier postgres docs, simple was 'u'nspecified, but current versions use 's'imple.  text cast is required.

    pg_catalog.pg_get_constraintdef(c.oid, true) as condef
FROM
    pg_catalog.pg_constraint AS c
    INNER JOIN (
                   SELECT pg_class.oid, QUOTE_IDENT(pg_namespace.nspname) || '.' || QUOTE_IDENT(pg_class.relname) AS name
                   FROM pg_class INNER JOIN pg_namespace ON pg_class.relnamespace=pg_namespace.oid
               ) AS tf ON tf.oid=c.conrelid
    INNER JOIN (
                   SELECT pg_class.oid, QUOTE_IDENT(pg_namespace.nspname) || '.' || QUOTE_IDENT(pg_class.relname) AS name
                   FROM pg_class INNER JOIN pg_namespace ON pg_class.relnamespace=pg_namespace.oid
               ) AS tt ON tt.oid=c.confrelid
WHERE c.contype = 'f' ORDER BY 1;
```

### Как получить статистику использования индексов?

Запрос отображает использование индексов. Что позволяет увидеть наиболее часто использованные индексы, а также и наиболее редко (у которых будет index_scans_count = 0).

Учитываются только пользовательские индексы и не учитываются уникальные, т.к. они используются как ограничения (как часть логики хранения данных).

В начале отображаются наиболее часто используемые индексы (отсортированы по колонке index_scans_count)

```sql
SELECT
    idstat.relname                            AS table_name,                  -- имя таблицы
    indexrelname                            AS index_name,                  -- индекс
    idstat.idx_scan                                AS index_scans_count,           -- число сканирований по этому индексу
    pg_size_pretty(pg_relation_size(indexrelid))        AS index_size,                  -- размер индекса
    tabstat.idx_scan                        AS table_reads_index_count,     -- индексных чтений по таблице
    tabstat.seq_scan                        AS table_reads_seq_count,       -- последовательных чтений по таблице
    tabstat.seq_scan + tabstat.idx_scan                AS table_reads_count,           -- чтений по таблице
    n_tup_upd + n_tup_ins + n_tup_del                AS table_writes_count,          -- операций записи
    pg_size_pretty(pg_relation_size(idstat.relid))      AS table_size                   -- размер таблицы
FROM
    pg_stat_user_indexes                        AS idstat
JOIN
    pg_indexes
    ON
    indexrelname = indexname
    AND
    idstat.schemaname = pg_indexes.schemaname
JOIN
    pg_stat_user_tables                        AS tabstat
    ON
    idstat.relid = tabstat.relid
WHERE
    indexdef !~* 'unique'
ORDER BY
    idstat.idx_scan DESC,
    pg_relation_size(indexrelid) DESC
```

### Как получить список установленных расширений (extensions)?

```sql
select * from pg_available_extensions where installed_version is not null;
```

### Как получить список таблиц с размером занимаемого места?

```sql
SELECT nspname || '.' || relname AS "relation",
       pg_size_pretty(pg_total_relation_size(C.oid)) AS "total_size"
FROM pg_class C
  LEFT JOIN pg_namespace N ON (N.oid = C.relnamespace)
WHERE nspname NOT IN ('pg_catalog', 'information_schema')
      AND C.relkind <> 'i'
      AND nspname !~ '^pg_toast'
ORDER BY pg_total_relation_size(C.oid) DESC
LIMIT 100
```

### Как получить и изменить значения параметров конфигурации выполнения?

#### получение значений параметров

```sql
-- способ 1
SHOW pg_trgm.word_similarity_threshold;
SHOW pg_trgm.similarity_threshold;

-- способ 2
SELECT name, setting AS value
FROM pg_settings
WHERE name IN ('pg_trgm.word_similarity_threshold', 'pg_trgm.similarity_threshold');

-- способ 3
SELECT current_setting('pg_trgm.word_similarity_threshold'), current_setting('pg_trgm.similarity_threshold');
```

#### изменение значений параметров
```sql
-- способ 1
SET pg_trgm.similarity_threshold = 0.3;
SET pg_trgm.word_similarity_threshold = 0.3;

-- способ 2
SELECT set_config('pg_trgm.word_similarity_threshold', 0.2::text, FALSE),
       set_config('pg_trgm.similarity_threshold', 0.2::text, FALSE);
```

### Как получить все активные в данный момент процессы автовакуумa и время их работы?

Вакуумирование — важная процедура поддержания хорошей работоспособности вашей базы.
Если вы видите, что автовакуум процессы всё время работают, это значит что они не успевают за количеством изменений в системе. А это в свою очередь сигнал того что надо срочно принимать меры, иначе есть большой риск “распухания” таблиц и индексов — ситуация когда физический размер объектов в базе очень большой, а при этом полезной информации там в разы меньше.

[Источник](https://dataegret.ru/#_autovacuumWorkers)

```
SELECT (clock_timestamp() - xact_start) AS ts_age,
state, pid, query FROM pg_stat_activity
WHERE query ilike '%autovacuum%' AND NOT pid=pg_backend_pid()
```

### Как узнать, почему время ответа от базы периодически падает?

При неправильно настроенных контрольных точках база будет генерировать избыточную дисковую нагрузку. Это будет происходить с высокой частотой, что будет замедлять общее время отклика системы и базы данных.
Для того, чтобы понять правильность настройки, надо обратить внимание на следующие отклонения в поведении базы данных:
в мониторинге приложения или базы будут видны пики во времени ответа, с хорошо прослеживаемой периодичностью;
в моменты "пиков" в логе базы будет отслеживаться большое количество медленных запросов (в случае если логирование таких запросов настроено).

Запрос покажет статистику по контрольным точкам с момента, когда она в последний раз обнулялась. Важными показателями будут минуты между контрольными точками и объем записываемой информации.
Большое кол-во данных за короткое время — это серьезная нагрузка на систему ввода-вывода. Если это ваш случай, то ситуацию нужно однозначно менять!

[Источник](https://dataegret.ru/#_timeDropsDown)

```sql
SELECT now()-pg_postmaster_start_time() "Uptime",
now()-stats_reset "Minutes since stats reset",
round(100.0*checkpoints_req/checkpoints,1) "Forced
checkpoint ratio (%)",
round(min_since_reset/checkpoints,2) "Minutes between
checkpoints",
round(checkpoint_write_time::numeric/(checkpoints*1000),2) "Average
write time per checkpoint (s)",
round(checkpoint_sync_time::numeric/(checkpoints*1000),2) "Average
sync time per checkpoint (s)",
round(total_buffers/pages_per_mb,1) "Total MB written",
round(buffers_checkpoint/(pages_per_mb*checkpoints),2) "MB per
checkpoint",
round(buffers_checkpoint/(pages_per_mb*min_since_reset*60),2)
"Checkpoint MBps"
FROM (
SELECT checkpoints_req,
checkpoints_timed + checkpoints_req checkpoints,
checkpoint_write_time,
checkpoint_sync_time,
buffers_checkpoint,
buffers_checkpoint + buffers_clean + buffers_backend total_buffers,
stats_reset,
round(extract('epoch' from now() - stats_reset)/60)::numeric
min_since_reset,
(1024.0 * 1024 / (current_setting('block_size')::numeric))pages_per_mb
FROM pg_stat_bgwriter
) bg
```

### Как обезопасить приложение от тяжёлых миграций, приводящих к блокированию запросов?

Вначале каждой миграции, которая выполняется внутри транзакции, нужно изменить настройки конфигурации [`lock_timeout`](https://postgrespro.ru/docs/postgresql/10/runtime-config-client#GUC-LOCK-TIMEOUT) и [`statement_timeout`](https://postgrespro.ru/docs/postgresql/10/runtime-config-client#GUC-STATEMENT-TIMEOUT) командой [SET LOCAL](https://postgrespro.ru/docs/postgresql/10/sql-set).
Действие SET LOCAL продолжается только до конца текущей транзакции, независимо от того, фиксируется она или нет. 
При выполнении такой команды вне блока транзакции выдаётся предупреждение и больше ничего не происходит.

```sql
BEGIN;
SET LOCAL lock_timeout TO '5s';
SET LOCAL statement_timeout TO '30min';

/*
Здесь SQL команды для миграции
*/

COMMIT;
```
Если какие-либо запросы в миграции приведут к долгому [блокированию таблиц](https://github.com/dataegret/pg-utils/blob/master/sql/locktree.sql), то транзакция с миграцией откатится, а ваши пользователи не пострадают.
Если транзакция откатится, то есть 2 варианта: запустить повторно во время меньших нагрузок или оптимизировать код миграции, чтобы свести к минимуму блокировки.

Возможно, есть смысл выставить настройку `lock_timeout = '60s'` прямо в postgresql.conf.
Если что-то пойдёт не так, то пользователи пострадают недолго, а проблема может решиться автоматически.

### Simple index checking

[Источник и статья по теме](https://www.compose.com/articles/simple-index-checking-for-postgres/)

```sql
with table_stats as (
select psut.relname,
  psut.n_live_tup,
  1.0 * psut.idx_scan / greatest(1, psut.seq_scan + psut.idx_scan) as index_use_ratio
from pg_stat_user_tables psut
order by psut.n_live_tup desc
),
table_io as (
select psiut.relname,
  sum(psiut.heap_blks_read) as table_page_read,
  sum(psiut.heap_blks_hit)  as table_page_hit,
  sum(psiut.heap_blks_hit) / greatest(1, sum(psiut.heap_blks_hit) + sum(psiut.heap_blks_read)) as table_hit_ratio
from pg_statio_user_tables psiut
group by psiut.relname
order by table_page_read desc
),
index_io as (
select psiui.relname,
  psiui.indexrelname,
  sum(psiui.idx_blks_read) as idx_page_read,
  sum(psiui.idx_blks_hit) as idx_page_hit,
  1.0 * sum(psiui.idx_blks_hit) / greatest(1.0, sum(psiui.idx_blks_hit) + sum(psiui.idx_blks_read)) as idx_hit_ratio
from pg_statio_user_indexes psiui
group by psiui.relname, psiui.indexrelname
order by sum(psiui.idx_blks_read) desc
)
select ts.relname, ts.n_live_tup, ts.index_use_ratio,
  ti.table_page_read, ti.table_page_hit, ti.table_hit_ratio,
  ii.indexrelname, ii.idx_page_read, ii.idx_page_hit, ii.idx_hit_ratio
from table_stats ts
left outer join table_io ti
  on ti.relname = ts.relname
left outer join index_io ii
  on ii.relname = ts.relname
order by ti.table_page_read desc, ii.idx_page_read desc
```

### Как скопировать таблицы из одной базы данных в другую?
   
```bash
pg_dump -U postgres -h 127.0.0.1 --exclude-table=_* --dbname={database_src} --schema=public --verbose | psql -U postgres -h 127.0.0.1 --dbname={database_dst} --single-transaction --set ON_ERROR_ROLLBACK=on 2> errors.txt
```
