-- check IP syntax exactly in your PostgreSQL version
create or replace function is_inet(str text, is_notice boolean default false)
    RETURNS boolean
    returns null on null input
    parallel unsafe --(ERROR:  cannot start subtransactions during a parallel operation)
    stable
    language plpgsql
as
$$
DECLARE
    exception_sqlstate text;
    exception_message text;
    exception_context text;
BEGIN
    BEGIN
        RETURN (str::inet is not null);
    EXCEPTION WHEN others THEN
        IF is_notice THEN
            GET STACKED DIAGNOSTICS
                exception_sqlstate := RETURNED_SQLSTATE,
                exception_message  := MESSAGE_TEXT,
                exception_context  := PG_EXCEPTION_CONTEXT;
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
        assert is_inet('0.0.0.0');
        assert is_inet('255.255.255.255');
        assert is_inet('192.168.0.1/24');
        --negative
        assert not is_inet('0.0.0');
        assert not is_inet('255.255.255.256');
        assert not is_inet('192.168.0.1/244');
    end
$$;
