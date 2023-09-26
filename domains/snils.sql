--https://ru.wikipedia.org/wiki/Страховой_номер_индивидуального_лицевого_счёта

CREATE DOMAIN public.snils AS text CHECK(public.is_snils(VALUE));

COMMENT ON DOMAIN public.snils IS 'СНИЛС (страховой номер индивидуального лицевого счёта)';
