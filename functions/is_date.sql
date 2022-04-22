create or replace function is_date(str text, is_notice boolean default false)
    returns boolean
    returns null on null input
    --parallel safe
    stable
    language plpgsql
    set datestyle = 'ISO, DMY'
    cost 5
as
$$
DECLARE
    exception_sqlstate text;
    exception_message text;
    exception_context text;
BEGIN
    -- сначала проверяем формат ввода (YYYYMMDD не поддерживается!)
    if not (
        octet_length(str) = 10 --speed improves
        and (str ~ '^\d{4}-\d{2}-\d{2}$' /*YYYY-MM-DD*/ or str ~ '^\d{2}\.\d{2}\.\d{4}$'/*DD.MM.YYYY*/)
       )
    then
        return false;
    end if;

    BEGIN
        -- теперь проверяем наличие несущестующей даты
        -- make_date() для невалидной даты тоже кидает исключение, например: [22008] ERROR: date field value out of range: 2021-02-29
        RETURN (str::date is not null);
    EXCEPTION WHEN others THEN
        GET STACKED DIAGNOSTICS
            exception_sqlstate = RETURNED_SQLSTATE,
            exception_message = MESSAGE_TEXT,
            exception_context = PG_EXCEPTION_CONTEXT;
        IF is_notice THEN
            RAISE NOTICE 'exception_sqlstate = %', exception_sqlstate;
            RAISE NOTICE 'exception_context = %', exception_context;
            RAISE NOTICE 'exception_message = %', exception_message;
        END IF;
        RETURN FALSE;
    END;
END;
$$;

--TEST
do $$
    begin
        --positive
        assert is_date('01.01.2000');
        assert is_date('2000-12-31');

        --negative
        assert not is_date('01.01.2000 00:00:00');
        assert not is_date('00.01.2000');
        assert not is_date('30.02.2000');
    end
$$;
