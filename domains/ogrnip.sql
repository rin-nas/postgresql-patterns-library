--https://ru.wikipedia.org/wiki/Основной_государственный_регистрационный_номер_индивидуального_предпринимателя

CREATE DOMAIN ogrnip AS text CHECK(is_ogrnip(VALUE));

COMMENT ON DOMAIN ogrnip IS 'ОГРНИП (основной государственный регистрационный номер индивидуального предпринимателя)';
