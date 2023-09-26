CREATE DOMAIN public.inn AS text CHECK(public.is_inn10(VALUE) OR public.is_inn12(VALUE));
COMMENT ON DOMAIN public.inn IS 'ИНН юридического или физического лица или ИП';

--TESTS
select '7725088527'::public.inn; --ok
select '7715034360'::public.inn10; --ok
select '773370857141'::public.inn; --ok
select '344809916052'::public.inn12; --ok

select '1234567890'::public.inn; --error
select '123456789012'::public.inn; --error
select '1234567890'::public.inn10; --error
select '123456789012'::public.inn12; --error

select '12345678901'::public.inn; --error
select '1234567890123'::public.inn; --error
select '12345678901'::public.inn10; --error
select '1234567890123'::public.inn12; --error
