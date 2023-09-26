--https://ru.wikipedia.org/wiki/Основной_государственный_регистрационный_номер_индивидуального_предпринимателя

CREATE DOMAIN public.ogrnip AS text CHECK(public.is_ogrnip(VALUE));

COMMENT ON DOMAIN public.ogrnip IS 'ОГРНИП (основной государственный регистрационный номер индивидуального предпринимателя)';
