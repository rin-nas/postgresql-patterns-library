CREATE DOMAIN inn AS text CHECK(is_inn10(VALUE) OR is_inn12(VALUE));
COMMENT ON DOMAIN inn IS 'ИНН юридического или физического лица или ИП';
