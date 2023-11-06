create or replace function public.shannon_entropy(s text)
    returns numeric
    immutable
    strict -- returns null if any parameter is null
    parallel safe -- Postgres 10 or later
    security invoker
    language sql
    set search_path = ''
as $func$
    with f(f) as (
        select count(*) * 1.0 / l.l
        from regexp_split_to_table(shannon_entropy.s, '') as c(c)
           , length(shannon_entropy.s) as l(l)
        group by c.c, l.l
    )
    select -1 * sum(f.f * log(2, f.f))
    from f
$func$;

comment on function public.shannon_entropy(s text) is $$
Calculates Shannon entropy.
Энтропия ограничивает максимально возможное сжатие информации без потерь.
Согласно теореме Шеннона, существует предел сжатия без потерь, зависящий от энтропии источника.
Чем более предсказуемы получаемые данные, тем лучше их можно сжать.
Случайная независимая равновероятная последовательность сжатию без потерь не поддаётся.
https://en.wikipedia.org/wiki/Entropy_coding
$$;

-- TEST
do $$
    begin
        assert public.shannon_entropy('zzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzz') = 0;
        assert public.shannon_entropy('AABC') = 1.5;
        assert round(public.shannon_entropy('0123456789'), 2) = 3.32;
        assert round(public.shannon_entropy('abracadabra'), 2) = 2.04;
        assert round(public.shannon_entropy('Ехал Грека через реку. Видит Грека в реке рак. Сунул Грека руку в реку. Рак за руку Греку цап!'), 2) = 3.81;
    end;
$$