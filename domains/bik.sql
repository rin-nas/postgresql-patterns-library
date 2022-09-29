--https://ru.wikipedia.org/wiki/Банковский_идентификационный_код

CREATE DOMAIN bik AS text CHECK(is_bik(VALUE));

COMMENT ON DOMAIN bik IS 'БИК (Банковский Идентификационный Код)';
