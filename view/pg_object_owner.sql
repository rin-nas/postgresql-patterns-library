/*
Creates a view to get the ownership of all objects in the current database.
PostgreSQL 11 or newer
Original source: https://github.com/sjstoelting/pgsql-tweaks/blob/main/sql/view_pg_object_ownership.sql
Changes: object_name column added
*/

CREATE OR REPLACE VIEW pg_object_owner AS
WITH dbobjects AS
    (
        SELECT cls.oid
            , nsp.nspname AS object_schema
            , cls.relname AS object_name
            , rol.rolname AS owner
            , CASE cls.relkind
                WHEN 'I' THEN
                    'PARTITIONED INDEX'
                WHEN 'S' THEN
                    'SEQUENCE'
                WHEN 'c' THEN
                    'COMPOSITE TYPE'
                WHEN 'f' THEN
                    'FOREIGN TABLE'
                WHEN 'i' THEN
                    'INDEX'
                WHEN 'm' THEN
                    'MATERIALIZED_VIEW'
                WHEN 'p' THEN
                    'PARTITIONED TABLE'
                WHEN 'r' THEN
                    'TABLE'
                WHEN 'v' THEN
                    'VIEW'
                ELSE
                    cls.relkind::text
            END AS object_type
        FROM pg_catalog.pg_class AS cls
        INNER JOIN pg_roles AS rol
            ON cls.relowner = rol.oid
        INNER JOIN pg_catalog.pg_namespace AS nsp
            ON cls.relnamespace = nsp.oid
        UNION ALL
        SELECT db.oid
            , NULL AS object_schema
            , db.datname AS object_name
            , rol.rolname AS owner
            , 'DATABASE' AS object_type
        FROM pg_catalog.pg_database AS db
        INNER JOIN pg_roles AS rol
            ON db.datdba = rol.oid
        UNION ALL
        SELECT ext.oid
            , NULL AS object_schema
            , ext.extname
            , rol.rolname AS owner
            , 'EXTENSION' AS object_type
        FROM pg_catalog.pg_extension AS ext
        INNER JOIN pg_roles AS rol
            ON ext.extowner = rol.oid
        UNION ALL
        SELECT fdw.oid
            , NULL AS object_schema
            , fdw.fdwname AS object_name
            , rol.rolname AS owner
            , 'FOREIGN DATA WRAPPER' AS object_type
        FROM pg_catalog.pg_foreign_data_wrapper AS fdw
        INNER JOIN pg_roles AS rol
            ON fdw.fdwowner = rol.oid
        UNION ALL
        SELECT srv.oid
            , NULL AS object_schema
            , srv.srvname AS object_name
            , rol.rolname AS owner
            , 'FOREIGN SERVER' AS object_type
        FROM pg_catalog.pg_foreign_server AS srv
        INNER JOIN pg_roles AS rol
            ON srv.srvowner = rol.oid
        UNION ALL
        SELECT lang.oid
            , NULL AS object_schema
            , lang.lanname AS object_name
            , rol.rolname AS owner
            , 'LANGUAGE' AS object_type
        FROM pg_catalog.pg_language AS lang
        INNER JOIN pg_roles AS rol
            ON lang.lanowner = rol.oid
        UNION ALL
        SELECT nsp.oid
            , NULL AS object_schema
            , nsp.nspname AS object_name
            , rol.rolname AS owner
            , 'SCHEMA' AS object_type
        FROM pg_catalog.pg_namespace AS nsp
        INNER JOIN pg_roles AS rol
            ON nsp.nspowner = rol.oid
        UNION ALL
        SELECT opc.oid
            , NULL AS object_schema
            , opc.opcname AS object_name
            , rol.rolname AS owner
            , 'OPERATOR CLASS' AS object_type
        FROM pg_catalog.pg_opclass AS opc
        INNER JOIN pg_roles AS rol
            ON opc.opcowner = rol.oid
        UNION ALL
        SELECT pro.oid
            , nsp.nspname AS object_schema
            , pro.proname AS object_name
            , rol.rolname AS owner
            , CASE lower(pro.prokind)
                WHEN 'f' THEN
                    'FUNCTION'
                WHEN 'p' THEN
                    'PROCEDURE'
                WHEN 'a' THEN
                    'AGGREGATE FUNCTION'
                WHEN 'w' THEN
                    'WINDOW FUNCTION'
                ELSE
                    lower(pro.prokind)
            END AS object_type
        FROM pg_catalog.pg_proc AS pro
        INNER JOIN pg_roles AS rol
            ON pro.proowner = rol.oid
        INNER JOIN pg_catalog.pg_namespace nsp
            ON pro.pronamespace = nsp.oid
            WHERE nsp.nspname NOT IN ('pg_catalog', 'information_schema')
        UNION ALL
        SELECT col.oid
            , NULL AS object_schema
            , col.collname AS object_name
            , rol.rolname AS owner
            , 'COLLATION' AS object_type
        FROM pg_catalog.pg_collation AS col
        INNER JOIN pg_roles AS rol
            ON col.collowner = rol.oid
        UNION ALL
        SELECT con.oid
            , NULL AS object_schema
            , con.conname AS object_name
            , rol.rolname AS owner
            , 'CONVERSION' AS object_type
        FROM pg_catalog.pg_conversion AS con
        INNER JOIN pg_roles AS rol
            ON con.conowner = rol.oid
        UNION ALL
        SELECT evt.oid
            , NULL AS object_schema
            , evt.evtname AS object_name
            , rol.rolname AS owner
            , 'EVENT TRIGGER' AS object_type
        FROM pg_catalog.pg_event_trigger AS evt
        INNER JOIN pg_roles AS rol
            ON evt.evtowner = rol.oid
        UNION ALL
        SELECT opf.oid
            , NULL AS object_schema
            , opf.opfname AS object_name
            , rol.rolname AS owner
            , 'OPERATION FAMILY' AS object_type
        FROM pg_catalog.pg_opfamily AS opf
        INNER JOIN pg_roles AS rol
            ON opf.opfowner = rol.oid
        UNION ALL
        SELECT pub.oid
            , NULL AS object_schema
            , pub.pubname AS object_name
            , rol.rolname AS owner
            , 'PUBLICATIONS' AS object_type
        FROM pg_catalog.pg_publication AS pub
        INNER JOIN pg_roles AS rol
            ON pub.pubowner = rol.oid
    )
SELECT dbobjects.oid
    , dbobjects.object_schema
    , dbobjects.object_name --!!!
    , dbobjects.owner
    , dbobjects.object_type
    , depend.deptype
    , CASE depend.deptype
        WHEN 'n' THEN
            'DEPENDENCY_NORMAL'
        WHEN 'a' THEN
            'DEPENDENCY_AUTO'
        WHEN 'i' THEN
            'DEPENDENCY_INTERNAL'
        WHEN 'P' THEN
            'DEPENDENCY_PARTITION_PRI'
        WHEN 'S' THEN
            'DEPENDENCY_PARTITION_SEC'
        WHEN 'e' THEN
            'DEPENDENCY_EXTENSION'
        WHEN 'x' THEN
            'DEPENDENCY_EXTENSION'
        WHEN 'p' THEN
            'DEPENDENCY_PIN'
        ELSE
            'NOT DEFINED, SEE DOCUMENTATION'
    END AS dependency_type
FROM dbobjects
LEFT OUTER JOIN pg_catalog.pg_depend AS depend
    ON dbobjects.oid = depend.objid
WHERE object_schema NOT IN ('information_schema', 'pg_catalog')
    AND object_schema NOT LIKE 'pg_toast%'
;

-- Add a comment
COMMENT ON VIEW pg_object_owner IS 'The view returns all objects, its type, and its ownership in the current database, excluding those in the schema pg_catalog and information_schema';
