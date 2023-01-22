--Inspired by https://hakibenita.com/future-proof-sql

create or replace function raise_exception(
    value anyelement,
    message text default 'Unhandled value',
    detail text default '',
    hint text default 'See value in detail as JSON',
    errcode text default  'raise_exception'
)
    returns anyelement
    immutable
    returns null on null input
    parallel safe
    language plpgsql
    set search_path = ''
as
$$
begin
    raise exception using
        message = message,
        detail = case when detail = ''
                      then to_json(value)::text
                      else detail
                 end,
        hint = hint,
        errcode = errcode;
end;
$$;

--TEST
--select raise_exception(1234567890);
--select raise_exception('ABCDE'::text);
