CREATE OR REPLACE FUNCTION is_sql(sql text) returns boolean
    language plpgsql
AS
$$
DECLARE
    exception_message text;
    exception_context text;
BEGIN
    BEGIN
        EXECUTE E'DO $IS_SQL$ BEGIN\nRETURN;\n' || trim(trailing E'; \r\n' from sql) || E';\nEND; $IS_SQL$;';
    EXCEPTION WHEN syntax_error THEN
        GET STACKED DIAGNOSTICS
            exception_message = MESSAGE_TEXT,
            exception_context = PG_EXCEPTION_CONTEXT;
        RAISE NOTICE '%', exception_context;
        RAISE NOTICE '%', exception_message;
        RETURN FALSE;
    END;
    RETURN TRUE;
END
$$;

-- проверяем, что работает
SELECT is_sql('SELECTx'), is_sql('SELECT x');
