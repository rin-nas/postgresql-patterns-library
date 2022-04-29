--https://habr.com/ru/company/hflabs/blog/333736/

CREATE DOMAIN kladr AS text CHECK(octet_length(VALUE) IN (13, 17, 19) AND VALUE ~ '^\d+$');
COMMENT ON DOMAIN kladr IS 'Идентификатор КЛАДР';

--TEST
select '1234567890123'::kladr; --ok
select '78000000000172700'::kladr; --ok
select '1234567890123456789'::kladr; --ok

select '1234567890'::kladr; --error

    
