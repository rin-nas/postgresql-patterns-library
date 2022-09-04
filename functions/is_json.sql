-- check JSON syntax exactly in your PostgreSQL version
create or replace function is_json(str text, is_notice boolean default false)
    RETURNS boolean
    returns null on null input
    parallel unsafe --(ERROR:  cannot start subtransactions during a parallel operation)
    stable
    language plpgsql
as
$$ --
DECLARE
    exception_sqlstate text;
    exception_message text;
    exception_context text;
BEGIN
    BEGIN
        RETURN (str::json is not null);
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
        assert is_json('null');
        assert is_json('true');
        assert is_json('false');
        assert is_json('0');
        assert is_json('-0.1');
        assert is_json('""');
        assert is_json('[]');
        assert is_json('{}');
        --negative
        assert not is_json('', true);
        assert not is_json('{oops}', true);
    end
$$;
