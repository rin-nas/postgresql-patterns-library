create or replace function is_datetime(str text, is_notice boolean default false)
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

    min_len constant int not null default octet_length('YYYYMMDD HHMM');
    max_len constant int not null default octet_length('YYYY-MM-DD HH:MM:SS.NNNNNN');
BEGIN
    --speed improves
    if octet_length(str) not between min_len and max_len
    then
        return false;
    end if;

    -- https://postgrespro.ru/docs/postgresql/12/datetime-input-rules
    str := regexp_replace(str, '
        ^
            (\d{8})               #YYYYMMDD
            (\d{6}(?:\.\d{1,6})?) #HHMMSS[.NNNNNN]
        $', '\1 \2', 'x');
    -- проверяем формат ввода
    if str ~ '^\d+(?:([\-.])\d+\1\d+)?$' --не число, не дата
        or str !~ '^[\d\- :.+]+$' --проверка на допустимые символы
    then
        return false;
    end if;

    BEGIN
        RETURN (str::timestamptz is not null);
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
        assert is_datetime('20001231 0900'); --мин. длина
        assert is_datetime('2000-12-31 09:59:59');
        assert is_datetime('28.02.2000 0900');
        assert is_datetime('20001231095959');
        assert is_datetime('20001231095959.123456');
        assert is_datetime('2000-12-31 09:59:59.123456'); --макс. длина

        --negative
        assert not is_datetime('1.1.1'); --неверный формат
        assert not is_datetime('20-1-1'); --неверный формат
        assert not is_datetime('31.12.2000'); --неверный формат
        assert not is_datetime('2000-12-31'); --неверный формат
        assert not is_datetime('165801001'); --неверный формат, select '165801001'::timestamptz; --16580-10-01 00:00:00.000000 +03:00
        assert not is_datetime('200012310900'); --неверный формат
        assert not is_datetime('2000-12-31 09:59:59.1234567'); --неверный формат (превышение длины)
        assert not is_datetime('/2020/10/15/screenshot-6.png'); --неверный формат, select '/2020/10/15/screenshot-6.png'::timestamptz; --2020-10-14 20:00:00.000000 +03:00

        assert not is_datetime('30.02.2000 0900'); --неверная дата-время
        assert not is_datetime('2000-12-00 0900'); --неверная дата-время
        assert not is_datetime('2000-02-30 0900'); --неверная дата-время
    end
$$;
