CREATE DOMAIN email AS text CHECK(
    octet_length(VALUE) BETWEEN 6 AND 320 -- https://en.wikipedia.org/wiki/Email_address
    AND VALUE LIKE '_%@_%.__%'            -- rough, but quick check email syntax
    --AND is_email(VALUE)                 -- accurate, but very slow check email syntax, so don't use it in domain!
);

COMMENT ON DOMAIN email IS 'Aдрес электронной почты с минимальной, но быстрой валидацией';

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
