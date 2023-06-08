-- Adapted from https://cloud.google.com/alloydb/docs/troubleshoot/find-fix-inconsistent-indexes

DO $$
DECLARE
    r RECORD;
BEGIN
    RAISE NOTICE 'Started amcheck on database: %', current_database();
    FOR r IN
        SELECT c.oid, c.oid::regclass relname, i.indisunique
        FROM pg_index i
                 JOIN pg_opclass op ON i.indclass[0] = op.oid
                 JOIN pg_am am ON op.opcmethod = am.oid
                 JOIN pg_class c ON i.indexrelid = c.oid
                 JOIN pg_namespace n ON c.relnamespace = n.oid
        WHERE am.amname = 'btree'
          AND c.relpersistence != 't'
          AND c.relkind = 'i'
          AND i.indisready AND i.indisvalid
        ORDER BY i.indisunique, c.oid::regclass::text
    LOOP
        BEGIN
            RAISE NOTICE 'Checking index %:', r.relname;
            PERFORM bt_index_check(index => r.oid, heapallindexed => r.indisunique);
        EXCEPTION
            WHEN undefined_function THEN
                RAISE EXCEPTION 'Failed to find the amcheck extension';
            WHEN OTHERS THEN
                RAISE LOG 'Failed to check index %: %', r.relname, sqlerrm;
                RAISE WARNING 'Failed to check index %: %', r.relname, sqlerrm;
        END;
    END LOOP;
    RAISE NOTICE 'Finished amcheck on database: %', current_database();
END $$;
