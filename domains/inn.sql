CREATE DOMAIN inn AS text CHECK(is_inn10(VALUE) OR is_inn12(VALUE));
COMMENT ON DOMAIN inn IS 'ИНН юридического или физического лица или ИП';

--TESTS
select '7725088527'::inn; --ok
select '7715034360'::inn10; --ok
select '773370857141'::inn; --ok
select '344809916052'::inn12; --ok

select '1234567890'::inn; --error
select '123456789012'::inn; --error
select '1234567890'::inn10; --error
select '123456789012'::inn12; --error

select '12345678901'::inn; --error
select '1234567890123'::inn; --error
select '12345678901'::inn10; --error
select '1234567890123'::inn12; --error
