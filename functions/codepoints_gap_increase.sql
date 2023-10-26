create or replace function public.codepoints_gap_increase(a int[])
    returns int[]
    immutable
    strict -- returns null if any parameter is null
    parallel safe -- Postgres 10 or later
    security invoker
    language sql
    set search_path = ''
as $func$
    select array(
        select case when u.e > a[1] then u.e + a[2] - 1
                    else u.e
               end
        from unnest(a[3:]) as u(e)
    );
$func$;

comment on function public.codepoints_gap_increase(a int[]) is 'Функция, обратная к public.codepoints_gap_decrease(a int[])';

-- TEST
do $$
    begin
        assert public.codepoints_gap_increase('{36,69,37,44,47,47,41,36,44,37,37,47,37}') = '{105,112,115,115,109,36,112,105,105,115,105}';
        assert public.codepoints_gap_increase('{1,1,2,1}') = '{2,1}';
        assert public.codepoints_gap_increase('{1,1,1}') = '{1}';
        assert public.codepoints_gap_increase('{}') = '{}';
    end;
$$;
