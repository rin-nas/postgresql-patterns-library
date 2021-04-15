-- Проверяет на корректность ИНН юридического лица
-- https://ru.wikipedia.org/wiki/Идентификационный_номер_налогоплательщика
create or replace function is_inn10(inn text) returns boolean
    immutable
    strict
    parallel safe -- Postgres 10 or later
    language plpgsql
as
$$
DECLARE
    controlSum integer := 0;
    digits integer[];
BEGIN

    IF length(inn) != 10 or inn !~ '^\d+$' THEN
        return FALSE;
    END IF;

    digits = regexp_split_to_array(inn, '')::integer[];

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

comment on function is_inn10(text) is 'Проверяет правильность ИНН юридического лица';

-- Проверяет на корректность ИНН физического лица или индивидуального предпринимателя
-- https://ru.wikipedia.org/wiki/Идентификационный_номер_налогоплательщика
create or replace function is_inn12(inn text) returns boolean
    immutable
    strict
    parallel safe -- Postgres 10 or later
    language plpgsql
as
$$
DECLARE
    controlSum1 integer := 0;
    controlSum2 integer := 0;
    digits integer[];
BEGIN

    IF length(inn) != 12 or inn !~ '^\d+$' THEN
        return FALSE;
    END IF;

    digits = regexp_split_to_array(inn, '')::integer[];

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

comment on function is_inn12(text) is 'Проверяет правильность ИНН физического лица или индивидуального предпринимателя';

DO $$
BEGIN
    --positive
    ASSERT is_inn10('7725088527');
    ASSERT is_inn10('7715034360');
    ASSERT is_inn12('773370857141');
    ASSERT is_inn12('344809916052');

    --negative 1 check sum
    ASSERT NOT is_inn10('7725088528');
    ASSERT NOT is_inn10('7715034361');
    ASSERT NOT is_inn12('773370857142');
    ASSERT NOT is_inn12('344809916053');

    --negative 2 check length
    ASSERT NOT is_inn10('772508852');
    ASSERT NOT is_inn12('77337085714');

    --negative 3 check digits
    ASSERT NOT is_inn10('qwertyuiop');
    ASSERT NOT is_inn12('qwertyuiopas');
END $$;
