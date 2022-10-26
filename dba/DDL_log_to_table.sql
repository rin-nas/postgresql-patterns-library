--Журналирование (логирование) DDL команд в таблицу БД

--Выполнять под суперпользователем postgres!

create schema db_audit;

create type db_audit.tg_event_type as enum ('ddl_command_start', 'ddl_command_end', 'table_rewrite', 'sql_drop');

comment on type company_person_permission_type is $$События:
    ddl_command_start - событие происходит непосредственно перед выполнением команд CREATE, ALTER, DROP, SECURITY LABEL, COMMENT, GRANT и REVOKE.
    ddl_command_end   - событие происходит непосредственно после выполнения команд из того же набора.
    table_rewrite     - событие происходит только после того, как таблица будет перезаписана в результате определённых действий команд ALTER TABLE и ALTER TYPE.
    sql_drop          - событие происходит непосредственно перед событием ddl_command_end для команд, которые удаляют объекты базы данных.
$$;

create table db_audit.ddl_log (
    id integer generated always as identity primary key,
    transaction_start_at timestamp with time zone not null default transaction_timestamp() check(transaction_start_at <= clock_timestamp() + interval '10m'),
    created_at timestamp with time zone not null default clock_timestamp() check(created_at <= clock_timestamp() + interval '10m'),
    event db_audit.tg_event_type not null,
    tag text not null check (octet_length(tag) > 0),

    client_addr inet,
    client_port int,
    backend_pid int not null,
    application_name text,
    "session_user" name not null check (octet_length("session_user") > 0),
    "current_user" name not null check (octet_length("current_user") > 0),
    transaction_id bigint not null,

    conf_load_time timestamptz not null check(conf_load_time <= clock_timestamp() + interval '10m'),
    postmaster_start_time timestamptz not null check(postmaster_start_time <= clock_timestamp() + interval '10m'),
    server_version_num int not null check (server_version_num > 0),

    current_schemas name[],
    trigger_depth int not null check (trigger_depth >= 0),
    top_queries text not null check (octet_length(top_queries) > 0),
    context_stack text check (octet_length(context_stack) > 0),

    --Nullable columns from pg_event_trigger_ddl_commands() called on 'ddl_command_end' event:
    object_type text,
    schema_name text,
    object_identity text,
    in_extension bool
);

do $do$
begin

    comment on table db_audit.ddl_log is 'Журнал выполнения DDL команд';

    comment on column db_audit.ddl_log.id is 'ID строки';
    comment on column db_audit.ddl_log.transaction_start_at is 'Дата-время начала транзакции';
    comment on column db_audit.ddl_log.created_at is 'Дата-время создания события';
    comment on column db_audit.ddl_log.event is 'TG_EVENT - событие, для которого сработал триггер';
    comment on column db_audit.ddl_log.tag is 'TG_TAG - тег команды, для которой сработал триггер';

    comment on column db_audit.ddl_log.client_addr is 'inet_client_addr()';
    comment on column db_audit.ddl_log.client_port is 'inet_client_port()';
    comment on column db_audit.ddl_log.backend_pid is 'pg_backend_pid() - код серверного процесса, обслуживающего текущий сеанс';
    comment on column db_audit.ddl_log.application_name is $$current_setting('application_name') - имя приложения, обычно устанавливается приложением при подключении к серверу$$;
    comment on column db_audit.ddl_log."session_user" is 'session_user - имя пользователя сеанса';
    comment on column db_audit.ddl_log."current_user" is 'current_user - имя пользователя в текущем контексте выполнения';
    comment on column db_audit.ddl_log.transaction_id is 'txid_current() - получает идентификатор текущей транзакции и присваивает новый, если текущая транзакция его не имеет';

    comment on column db_audit.ddl_log.conf_load_time is 'pg_conf_load_time() - время загрузки конфигурации';
    comment on column db_audit.ddl_log.postmaster_start_time is 'pg_postmaster_start_time() - время запуска сервера';
    comment on column db_audit.ddl_log.server_version_num is $$current_setting('server_version_num') - номер версии сервера в виде целого числа$$;

    comment on column db_audit.ddl_log.current_schemas is 'current_schemas(true) - имена схем в пути поиска, возможно включая схемы, добавляемые в него неявно';
    comment on column db_audit.ddl_log.trigger_depth is 'pg_trigger_depth() - текущий уровень вложенности в триггерах PostgreSQL (0, если эта функция вызывается (прямо или косвенно) не из тела триггера)';
    comment on column db_audit.ddl_log.top_queries is 'current_query() - текст запроса, выполняемого в данный момент, в том виде, в каком его передал клиент (может состоять из нескольких операторов)';
    comment on column db_audit.ddl_log.context_stack is $$Стёк вызова, позволяет определить текущее место выполнения кода.
В первой строке отмечается текущая функция и выполняемая в данный момент команда GET DIAGNOSTICS (она вырезается за ненадобностью).
Во второй и последующих строках отмечаются функции выше по стеку вызовов$$;

    --Nullable columns from pg_event_trigger_ddl_commands() called on 'ddl_command_end' event:
    comment on column db_audit.ddl_log.object_type is 'Тип объекта';
    comment on column db_audit.ddl_log.schema_name is 'Имя схемы, к которой относится объект; если объект не относится ни к какой схеме — NULL. В кавычки имя не заключается.';
    comment on column db_audit.ddl_log.object_identity is 'Текстовое представление идентификатора объекта, включающее схему. При необходимости компоненты этого идентификатора заключаются в кавычки.';
    comment on column db_audit.ddl_log.in_extension is 'True, если команда является частью скрипта расширения';

end
$do$;

create index ddl_log_transaction_id_index on db_audit.ddl_log (transaction_id);
create index ddl_log_multicolumn on db_audit.ddl_log (object_identity, object_type, created_at) where object_identity is not null;
create index ddl_log_created_at_pg_temp on db_audit.ddl_log (created_at) where schema_name = 'pg_temp';

------------------------------------------------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION db_audit.ddl_command_start_log()
    RETURNS event_trigger
    SECURITY DEFINER
    PARALLEL SAFE
    LANGUAGE plpgsql
AS $$
DECLARE
    stack text;
BEGIN
    GET DIAGNOSTICS stack := PG_CONTEXT;
    stack := nullif(regexp_replace(stack, '^[^\r\n]*\s*', ''), ''); --удаляем первую строку

    insert into db_audit.ddl_log (
        event, tag, client_addr, client_port,
        backend_pid, application_name, "session_user", "current_user", transaction_id,
        conf_load_time, postmaster_start_time, server_version_num,
        current_schemas, trigger_depth, top_queries, context_stack)
    select TG_EVENT::db_audit.tg_event_type, TG_TAG, inet_client_addr(), inet_client_port(),
           pg_backend_pid(), nullif(trim(current_setting('application_name')), ''), session_user, current_user, txid_current(),
           pg_conf_load_time(), pg_postmaster_start_time(), current_setting('server_version_num')::int,
           current_schemas(true), pg_trigger_depth(), current_query(), stack;

END;
$$;

CREATE OR REPLACE FUNCTION db_audit.ddl_command_end_log()
    RETURNS event_trigger
    SECURITY DEFINER
    PARALLEL SAFE
    LANGUAGE plpgsql
AS $$
DECLARE
    rec record;
    stack text;
    is_deleted boolean not null default false;
BEGIN
    GET DIAGNOSTICS stack := PG_CONTEXT;
    stack := nullif(regexp_replace(stack, '^[^\r\n]*\s*', ''), ''); --удаляем первую строку

    FOR rec IN SELECT * FROM pg_event_trigger_ddl_commands()
    LOOP
        insert into db_audit.ddl_log (
            event, tag, client_addr, client_port,
            backend_pid, application_name, "session_user", "current_user", transaction_id,
            conf_load_time, postmaster_start_time, server_version_num,
            current_schemas, trigger_depth, top_queries, context_stack,
            object_type, schema_name, object_identity, in_extension)
        select TG_EVENT::db_audit.tg_event_type, TG_TAG, inet_client_addr(), inet_client_port(),
               pg_backend_pid(), nullif(trim(current_setting('application_name')), ''), session_user, current_user, txid_current(),
               pg_conf_load_time(), pg_postmaster_start_time(), current_setting('server_version_num')::int,
               current_schemas(true), pg_trigger_depth(), current_query(), stack,
               rec.object_type, rec.schema_name, rec.object_identity, rec.in_extension;

        -- в истории создания и удаления временных таблиц храним только 1000 последних строк,
        -- остальные удаляем в момент создания временной таблицы
        if rec.schema_name = 'pg_temp' and not is_deleted then

            is_deleted := true;

            with t as (
                select t.transaction_id
                from db_audit.ddl_log as t
                where t.schema_name = 'pg_temp'
                order by t.created_at desc
                offset 1000
            ),
            s as (
                select m.id
                from db_audit.ddl_log as m
                where m.transaction_id in (select t.transaction_id from t)
                for update of m -- пытаемся заблокировать строки таблицы от изменения в параллельных транзакциях
                skip locked -- если строки заблокировать не удалось, пропускаем их (они уже заблокированы в параллельных транзакциях)
            )
            --select * from s; --для отладки
            delete from db_audit.ddl_log as d
            where d.id in (select s.id from s); -- наиболее эффективно удаление по первичному ключу
            --returning id --для отладки

        end if;

    END LOOP;

END;
$$;

CREATE OR REPLACE FUNCTION db_audit.sql_drop_log()
    RETURNS event_trigger
    SECURITY DEFINER
    PARALLEL SAFE
    LANGUAGE plpgsql
AS $$
DECLARE
    rec record;
    stack text;
BEGIN
    GET DIAGNOSTICS stack := PG_CONTEXT;
    stack := nullif(regexp_replace(stack, '^[^\r\n]*\s*', ''), ''); --удаляем первую строку

    FOR rec IN SELECT * FROM pg_event_trigger_dropped_objects()
    LOOP
        insert into db_audit.ddl_log (
            event, tag, client_addr, client_port,
            backend_pid, application_name, "session_user", "current_user", transaction_id,
            conf_load_time, postmaster_start_time, server_version_num,
            current_schemas, trigger_depth, top_queries, context_stack,
            object_type, schema_name, object_identity)
        select TG_EVENT::db_audit.tg_event_type, TG_TAG, inet_client_addr(), inet_client_port(),
               pg_backend_pid(), nullif(trim(current_setting('application_name')), ''), session_user, current_user, txid_current(),
               pg_conf_load_time(), pg_postmaster_start_time(), current_setting('server_version_num')::int,
               current_schemas(true), pg_trigger_depth(), current_query(), stack,
               rec.object_type, rec.schema_name, rec.object_identity;
    END LOOP;

END;
$$;

CREATE EVENT TRIGGER ddl_command_start_trigger ON ddl_command_start
    --WHEN TAG IN ('CREATE TABLE', 'DROP TABLE', 'ALTER TABLE') --для отладки
    EXECUTE FUNCTION db_audit.ddl_command_start_log();

CREATE EVENT TRIGGER ddl_command_end_trigger ON ddl_command_end
    --WHEN TAG IN ('CREATE TABLE', 'DROP TABLE', 'ALTER TABLE') --для отладки
    EXECUTE FUNCTION db_audit.ddl_command_end_log();

CREATE EVENT TRIGGER sql_drop_trigger ON sql_drop
    --WHEN TAG IN ('CREATE TABLE', 'DROP TABLE', 'ALTER TABLE') --для отладки
    EXECUTE FUNCTION db_audit.sql_drop_log();

------------------------------------------------------------------------------------------------------------------------
--TEST

create schema if not exists test;

DO $$
BEGIN
    EXECUTE 'CRE' || 'ATE TABLE test.a() /*"test", ''test''*/ ';
END
$$;

create table test.b();
alter table test.a
    add column i int,
    add column t text,
    add column s varchar(320);
create index on test.a(i);
drop table if exists test.a, test.b;

------------------------------------------------------------------------------------------------------------------------

create view db_audit.ddl_start_log as
select s.*,
       t.events_total,
       t.max_created_at - s.transaction_start_at as transaction_duration
from db_audit.ddl_log as s
cross join lateral (
    select count(*) as events_total,
           max(n.created_at) as max_created_at
    from db_audit.ddl_log as n
    where s.transaction_id = n.transaction_id
    group by n.transaction_id
) as t --on true
where event = 'ddl_command_start' --and top_queries !~ '^DROP TABLE IF EXISTS'
order by s.id desc;

comment on view db_audit.ddl_start_log is 'История выполненных DDL команд с длительностью выполнения транзакции';

--TEST
table db_audit.ddl_start_log limit 100;

------------------------------------------------------------------------------------------------------------------------

create view db_audit.objects as
with t as (
    select t.object_identity, t.object_type
    from db_audit.ddl_log as t
    where t.object_identity is not null
      and t.object_type is not null
      and (schema_name is null or schema_name not in ('pg_toast', 'pg_temp')) --служебные таблицы и индексы PG нас не интересуют, они удаляются автоматически вместе с таблицами
      and object_type not in ('table column', 'index', 'sequence', 'table constraint', 'domain constraint', 'trigger') --всё это удаляется автоматически вместе с таблицами
    group by t.object_identity, t.object_type
)
select t.*,
       c.created_at, c.tag as created_tag, c.top_queries as created_top_queries, c.context_stack as created_context_stack,
       u.created_at as updated_at, u.tag as updated_tag, u.top_queries as updated_top_queries, u.context_stack as updated_context_stack
from t
left join db_audit.ddl_log as c --вычисляем дату-время создания
    on c.object_identity = t.object_identity
    and c.object_type = t.object_type
    and c.tag ~ '^CREATE\M' --CREATE OR REPLACE
    and not exists(
            select
            from db_audit.ddl_log as e
            where e.tag ~ '^(DROP|CREATE)\M'
              and e.object_identity = c.object_identity
              and e.object_type = c.object_type
              and e.created_at > c.created_at
        )
left join db_audit.ddl_log as u --вычисляем дату-время обновления
    on u.object_identity = t.object_identity
    and u.object_type = t.object_type
    and u.tag ~ '^(CREATE|ALTER|COMMENT)\M' --CREATE OR REPLACE
    and u.created_at is distinct from c.created_at
    and not exists(
            select
            from db_audit.ddl_log as e
            where e.tag ~ '^(DROP|CREATE|ALTER|COMMENT)\M'
              and e.object_identity = u.object_identity
              and e.object_type = u.object_type
              and e.created_at > u.created_at
       )
where not (c.created_at is null and u.created_at is null) --исключаем уже удалённые объекты
  and case t.object_type --исключаем уже удалённые объекты
          when 'table' then to_regclass(t.object_identity) is not null
          when 'view' then to_regclass(t.object_identity) is not null
          when 'function' then to_regprocedure(t.object_identity) is not null
          when 'procedure' then to_regprocedure(t.object_identity) is not null
          when 'type' then to_regtype(t.object_identity) is not null
          else true
      end
 --and t.object_identity !~ '^depers\M'
order by coalesce(u.created_at, c.created_at) desc;

comment on view db_audit.objects is $$
    Список существующих объектов БД (схем, таблиц, представлений, типов, функций, процедур)
    с датой-временем создания и обновления (если такие есть в истории выполненных DDL команд)
$$;

--TEST
table db_audit.objects limit 100;

------------------------------------------------------------------------------------------------------------------------
/*
-- разрешаем пользователю migration читать таблицы и схемы (но не изменять)
GRANT USAGE ON SCHEMA db_audit TO migration;
GRANT SELECT ON db_audit.ddl_log TO migration;
GRANT SELECT ON db_audit.ddl_start_log TO migration;
GRANT SELECT ON db_audit.objects TO migration;
*/
