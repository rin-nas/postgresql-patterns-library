--Inspired by https://hakibenita.com/future-proof-sql

--TODO: добавить ещё параметры, см. https://postgrespro.ru/docs/postgresql/14/plpgsql-errors-and-messages
create or replace function raise_exception(
    value anyelement,
    message text default 'Unhandled value',
    detail text default null,
    hint text default 'See value in detail as JSON',
    errcode text default 'raise_exception'
)
    returns boolean
    immutable
    --strict -- returns null if any parameter is null
    parallel safe
    language plpgsql
    set search_path = ''
as
$$
begin
    raise exception using
        message = coalesce(message, 'Unhandled value'),
        detail  = coalesce(detail, coalesce(to_json(value), 'null'::json)::text),
        hint    = coalesce(hint, 'See value in detail as JSON'),
        errcode = coalesce(errcode, 'raise_exception');
end;
$$;

--TEST
--select raise_exception(null::int);
--select raise_exception(1234567890);
--select raise_exception('ABCDE'::text);
--select raise_exception(json_build_object('id', 123));
--select raise_exception('1d2h3m4s'::interval);
--select raise_exception(now());

/*
--explain
select i
from generate_series(1, 3000000) as x(i)
where case when clock_timestamp() - statement_timestamp() < '1s'
           then true
           else raise_exception(i)
      end
order by i;
*/
