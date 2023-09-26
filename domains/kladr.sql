--https://ru.wikipedia.org/wiki/Классификатор_адресов_Российской_Федерации
--https://habr.com/ru/company/hflabs/blog/333736/

/*
Структура кода
    СС РРР ГГГ ППП АА — 13 цифр
    СС РРР ГГГ ППП УУУУ АА — 17 цифр
    СС РРР ГГГ ППП УУУУ ДДДД — 19 цифр
где
    СС – код субъекта Российской Федерации (региона), коды регионов представлены в Приложении 2 к описанию КЛАДР
    РРР – код района
    ГГГ – код города
    ППП – код населенного пункта
    УУУУ – код улицы
    АА – признак актуальности адресного объекта
*/

CREATE DOMAIN public.kladr AS text CHECK(octet_length(VALUE) IN (13, 17, 19) AND VALUE ~ '^\d+$');

COMMENT ON DOMAIN public.kladr IS 'Идентификатор КЛАДР';

--TEST
select '1234567890123'::public.kladr; --ok
select '78000000000172700'::public.kladr; --ok
select '1234567890123456789'::public.kladr; --ok

select '1234567890'::public.kladr; --error
