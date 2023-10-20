CREATE AGGREGATE public.bit_agg(bit varying) (
    SFUNC     = bitcat
    , STYPE   = bit varying
);
