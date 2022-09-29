--https://ru.wikipedia.org/wiki/Корреспондентский_счёт

CREATE DOMAIN correspondent_account AS text CHECK(is_correspondent_account(VALUE));

COMMENT ON DOMAIN correspondent_account IS 'Корреспондентский счёт';
