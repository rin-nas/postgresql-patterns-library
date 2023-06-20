CREATE OR REPLACE FUNCTION is_regexp(regexp text, is_notice boolean default false)
    returns boolean
    returns null on null input
    parallel unsafe --(ERROR:  cannot start subtransactions during a parallel operation)
    language plpgsql
    set search_path = ''
    cost 5
AS
$$
DECLARE
    exception_sqlstate text;
    exception_message text;
    exception_context text;
BEGIN
    BEGIN
        PERFORM '' ~ regexp;
    EXCEPTION WHEN invalid_regular_expression THEN
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
    RETURN TRUE;
END
$$;

comment on function is_regexp(regexp text, is_notice boolean) is 'Check Regexp syntax exactly in your PostgreSQL version';

-- TEST
do $$
    begin
        --positive
        assert is_regexp('^[z]+\d$');
        assert is_regexp('');

        --negative
        assert not is_regexp('[', true);
        assert not is_regexp('*', true);
        assert not is_regexp('\', true);
    end;
$$;
