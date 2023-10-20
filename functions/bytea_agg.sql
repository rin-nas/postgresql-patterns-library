CREATE AGGREGATE public.bytea_agg(bytea) (
    SFUNC     = byteacat
    , STYPE   = bytea
);
