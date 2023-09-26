--https://ru.wikipedia.org/wiki/Расчётный_счёт

CREATE DOMAIN public.client_account AS text CHECK(public.is_client_account(VALUE));

COMMENT ON DOMAIN public.client_account IS 'Расчётный (клиентский) счёт';
