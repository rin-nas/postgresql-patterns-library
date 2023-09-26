CREATE DOMAIN public.inn10 AS text CHECK(public.is_inn10(VALUE));
COMMENT ON DOMAIN public.inn10 IS 'ИНН юридического лица';
