--https://ru.wikipedia.org/wiki/Банковский_идентификационный_код

CREATE DOMAIN public.bik AS text CHECK(public.is_bik(VALUE));

COMMENT ON DOMAIN public.bik IS 'БИК (Банковский Идентификационный Код)';
