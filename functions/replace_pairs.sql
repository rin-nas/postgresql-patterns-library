CREATE OR REPLACE FUNCTION replace_pairs(str text, input jsonb)
    RETURNS text
    LANGUAGE plpgsql AS
$func$
DECLARE
    rec record;
BEGIN
    FOR rec IN
        SELECT * FROM jsonb_each_text(input) ORDER BY length(key) DESC
        LOOP
            str := replace(str, rec.key, rec.value);
    END LOOP;

    RETURN str;
END
$func$;

-- test
select replace_pairs('aaabaaba', '{"aa":2, "a":1}'::jsonb); -- 21b2b1
