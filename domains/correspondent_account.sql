--https://ru.wikipedia.org/wiki/Корреспондентский_счёт

CREATE DOMAIN public.correspondent_account AS text CHECK(public.is_correspondent_account(VALUE));

COMMENT ON DOMAIN public.correspondent_account IS 'Корреспондентский счёт';
