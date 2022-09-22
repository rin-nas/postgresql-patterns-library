# ✅ Валидатор схемы БД PostgreSQL

## Цель

Поддержание заданного уровня качества БД: скорости работы SQL запросов c целостностью данных и наличия документации

## Применение

* Валидация схемы БД после автоматического тестирования наката миграции БД
* Валидация схемы БД после автоматического тестирования отката миграции БД


## Описание работы

Валидатор представляет из себя [функцию](functions/db_validate_v2.sql) в БД PostgreSQL 12+.

Запуск:

```sql
select db_validate_v2(
    --'{has_pk_uk,has_not_redundant_index,has_index_for_fk}', --some checks
    null, --all checks

    null, --schemas_ignore_regexp
    '{unused,migration,test}', --schemas_ignore

    '(?<![a-z\d])(te?mp|test|unused|backups?|deleted)(?![a-z\d])', --tables_ignore_regexp
    null --tables_ignore
);
```

Функция проверяет текущую БД на наличие проблем. Никаких данных не возвращается. Если проблемы не найдены, функция успешно завершает работу, иначе возвращается ошибка (исключение в терминах PL/PgSQL): текст ошибки и рекомендации по исправлению.

Рекомендуется вызвать функцию в одной транзакции до и после накатывания миграции на тестовой БД. Если до применения миграции ошибок нет, а после есть, значит причина в миграции БД.

## Проверки

<table class="relative-table wrapped" style="width: 100.0%;">
    <colgroup><col /><col /><col style="width: 16.2491%;" /><col style="width: 17.7945%;" /><col style="width: 51.5393%;" /></colgroup>
<tbody>
<tr>
    <th class="numberingColumn">№</th>
    <th colspan="1">В какой версии сделано</th>
    <th colspan="1">Код проверки</th>
    <th>Название проверки</th>
    <th>Назначение (обоснование) проверки</th>
</tr>
<tr>
    <td class="numberingColumn">1</td>
    <td colspan="1">v1</td>
    <td colspan="1"><code>has_pk_uk</code></td>
    <td>
        <p>Наличие первичного или уникального индекса в таблице</p>
    </td>
    <td>
        <p>Первичный индекс (PK) позволяет</p>
        <ul>
            <li>однозначно идентифицировать запись таблицы БД</li>
            <li>получить очень быстрый доступ к записи</li>
        </ul>
        <p>Уникальный индекс (UK) позволяет исключить дубликаты.</p>
        <p>Без PK или UK невозможно сделать логическую репликацию.</p>
    </td>
</tr>
<tr>
    <td class="numberingColumn">2</td>
    <td colspan="1">v1</td>
    <td colspan="1"><code>has_not_redundant_index</code></td>
    <td>
        <p>Отсутствие избыточных индексов в таблице</p></td>
    <td>
    <p>Если есть составной индекс на поля col1 и col2 (именно в такой последовательности), то отдельный индекс на поле col1 не нужен, он <span style="letter-spacing: 0.0px;">избыточный. Лишние индексы занимают место на диске и замедляют DML запросы.</span></p></td>
</tr>
<tr>
    <td class="numberingColumn">3</td>
    <td colspan="1">v2</td>
    <td colspan="1"><code>has_index_for_fk</code></td>
    <td colspan="1">
    <p>Наличие индексов для ограничений внешних ключей в таблице</p></td>
    <td colspan="1">Без индексов на ограничения внешних ключей (FK) могут работать медленно элементарные запросы типа <strong><code>DELETE FROM {table} WHERE id=&lt;id&gt;</code></strong> из-за ссылающихся на <code>{table}</code> таблиц по FK без индекса.</td>
</tr>
<tr>
    <td class="numberingColumn">4</td>
    <td colspan="1">v2</td>
    <td colspan="1"><code>has_table_comment</code></td>
    <td colspan="1">Наличие описания для таблицы</td>
    <td colspan="1">На этапе проектирования описание помогает лучше понять назначение таблицы и на сколько удачно она названа исходя из описания.
                    В дальнейшем тандем названия и описания упрощают понимание и поддержку кода. Порог входа для новых IT специалистов (разработчиков, тестировщиков, бизнес- и системных аналитиков) уменьшается.
                    Значение в <strong><code>COMMENT ON TABLE {table}</code></strong> не должно быть пустым и не должно совпадать с названием таблицы.
                    Таблицы-секции из проверки исключаются.
    </td>
</tr>
<tr>
    <td class="numberingColumn">5</td>
    <td colspan="1">v2</td>
    <td colspan="1"><code>has_column_comment</code></td>
    <td colspan="1">Наличие описания для колонки</td>
    <td colspan="1">На этапе проектирования описание помогает лучше понять назначение колонки и на сколько удачно она названа исходя из описания.
                    В дальнейшем тандем названия и описания упрощают понимание и поддержку кода. Порог входа для новых IT специалистов (разработчиков, тестировщиков, бизнес- и системных аналитиков) уменьшается.
                    Значение в <strong><code>COMMENT ON TABLE {table}.{column}</code></strong> не должно быть пустым и не должно совпадать с названием колонки.
                    Колонки с названием <strong><code>id</code></strong> из проверки исключаются.
                    Таблицы-секции из проверки исключаются.
    </td>
</tr>
</tbody>
</table>

## TODO

1. Добавить проверку наличия описаний (`comment on ...`) для представлений (view), типов, функций, процедур. В миграциях БД забывают это делать.
1. Добавить проверку именования последовательностей по шаблону `{table}_id_seq`. Некоторые фреймворки закладываются на эти названия.
1. Добавить проверку отсутствия возможности записать `null` или пустую строку в текстовую колонку (когда нет ни одного ограничения типа `check` на колонку), д.б. только 1 способ
1. Добавить проверку отсутствия дубликатов ограничений таблицы (`has_not_duplicate_constraint`):
```sql
with s as (
   SELECT con.conrelid::regclass                                                   as table_name,
          array_length(array_agg(pg_get_constraintdef(con.oid, true)), 1)          as def_count,
          array_length(array_agg(distinct pg_get_constraintdef(con.oid, true)), 1) as def_uniq_count,
          array_agg(pg_get_constraintdef(con.oid, true)) as def
   FROM pg_constraint as con
   WHERE connamespace::regnamespace not in ('pg_catalog', 'information_schema')
     and con.conrelid != 0
   GROUP BY con.conrelid::regclass
)
select s.table_name, t.*
from s
cross join lateral (
    select u.value,
           count(*) as duplicate_count
    from unnest(s.def) as u(value)
    group by u.value
    having count(*) > 1
) as t
where def_count != def_uniq_count;
```
