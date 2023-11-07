-- Проверяет на корректность ИНН физического лица или индивидуального предпринимателя
-- https://ru.wikipedia.org/wiki/Идентификационный_номер_налогоплательщика
create or replace function public.is_inn12(inn text) returns boolean
    immutable
    strict -- returns null if any parameter is null
    parallel safe -- Postgres 10 or later
    language plpgsql
    set search_path = ''
    cost 5
as
$$
DECLARE
    controlSum1 integer := 0;
    controlSum2 integer := 0;
    digits integer[];
BEGIN

    IF octet_length(inn) != 12 or inn ~ '\D' THEN
        return FALSE;
    END IF;

    digits = string_to_array(inn, null)::integer[];

    -- Проверка контрольных цифр для 12-значного ИНН
    controlSum1 :=
           7 * digits[1]
        +  2 * digits[2]
        +  4 * digits[3]
        + 10 * digits[4]
        +  3 * digits[5]
        +  5 * digits[6]
        +  9 * digits[7]
        +  4 * digits[8]
        +  6 * digits[9]
        +  8 * digits[10];

    IF (controlSum1 % 11) % 10 != digits[11] THEN
        return FALSE;
    END IF;

    controlSum2 :=
           3 * digits[1]
        +  7 * digits[2]
        +  2 * digits[3]
        +  4 * digits[4]
        + 10 * digits[5]
        +  3 * digits[6]
        +  5 * digits[7]
        +  9 * digits[8]
        +  4 * digits[9]
        +  6 * digits[10]
        +  8 * digits[11];

    RETURN (controlSum2 % 11) % 10 = digits[12];

END;
$$;

comment on function public.is_inn12(text) is 'Проверяет правильность ИНН физического лица или индивидуального предпринимателя';

--TEST

DO $$
BEGIN
    --positive
    ASSERT public.is_inn12('773370857141');
    ASSERT public.is_inn12('344809916052');

    --negative 1 check sum
    ASSERT NOT public.is_inn12('773370857142');
    ASSERT NOT public.is_inn12('344809916053');

    --negative 2 check length
    ASSERT NOT public.is_inn12('77337085714');

    --negative 3 check digits
    ASSERT NOT public.is_inn12('qwertyuiopas');
END $$;
