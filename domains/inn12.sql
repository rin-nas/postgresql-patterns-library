CREATE DOMAIN inn12 AS text CHECK(is_inn12(VALUE));
COMMENT ON DOMAIN inn12 IS 'ИНН физического лица и ИП';
