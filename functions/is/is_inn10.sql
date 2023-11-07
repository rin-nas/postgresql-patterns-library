-- Проверяет на корректность ИНН юридического лица
-- https://ru.wikipedia.org/wiki/Идентификационный_номер_налогоплательщика
create or replace function public.is_inn10(inn text) returns boolean
    immutable
    strict -- returns null if any parameter is null
    parallel safe -- Postgres 10 or later
    language plpgsql
    set search_path = ''
    cost 5
as
$$
DECLARE
    controlSum integer := 0;
    digits integer[];
BEGIN

    IF octet_length(inn) != 10 or inn ~ '\D' THEN
        return FALSE;
    END IF;

    digits = string_to_array(inn, null)::integer[];

    -- Проверка контрольных цифр для 10-значного ИНН
    controlSum :=
           2 * digits[1]
        +  4 * digits[2]
        + 10 * digits[3]
        +  3 * digits[4]
        +  5 * digits[5]
        +  9 * digits[6]
        +  4 * digits[7]
        +  6 * digits[8]
        +  8 * digits[9];
    RETURN  (controlSum % 11) % 10 = digits[10];

END;
$$;

comment on function public.is_inn10(text) is 'Проверяет правильность ИНН юридического лица';

--TEST

DO $$
BEGIN
    --positive
    ASSERT public.is_inn10('7725088527');
    ASSERT public.is_inn10('7715034360');

    --negative 1 check sum
    ASSERT NOT public.is_inn10('7725088528');
    ASSERT NOT public.is_inn10('7715034361');

    --negative 2 check length
    ASSERT NOT public.is_inn10('772508852');

    --negative 3 check digits
    ASSERT NOT public.is_inn10('qwertyuiop');
END $$;
