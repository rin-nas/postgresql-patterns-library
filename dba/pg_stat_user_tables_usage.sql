--Как узнать, какие самые частые действия в таблице совершаются?
with s1 as (
    select
       --pg_stat_all_tables.schemaname || '.' || pg_stat_all_tables.relname as table_name,
       relid::regclass as table_name,
       --pg_size_pretty(pg_relation_size(relid)),
       --(select spcname from pg_tablespace where oid=(select dattablespace from pg_database where datname=current_database())) as table_space,
       --seq_scan,
       seq_tup_read + idx_tup_fetch as readed,
       --idx_scan,
       n_tup_ins as inserted,
       n_tup_upd as updated,
       n_tup_del as deleted,
       --coalesce(n_tup_ins, 0) + 2 * coalesce(n_tup_upd, 0) - coalesce(n_tup_hot_upd, 0) + coalesce(n_tup_del, 0) as modified_total,
       n_tup_ins + n_tup_upd + n_tup_del as modified,
       n_tup_hot_upd * 100 / nullif(n_tup_upd, 0) as hot_updated_percent,
       (regexp_match(c.reloptions::text, 'fillfactor=(\d+)', 'i'))[1] as fillfactor
    from pg_stat_user_tables as t --https://postgrespro.ru/docs/postgresql/12/monitoring-stats
    join pg_class as c on c.oid = t.relid
)
, s2 as (
    select
        *,
        inserted * 100 / nullif(modified, 0) as inserted_percent,
        updated * 100  / nullif(modified, 0) as updated_percent,
        deleted * 100  / nullif(modified, 0) as deleted_percent,
        round(modified::numeric * 100 / nullif(readed + modified, 0), 2) as modified_percent
    from s1
)
select
    *,
    concat_ws('+',
      case when modified_percent < 20 then 'S' when modified_percent < 50 then 's' end, --select
      case when inserted_percent > 90 then 'I' when inserted_percent > 30 then 'i' end, --insert
      case when updated_percent  > 90 then 'U' when updated_percent  > 30 then 'u' end, --update
      case when deleted_percent  > 90 then 'D' when deleted_percent  > 30 then 'd' end  --delete
   ) as usage
from s2
where readed > 1e6 --пропускаем таблицы, у которых мало чтений
and modified > 1e6 --пропускаем таблицы, у которых мало модификаций
order by modified_percent desc nulls last
limit 1000;
