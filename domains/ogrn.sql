--https://ru.wikipedia.org/wiki/Основной_государственный_регистрационный_номер

CREATE DOMAIN public.ogrn AS text CHECK(public.is_ogrn(VALUE));

COMMENT ON DOMAIN public.ogrn IS 'ОГРН (основной государственный регистрационный номер)';
