CREATE DOMAIN inn10 AS text CHECK(is_inn10(VALUE));
COMMENT ON DOMAIN inn IS 'ИНН юридического лица';
