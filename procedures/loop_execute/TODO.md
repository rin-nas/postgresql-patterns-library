# TODO

1. Добавить автотесты
1. https://github.com/theory/pgtap/blob/master/tools/parallel_conn.sh
1. Избавиться от последнего запроса, который всегда возвращает `0 affected rows`
   Если affected rows < $2, то нужно прервать цикл (см. REV-1419)
1. Принудительно выключить последовательное сканирование таблиц через `SET enable_seqscan = OFF`?
