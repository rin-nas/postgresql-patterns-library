-- check SQL syntax exactly in your PostgreSQL version
CREATE OR REPLACE FUNCTION depers.is_sql(sql text, is_notice boolean default false)
    returns boolean
    returns null on null input
    parallel safe
    language plpgsql
AS
$$
DECLARE
    exception_message text;
    exception_context text;
BEGIN
    BEGIN
        EXECUTE E'DO $IS_SQL$ BEGIN\nRETURN;\n' || trim(trailing E'; \r\n\t' from sql) || E';\nEND; $IS_SQL$;';
    EXCEPTION WHEN syntax_error THEN
        GET STACKED DIAGNOSTICS
            exception_message = MESSAGE_TEXT,
            exception_context = PG_EXCEPTION_CONTEXT;
        IF is_notice THEN
            RAISE NOTICE '%', exception_context;
            RAISE NOTICE '%', exception_message;
        END IF;
        RETURN FALSE;
    END;
    RETURN TRUE;
END
$$;

-- TEST
do $$
    begin
        assert not depers.is_sql('SELECTx', true);
        assert depers.is_sql('SELECT x');
    end;
$$;
