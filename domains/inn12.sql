CREATE DOMAIN public.inn12 AS text CHECK(public.is_inn12(VALUE));
COMMENT ON DOMAIN public.inn12 IS 'ИНН физического лица и ИП';
