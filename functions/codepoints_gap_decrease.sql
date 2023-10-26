create or replace function public.codepoints_gap_decrease(a int[])
    returns int[]
    immutable
    strict -- returns null if any parameter is null
    parallel safe -- Postgres 10 or later
    security invoker
    language sql
    set search_path = ''
as $func$
    select array(
        with u (e) as (
            select unnest(codepoints_gap_decrease.a)
        ),
        gap (e, distance) as (
            select u.e,
                   coalesce(lead(u.e) over (order by u.e) - u.e, 1)
            from u
            order by 2 desc nulls last
            limit 1
        )
        select gap.e from gap
        union all
        select gap.distance from gap
        union all
        select case when u.e > gap.e then u.e - gap.distance + 1
                    else u.e
               end
        from u
        cross join gap
    );
$func$;

comment on function public.codepoints_gap_decrease(a int[]) is $$
    Используется для улучшения сжатия последовательности юникод кодов универсальными кодами.
    Хорошо работает только для текстов на русском и других языках с юникод кодами > 255.
    Находит максимальную дистанцию между двумя последовательными элементами отсортированного числового массива.
    На промежуточном этапе получает значение найденного элемента (E) и дистанцию до следующего элемента массива (D).
    Затем для всех элементов N > E: N = N - D + 1.
    Добавляет в конец массива 2 элемента N, D и возвращает итоговый массив.
$$;

-- TEST
do $$
    begin
        assert public.codepoints_gap_decrease('{105,112,115,115,109,36,112,105,105,115,105}') = '{36,69,37,44,47,47,41,36,44,37,37,47,37}';
        assert public.codepoints_gap_decrease('{2,1}') = '{1,1,2,1}';
        assert public.codepoints_gap_decrease('{1}') = '{1,1,1}';
        assert public.codepoints_gap_decrease('{}') = '{}';
    end;
$$;

