--https://ru.wikipedia.org/wiki/Страховой_номер_индивидуального_лицевого_счёта

CREATE DOMAIN snils AS text CHECK(is_snils(VALUE));

COMMENT ON DOMAIN snils IS 'СНИЛС (страховой номер индивидуального лицевого счёта)';
