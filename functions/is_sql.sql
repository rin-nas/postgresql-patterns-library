CREATE OR REPLACE FUNCTION is_sql(sql text, is_notice boolean default false)
    returns boolean
    returns null on null input
    parallel unsafe --(ERROR:  cannot start subtransactions during a parallel operation)
    language plpgsql
    cost 5
AS
$$
DECLARE
    exception_sqlstate text;
    exception_message text;
    exception_context text;
BEGIN
    BEGIN

        --Speed improves. Shortest commands are "abort" or "do ''"
        IF octet_length(sql) < 5 OR sql ~ '^[\s\-]*$' THEN
            return false;
        END IF;

        EXECUTE E'DO $IS_SQL$ BEGIN\nRETURN;\n' || trim(trailing E'; \r\n\t' from sql) || E';\nEND; $IS_SQL$;';
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
    RETURN TRUE;
END
$$;

COMMENT ON FUNCTION is_sql(sql text, is_notice boolean) IS 'Check SQL syntax exactly in your PostgreSQL version';

-- TEST
do $do$
begin
    --positive
    assert is_sql('SELECT x');
    assert is_sql('ABORT');
    assert is_sql($$do ''$$);
    
    --negative
    assert not is_sql('SELECTx');
    assert not is_sql('-------');
    assert not is_sql('return unknown');
end;
$do$;

