/*
Invalid page in block XXX of relation YYY

Source:
  * https://bolknote.ru/all/invalid-page-in-block-xxx-of-relation-yyy/
  * https://bolknote.ru/all/invalid-page-i-tost/
*/
CREATE OR REPLACE FUNCTION check_table(table_name TEXT)
RETURNS void AS $$
DECLARE
    rec RECORD;
    row_data RECORD;
BEGIN
    FOR rec IN SELECT ctid::text as ctid_str, id FROM table_name
    LOOP
        BEGIN
            EXECUTE format('SELECT * FROM %I WHERE ctid = %L::tid', table_name, rec.ctid_str)
            INTO STRICT row_data;

        row_data := ROW(ROW_TO_JSON(row_data)); /* to read the toasts */

        EXCEPTION WHEN others THEN
            RAISE WARNING 'CTID: %, ID: %, Error: %', rec.ctid_str, rec.id, SQLERRM;
        END;
    END LOOP;
END;
$$ LANGUAGE plpgsql;
