create or replace function public.entropy(s text)
    returns numeric
    immutable
    strict -- returns null if any parameter is null
    parallel safe -- Postgres 10 or later
    security invoker
    language sql
    set search_path = ''
as $func$
    with t(freq) as (
        select count(*) * 1.0 / l.l
        from unnest(string_to_array(entropy.s, null)) as s(char)
           , char_length(entropy.s) as l(l)
        group by s.char, l.l
    )
    select -1 * sum(t.freq * log(2, t.freq))
    from t
$func$;

comment on function public.entropy(s text) is $$
Calculates Shannon entropy.
Возвращает число >= 0.

Энтропия - это среднее количество собственной информации в данных.
Энтропия рассматривается как мера беспорядка в данных.
За единицу количества информации принимается 1 бит (да/нет).

Энтропия ограничивает максимально возможное сжатие информации без потерь.
Согласно теореме Шеннона, существует предел сжатия без потерь, зависящий от энтропии источника.
Чем более предсказуемы получаемые данные, тем лучше их можно сжать.
Случайная независимая равновероятная последовательность сжатию без потерь не поддаётся.
https://en.wikipedia.org/wiki/Entropy_coding
$$;

create or replace function public.entropy(s bytea)
    returns numeric
    immutable
    strict -- returns null if any parameter is null
    parallel safe -- Postgres 10 or later
    security invoker
    language sql
    set search_path = ''
as $func$
    with t(freq) as (
        select count(*) * 1.0 / l.l
        from octet_length(entropy.s) as l(l)
           , generate_series(1, l.l) as g(i)
           , get_byte(substring(entropy.s from g.i for 1), 0) as s(code)
        group by s.code, l.l
    )
    select -1 * sum(t.freq * log(2, t.freq))
    from t
$func$;


-- TEST
do $$
    begin
        --отсортировано по возрастанию энтропии
        assert public.entropy('z') = 0;
        assert public.entropy('z'::bytea) = 0;

        assert public.entropy('zzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzz') = 0;
        assert public.entropy('zzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzz'::bytea) = 0;

        assert public.entropy('AB') = 1;
        assert public.entropy('AB'::bytea) = 1;

        assert public.entropy('AABB') = 1;
        assert public.entropy('AABB'::bytea) = 1;

        assert public.entropy('AABC') = 1.5;
        assert public.entropy('AABC'::bytea) = 1.5;

        assert round(public.entropy('abracadabra'), 2) = 2.04;
        assert round(public.entropy('abracadabra'::bytea), 2) = 2.04;

        assert round(public.entropy('абракадабра'), 2) = 2.04;
        assert round(public.entropy('абракадабра'::bytea), 2) = 2.36;

        assert round(public.entropy('0123456789'), 2) = 3.32;
        assert round(public.entropy('0123456789'::bytea), 2) = 3.32;

        assert round(public.entropy('9876543210'), 2) = 3.32;
        assert round(public.entropy('9876543210'::bytea), 2) = 3.32;

        assert round(public.entropy('Ехал Грека через реку. Видит Грека в реке рак. Сунул Грека руку в реку. Рак за руку Греку цап!'), 2) = 3.81;
        assert round(public.entropy('Ехал Грека через реку. Видит Грека в реке рак. Сунул Грека руку в реку. Рак за руку Греку цап!'::bytea), 2) = 3.54;

        assert round(public.entropy('Съешь же ещё этих мягких французских булок да выпей чаю.'), 2) = 4.78;
        assert round(public.entropy('Съешь же ещё этих мягких французских булок да выпей чаю.'::bytea), 2) = 4.06;
    end;
$$
