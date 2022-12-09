/*
Терминируем долгие простаивающие без дела подключения к БД.

Цель — защита тестовой БД или производственной реплики БД от сбоев из-за ошибок в коде приложений.

Чтобы реплике забрать изменения с мастера, она принудительно терминирует по таймауту все очень долгие запросы и транзакции, которые выполняются на реплике.

Запрос необходимо выполнять 1 раз в минуту (например, из крона).

    $ crontab -l
    # m h dom mon dow command
    * * * * * psql -U postgres --file=/path/to/pg_terminate_backend_idle.sql

*/

--inspired by https://stackoverflow.com/questions/12391174/how-to-close-idle-connections-in-postgresql-automatically/69528572

select pg_terminate_backend(a.pid)
       --e.*, a.* --для отладки
from pg_stat_activity as a
cross join lateral (
    select NOW() - a.xact_start as xact_elapsed,          --длительность выполнения транзакции или NULL, если транзакции нет
           NOW() - a.query_start as query_elapsed,        --длительность выполнения запроса всего
           NOW() - a.state_change as state_change_elapsed --длительность выполнения запроса после изменения состояния (поля state)
) as e
where true
  and a.pid != pg_backend_pid()
  and a.state in ('idle', 'idle in transaction', 'idle in transaction (aborted)')
  and a.wait_event_type = 'Client'
  --значение таймаутов в минутах д.б. меньше, чем указано на реплике в параметрах конфигурации max_standby_archive_delay или max_standby_streaming_delay
  and (e.state_change_elapsed > interval '20 minutes' or e.xact_elapsed > interval '50 minutes')
  and a.application_name not in ('psql', 'pg_dump', 'pg_restore')
  and a.usename != 'postgres'
order by greatest(e.state_change_elapsed, e.query_elapsed, e.xact_elapsed) desc;
