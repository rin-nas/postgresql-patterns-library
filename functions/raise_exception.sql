--Inspired by https://hakibenita.com/future-proof-sql

--Documentation: https://postgrespro.ru/docs/postgresql/14/plpgsql-errors-and-messages

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
do $$
    DECLARE
        i int not null default 0;

        exception_sqlstate text;
        exception_message text;
        exception_context text;
        exception_detail text;
        exception_hint text;
    BEGIN
        LOOP
            BEGIN -- subtransaction SAVEPOINT
                i := i + 1;
                if i = 1 then
                    perform raise_exception(null::int);
                elsif i = 2 then
                    perform raise_exception(1234567890, null);
                elsif i = 3 then
                    perform raise_exception('ABCDE'::text, null, null);
                elsif i = 4 then
                    perform raise_exception(json_build_object('id', 123), null, null, null);
                elsif i = 5 then
                    perform raise_exception('1d2h3m4s'::interval, null, null, null, null);
                elsif i = 6 then
                    perform raise_exception(now());
                end if;
                EXIT WHEN true;
            EXCEPTION WHEN others THEN
                GET STACKED DIAGNOSTICS
                    exception_sqlstate := RETURNED_SQLSTATE,
                    exception_message  := MESSAGE_TEXT,
                    exception_context  := PG_EXCEPTION_CONTEXT,
                    exception_detail   := PG_EXCEPTION_DETAIL,
                    exception_hint     := PG_EXCEPTION_HINT;

                RAISE NOTICE '====== % ======', i;
                RAISE NOTICE '* exception_sqlstate = %', exception_sqlstate;
                RAISE NOTICE '* exception_message = %', exception_message;
                RAISE NOTICE '* exception_context = %', exception_context;
                RAISE NOTICE '* exception_detail = %', exception_detail;
                RAISE NOTICE '* exception_hint = %', exception_hint;
            END;
        END LOOP;
    END;
$$;

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
