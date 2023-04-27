CREATE EXTENSION IF NOT EXISTS citext;

/*
Why base type is citext and not text?
Because email is case insensetive, for example: alex.f@ya.ru = Alex.F@ya.ru.
So we can create unique constraint `alter table my_table add unique (email)`. Not `alter table my_table add unique (lower(email))`.
*/
CREATE DOMAIN email AS citext CHECK(
    octet_length(VALUE) BETWEEN 6 AND 320 -- https://en.wikipedia.org/wiki/Email_address
    AND VALUE LIKE '_%@_%.__%'            -- rough, but quick check email syntax
    --AND is_email(VALUE)                 -- accurate, but very slow check email syntax, so don't use it in domain!
);

COMMENT ON DOMAIN email IS 'Aдрес электронной почты с минимальной, но быстрой валидацией';

--Полная, но относительно медленная валидация email почти по спецификации:
--https://github.com/rin-nas/postgresql-patterns-library#Как-провалидировать-значение-поля-только-если-оно-явно-указано-в-UPDATE-запросе

--TEST

do $$
    begin
        assert null::email is null;
        assert 'e@m.ai'::email is not null;
    end
$$;


do $$
    BEGIN
        assert 'e@m.'::email is not null ; --raise exception [23514] ERROR: value for domain email violates check constraint "email_check"
    EXCEPTION WHEN SQLSTATE '23514' THEN
    END;
$$;
