--Журналирование (логирование) DDL команд в таблицу БД и аудит

--Выполнять под суперпользователем postgres!

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

GRANT SELECT ON db_audit.ddl_start_log TO alexan;

--TEST
table db_audit.ddl_start_log limit 100;

------------------------------------------------------------------------------------------------------------------------

--drop view db_audit.ddl_objects;

create view db_audit.ddl_objects as
with t as (
    select t.schema_name, t.object_identity, t.object_type
    from db_audit.ddl_log as t
    where t.object_identity is not null
      and t.object_type is not null
      and coalesce(t.schema_name, '') not in ('pg_temp', 'pg_toast')
    group by t.object_identity, t.object_type, t.schema_name
    having t.schema_name is null
        -- check schema exists, check schema access:
        or coalesce((select has_schema_privilege(ns.nspname, 'USAGE')
                       from pg_catalog.pg_namespace as ns
                      where ns.nspname = t.schema_name), false)
)
select t.*,
       --created:
       c.created_at,
       c.tag as created_tag,
       c.top_queries as created_top_queries,
       c.context_stack as created_context_stack,
       c.trigger_depth as created_trigger_depth,
       c.application_name as created_application_name,
       c.client_addr as created_client_addr,
       c.client_port as created_client_port,
       c.via_pooler as created_via_pooler,
       c.transaction_id as created_transaction_id,
       cd.events_total as created_events_total,
       cd.max_created_at - c.transaction_start_at as created_transaction_duration,
       --updated:
       u.created_at as updated_at,
       u.tag as updated_tag,
       u.top_queries as updated_top_queries,
       u.context_stack as updated_context_stack,
       u.trigger_depth as updated_trigger_depth,
       u.application_name as updated_application_name,
       u.client_addr as updated_client_addr,
       u.client_port as updated_client_port,
       u.via_pooler as updated_via_pooler,
       u.transaction_id as updated_transaction_id,
       ud.events_total as updated_events_total,
       ud.max_created_at - u.transaction_start_at as updated_transaction_duration
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
    /*
    GRANT and REVOKE does not work as expected, because
    "object_type" is 'TABLE' instead 'view', "schema_name" is null, "object_identity" is null.
    It's need to report PostgreSQL developers team.
    */
    and u.tag ~ '^(CREATE|ALTER|COMMENT|GRANT|REVOKE)\M'
    and (c.created_at is null or u.created_at > c.created_at)
    and not exists(
            select
            from db_audit.ddl_log as e
            where e.tag ~ '^(DROP|CREATE|ALTER|COMMENT|GRANT|REVOKE)\M'
              and e.object_identity = u.object_identity
              and e.object_type = u.object_type
              and e.created_at > u.created_at
       )
left join lateral (
    select count(*) as events_total,
           max(cd.created_at) as max_created_at
    from db_audit.ddl_log as cd
    where c.transaction_id = cd.transaction_id
    group by cd.transaction_id
) as cd on true
left join lateral (
    select count(*) as events_total,
           max(ud.created_at) as max_created_at
    from db_audit.ddl_log as ud
    where u.transaction_id = ud.transaction_id
    group by ud.transaction_id
) as ud on true
where not (c.created_at is null and u.created_at is null) --исключаем уже удалённые объекты
  --исключаем уже удалённые объекты:
  and case t.object_type
        --t.schema_name is null:
        when 'schema' then coalesce((select has_schema_privilege(ns.nspname, 'USAGE')
                                       from pg_catalog.pg_namespace as ns
                                      where ns.nspname = t.object_identity), false)
        when 'trigger' then true --TODO https://stackoverflow.com/questions/33174638/how-to-check-if-trigger-exists-in-postgresql
        --t.schema_name is not null:
        when 'table' then to_regclass(t.object_identity) is not null
        when 'view' then to_regclass(t.object_identity) is not null
        when 'function' then to_regprocedure(t.object_identity) is not null
        when 'procedure' then to_regprocedure(t.object_identity) is not null
        when 'type' then to_regtype(t.object_identity) is not null
        else true --table column, index, sequence, table constraint --TODO?
      end
order by coalesce(u.created_at, c.created_at) desc;

comment on view db_audit.ddl_objects is $$
    Список существующих объектов БД (схем, таблиц, представлений, типов, функций, процедур)
    с датой-временем создания и обновления (если такие есть в истории выполненных DDL команд)
$$;

GRANT SELECT ON db_audit.ddl_objects TO alexan;

--TEST
table db_audit.ddl_objects limit 100;
