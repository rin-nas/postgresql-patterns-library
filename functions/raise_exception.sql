--Inspired by https://hakibenita.com/future-proof-sql

--Documentation: https://postgrespro.ru/docs/postgresql/14/plpgsql-errors-and-messages

create or replace function public.raise_exception(
    value anyelement,
    message text default 'Unhandled value',
    detail  text default null,
    hint    text default 'See value (type %s) in detail as JSON',
    errcode text default 'raise_exception',
    "column"     text default null,
    "constraint" text default null,
    "table"      text default null,
    "schema"     text default null
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
        hint    = format(coalesce(hint, 'See value (type %s) in detail as JSON'), pg_typeof(value)::text),
        errcode = coalesce(errcode, 'raise_exception'/*ERRCODE_RAISE_EXCEPTION (P0001)*/),
        column      = coalesce("column", ''),
        constraint  = coalesce("constraint", ''),
        table       = coalesce("table", ''),
        schema      = coalesce("schema", ''),
        datatype    = pg_typeof(value)::text;
    return null::bool;
end;
$$;

comment on function public.raise_exception(
    value anyelement,
    message text,
    detail  text,
    hint    text,
    errcode text,
    "column"     text,
    "constraint" text,
    "table"      text,
    "schema"     text
) is $$
    Function to throwing an error for unhandled/impossible value.
    Uses in SQL language.
    Wrapper for RAISE command with EXCEPTION level in PL/pgSQL language.
$$;

------------------------------------------------------------------------------------------------------------------------
--TEST FUNCTION
do $$
    DECLARE
        i int not null default 0;

        exception_sqlstate text;
        exception_message text;
        exception_context text;
        exception_detail text;
        exception_hint text;
        exception_datatype text;
    BEGIN
        LOOP
            BEGIN
                i := i + 1;
                if i = 1 then
                    perform public.raise_exception(null::int);
                elsif i = 2 then
                    perform public.raise_exception(1234567890, null);
                elsif i = 3 then
                    perform public.raise_exception('ABCDE'::text, null, null);
                elsif i = 4 then
                    perform public.raise_exception(json_build_object('id', 123), null, null, null);
                elsif i = 5 then
                    perform public.raise_exception('1d2h3m4s'::interval, null, null, null, null);
                elsif i = 6 then
                    perform public.raise_exception(now(), null, null, null, null, null);
                elsif i = 7 then
                    perform public.raise_exception(true, null, null, null, null, null, null);
                elsif i = 8 then
                    perform public.raise_exception(-123.456, null, null, null, null, null, null, null);
                elsif i = 9 then
                    perform public.raise_exception(point(0, 0), null, null, null, null, null, null, null, null);
                elsif i = 10 then
                    perform public.raise_exception(row('a', 1)); --record test
                end if;
                EXIT WHEN true;
            EXCEPTION WHEN others THEN
                GET STACKED DIAGNOSTICS --https://postgrespro.ru/docs/postgresql/14/plpgsql-control-structures#PLPGSQL-ERROR-TRAPPING
                    exception_sqlstate := RETURNED_SQLSTATE,
                    exception_message  := MESSAGE_TEXT,
                    exception_context  := PG_EXCEPTION_CONTEXT,
                    exception_detail   := PG_EXCEPTION_DETAIL,
                    exception_hint     := PG_EXCEPTION_HINT,
                    exception_datatype := PG_DATATYPE_NAME;

                RAISE NOTICE '====== % ======', i;
                RAISE NOTICE '* exception_sqlstate = %', exception_sqlstate;
                RAISE NOTICE '* exception_message = %', exception_message;
                RAISE NOTICE '* exception_context = %', exception_context;
                RAISE NOTICE '* exception_detail = %', exception_detail;
                RAISE NOTICE '* exception_hint = %', exception_hint;
                RAISE NOTICE '* exception_datatype = %', exception_datatype;
            END;
        END LOOP;
    END;
$$;

------------------------------------------------------------------------------------------------------------------------
--USE EXAMPLE 1
select array_agg(
           case finger
                when 1 then 'one'
                when 2 then 'two'
                when 3 then 'three'
                when 4 then 'four'
                when 5 then 'five'
                else public.raise_exception(finger)::text
           end
       )
from generate_series(1, 5) as hand(finger);

--USE EXAMPLE 2
select hand1.finger, hand2.finger
from generate_series(1, 5) as hand1(finger)
left join generate_series(1, 4 + 1) as hand2(finger) using (finger)
--we are insured against mistakes:
where case when hand1.finger between 1 and 5
            and hand2.finger is not null
           then true
           else public.raise_exception(array[hand1.finger, hand2.finger])
      end
order by hand1.finger;

--USE EXAMPLE 3
with t as materialized (
    select i
    from generate_series(1, 100000) as x(i)
    where case when clock_timestamp() < '1s' + statement_timestamp()
               then true
               else public.raise_exception(i)
          end
    order by i
)
select count(*) from t;

--USE EXAMPLE 4
SELECT
    case when data_type = 'jsonb'
         then raise_exception(data_type, 'Миграцию БД накатывать не нужно, т.к. колонка scope уже имеет тип jsonb')
    end
FROM
    information_schema.columns
WHERE
    table_schema = 'public' AND
    table_name = 'source_1234567890' AND
    column_name = 'scope';

--See also: https://github.com/decibel/pgerror
