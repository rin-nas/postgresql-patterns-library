/*
Терминируем заблокированные одинаковые запросы, образующие очередь.

Цель — защита тестовой БД или производственной реплики БД от сбоев из-за ошибок в коде приложений.

Одинаковые запросы могут блокировать друг-друга и образовывать очередь.
Когда кол-во допустимых соединений к БД будет превышено, она принудительно терминирует все запросы и транзакции.
Среди этих запросов могут быть "невиновные" запросы.
Но можно терминировать только проблемные запросы и транзакции.

Запрос необходимо выполнять 1 раз в 15 секунд (например, из крона).

    $ crontab -l
    # m h dom mon dow command
    * * * * *               psql -U postgres --file=/path/to/pg_terminate_backend_lock.sql
    * * * * * ( sleep 15 && psql -U postgres --file=/path/to/pg_terminate_backend_lock.sql )
    * * * * * ( sleep 30 && psql -U postgres --file=/path/to/pg_terminate_backend_lock.sql )
    * * * * * ( sleep 45 && psql -U postgres --file=/path/to/pg_terminate_backend_lock.sql )

*/

select pg_terminate_backend(a.pid)
       -- e.*, a.* --для отладки
from pg_stat_activity as a
cross join lateral (
    select NOW() - a.xact_start as xact_elapsed,          --длительность выполнения транзакции или NULL, если транзакции нет
           NOW() - a.query_start as query_elapsed,        --длительность выполнения запроса всего
           NOW() - a.state_change as state_change_elapsed --длительность выполнения запроса после изменения состояния (поля state)
) as e
cross join pg_size_bytes(regexp_replace(trim(current_setting('track_activity_query_size')), '(?<![a-zA-Z])B$', '')) as s(track_activity_query_size_bytes)
where true
  and exists(
      select
      from pg_stat_activity as b
      where true
        and b.pid != a.pid --Идентификатор процесса
        and b.datid = a.datid --OID базы данных, к которой подключён серверный процесс
        and b.usesysid = a.usesysid --OID пользователя, подключённого к серверному процессу
        and b.pid = any(pg_blocking_pids(a.pid)) --Серверный процесс заблокировал другие
        and b.query = a.query --SQL запрос
        and octet_length(b.query) < s.track_activity_query_size_bytes
  )
  --по умолчанию текст запроса обрезается до 1024 байт; это число определяется параметром track_activity_query_size
  --обрезанные запросы игнорируем
  and octet_length(a.query) < s.track_activity_query_size_bytes
  and a.pid != pg_backend_pid()
  and a.state = 'active' --серверный процесс выполняет запрос
  and a.wait_event_type = 'Lock' --Lock: процесс ожидает тяжёлую блокировку
  and e.state_change_elapsed > '15 second'::interval
  and a.application_name not in ('pg_dump', 'pg_restore')
  and a.usename != 'postgres'
order by greatest(e.state_change_elapsed, e.query_elapsed, e.xact_elapsed) desc;
