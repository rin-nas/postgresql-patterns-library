create schema if not exists db_audit;

grant usage on schema db_audit to alexan;

drop type if exists db_audit.pg_terminated_reason_type;

create type db_audit.pg_terminated_reason_type as enum ('idle_timeout', 'duplicate_locked_query');

comment on type db_audit.pg_terminated_reason_type is $$Причины терминирования процессов:
    idle_timeout           -- у процесса закончилось максимальная длительность пребывания в статусе idle, idle in transaction, idle in transaction (aborted)
    duplicate_locked_query -- запрос, который заблокировал такой же запрос (с такой же командой) в другом процессе
$$;

drop table if exists db_audit.pg_terminated;

create table db_audit.pg_terminated (like pg_stat_activity); --PG12+

alter table db_audit.pg_terminated
    add column if not exists leader_pid integer, --PG13+
    add column if not exists query_id bigint, --PG14+
    add column pg_blocking_pids integer[] not null default array[]::integer[],
    add column id bigint generated always as identity primary key,
    add column reason db_audit.pg_terminated_reason_type not null,
    add column created_at timestamp with time zone not null default clock_timestamp() check(created_at <= clock_timestamp() + interval '10m');

comment on table db_audit.pg_terminated is $$
    Журнал терминированных процессов функцией pg_terminate_backend(), которая вызывается в функциях:
    * pg_terminate_idle_timeout() - это процессы в статусе idle с длительностью больше порогового значения
    * pg_terminate_duplicate_locked() - это процессы с одинаковыми SQL запросами, которые блокируют друг-друга
$$;
comment on column db_audit.pg_terminated.id is 'ID строки';
comment on column db_audit.pg_terminated.pg_blocking_pids is $$
    Результат функции pg_blocking_pids(pid).
    Массив с идентификаторами процессов сеансов, которые блокируют серверный процесс с указанным идентификатором.
    Либо пустой массив, если указанный серверный процесс не найден или не заблокирован.
$$;
comment on column db_audit.ddl_log.created_at is 'Дата-время создания события';

create index pg_terminated_created_at_reason on db_audit.pg_terminated (created_at, reason);

grant select on db_audit.pg_terminated to alexan;

