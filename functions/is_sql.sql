CREATE OR REPLACE FUNCTION is_sql(sql text, is_notice boolean default false)
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
    id text;
BEGIN
    BEGIN

        --Speed improves. Shortest commands are "abort" or "do ''"
        IF octet_length(sql) < 5 OR sql !~ '[A-Za-z]{2}' THEN
            return false;
        END IF;

        -- add ";" in end of string, if ";" does not exist
        sql := regexp_replace(sql, $regexp$
            ;?
            ((?: #1
                 --[^\r\n]*                     #singe-line comment
              |  /\*                            #multi-line comment (can be nested)
                   [^*/]* #speed improves
                   (?: [^*/]+
                     | \*[^/] #not end comment
                     | /[^*]  #not begin comment
                     |   #recursive:
                         /\*                            #multi-line comment (can be nested)
                           [^*/]* #speed improves
                           (?: [^*/]+
                             | \*[^/] #not end comment
                             | /[^*]  #not begin comment
                             |   #recursive:
                                 /\*                            #multi-line comment (can be nested)
                                   [^*/]* #speed improves
                                   (?: [^*/]+
                                     | \*[^/] #not end comment
                                     | /[^*]  #not begin comment
                                     #| #recursive
                                   )*
                                 \*/
                           )*
                         \*/
                   )*
                 \*/
              |  \s+
            )*)
            $
        $regexp$, ';\1', 'x');

        id  := to_char(now(), 'YYYYMMDDHH24MISSMS');
        sql := E'DO $IS_SQL' || id || E'$ BEGIN\nRETURN;\n' || sql || E'\nEND; $IS_SQL' || id || E'$;';

        EXECUTE sql;
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
    RETURN TRUE;
END
$$;

COMMENT ON FUNCTION is_sql(sql text, is_notice boolean) IS 'Check SQL syntax exactly in your PostgreSQL version';

-- TEST
do $do$
begin
    --positive
    assert is_sql('SELECT x/*--;*/ ; ');
    assert is_sql('SELECT x ; --');
    assert is_sql('SELECT -- ; ');
    assert is_sql('SELECT ; /*select ;*/ --');
    assert is_sql('ABORT');
    assert is_sql($$do ''$$);
    assert is_sql(pg_catalog.pg_get_functiondef('public.is_sql'::regproc::oid)); --self test

    --negative
    assert not is_sql('');
    assert not is_sql('do');
    assert not is_sql('123');
    assert not is_sql('SELECT !');
    assert not is_sql('SELECT ;;');
    assert not is_sql('SELECT ; ; /*select ;*/ --');
    assert not is_sql('  --select 1  ');
    assert not is_sql('  /*select 1*/  ');
    assert not is_sql('return unknown');
end;
$do$;

--HINT
/*
alter table db_migration
    add constraint db_migration_sql_up_check check (is_sql(sql_up)) not valid,
    add constraint db_migration_sql_down_check check (
        sql_down ~ '^\s*$' OR
        sql_comments_remove(sql_down) ~ '^\s*$' OR
        is_sql(sql_down)
    ) not valid;
*/

--see also https://github.com/okbob/plpgsql_check/
