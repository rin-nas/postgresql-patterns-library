--https://ru.wikipedia.org/wiki/Расчётный_счёт

CREATE DOMAIN client_account AS text CHECK(is_client_account(VALUE));

COMMENT ON DOMAIN client_account IS 'Расчётный (клиентский) счёт';
