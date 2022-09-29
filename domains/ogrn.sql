--https://ru.wikipedia.org/wiki/Основной_государственный_регистрационный_номер

CREATE DOMAIN ogrn AS text CHECK(is_ogrn(VALUE));

COMMENT ON DOMAIN ogrn IS 'ОГРН (основной государственный регистрационный номер)';
