create or replace function use_cpu(
    id bigint,
    cpu_num integer,
    cpu_max integer
)
    -- Функция предназначена для распараллеливания SQL запросов
    -- Принимает решение, использовать преданный номер процессора или нет
    -- Пример: WHERE use_cpu(id, 1, 5)
    returns boolean
    stable
    returns null on null input
    parallel safe
    language plpgsql
as
$$
BEGIN
    IF cpu_num NOT BETWEEN 1 AND 256 THEN
        RAISE EXCEPTION 'Argument cpu_num should be between 1 and 256, but % given!', cpu_num;
    ELSIF cpu_max NOT BETWEEN 1 AND 256 THEN
        RAISE EXCEPTION 'Argument cpu_max should be between 1 and 256, but % given!', cpu_max;
    ELSIF cpu_num > cpu_max THEN
        RAISE EXCEPTION 'Argument cpu_num should be <= cpu_max! Given cpu_num = %, cpu_max = %', cpu_num, cpu_max;
    END IF;

    RETURN abs(id) % cpu_max = cpu_num - 1;
END;
$$;

--TEST
--select sum(use_cpu(g, 1, 2)::int) from generate_series(1, 10000) as g; --5000

create or replace function use_cpu(
    str text,
    cpu_num integer,
    cpu_max integer
)
    -- Функция предназначена для распараллеливания SQL запросов
    -- Принимает решение, использовать преданный номер процессора или нет
    -- Пример: WHERE use_cpu('mike@domain.com', 1, 5)
    returns boolean
    stable
    returns null on null input
    parallel safe
    language plpgsql
as
$$
BEGIN
    IF cpu_num NOT BETWEEN 1 AND 256 THEN
        RAISE EXCEPTION 'Argument cpu_num should be between 1 and 256, but % given!', cpu_num;
    ELSIF cpu_max NOT BETWEEN 1 AND 256 THEN
        RAISE EXCEPTION 'Argument cpu_max should be between 1 and 256, but % given!', cpu_max;
    ELSIF cpu_num > cpu_max THEN
        RAISE EXCEPTION 'Argument cpu_num should be <= cpu_max! Given cpu_num = %, cpu_max = %', cpu_num, cpu_max;
    END IF;

    RETURN abs(crc32(str)) % cpu_max = cpu_num - 1;
END;
$$;

--TEST
--select sum(use_cpu(g::text, 1, 2)::int) from generate_series(1, 10000) as g; -- 4998
