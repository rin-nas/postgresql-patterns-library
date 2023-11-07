CREATE OR REPLACE FUNCTION public.bit_get(num bigint, pos int)
    returns bool
    stable
    returns null on null input
    security invoker
    parallel safe
    language plpgsql
    set search_path = ''
AS $$
begin
    if num < 0 then
        raise exception 'First procedure argument should be >= 0, but % given', num;
    elsif pos not between 1 and 64 then
        raise exception 'Second procedure argument should be between 1 and 64, but % given', pos;
    end if;
    return (num & (1 << (pos - 1))) > 0;
end
$$;

comment on function public.bit_get(num bigint, pos int)
    is 'Проверяет для числа в заданной позиции, установлен ли бит в 1';

--TEST
do $$
begin
    assert not public.bit_get(7, 4);
    assert public.bit_get(8, 4);
    assert public.bit_get(13, 4);
end;
$$;
