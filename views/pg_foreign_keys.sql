		-- Only version 11 or newer
		CREATE OR REPLACE VIEW pg_foreign_keys AS
		SELECT ccu.constraint_name
			, tc.is_deferrable
			, tc.initially_deferred
			, tc."enforced"
			, tc.table_schema
			, tc.table_name
			, kcu.column_name
			, ccu.table_schema AS foreign_table_schema
			, ccu.TABLE_NAME AS foreign_table_name
			, ccu.COLUMN_NAME AS foreign_column_name
			, EXISTS
				(
					SELECT 1
					FROM pg_catalog.pg_index AS i
					WHERE i.indrelid = cs.conrelid
						AND i.indpred IS NULL
						AND (i.indkey::smallint[])[0:cardinality(cs.conkey)-1] OPERATOR(pg_catalog.@>) cs.conkey
				) AS is_indexed
			FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS AS tc
			INNER JOIN INFORMATION_SCHEMA.KEY_COLUMN_USAGE AS kcu
				ON tc.CONSTRAINT_NAME = kcu.CONSTRAINT_NAME
			INNER JOIN INFORMATION_SCHEMA.CONSTRAINT_COLUMN_USAGE AS ccu
				ON ccu.CONSTRAINT_NAME = tc.CONSTRAINT_NAME
			INNER JOIN PG_CATALOG.PG_NAMESPACE AS n
				ON tc.table_schema = n.nspname
			INNER JOIN PG_CATALOG.PG_CONSTRAINT AS cs
				ON n."oid" = cs.connamespace
				AND tc.constraint_name = cs.conname
		WHERE tc.CONSTRAINT_TYPE = 'FOREIGN KEY'
		;
    
    COMMENT ON VIEW pg_foreign_keys IS 'The view returns all foreign keys of the current database';
    
    --Source: https://github.com/sjstoelting/pgsql-tweaks/blob/main/sql/view_pg_foreign_keys.sql
    
