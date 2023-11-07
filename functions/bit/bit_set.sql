CREATE OR REPLACE FUNCTION public.bit_set(num bigint, pos int, val boolean)
    returns bigint
    stable
    returns null on null input
    security invoker
    parallel safe
    language plpgsql
    set search_path = ''
AS $$
DECLARE
    mask bigint default 1 << (pos - 1);
begin
    if num < 0 then
        raise exception 'First procedure argument should be >= 0, but % given', num;
    elsif pos not between 1 and 64 then
        raise exception 'Second procedure argument should be between 1 and 64, but % given', pos;
    end if;
    if val then
        return num | mask;
    else
        return num & ~mask;
    end if;
end
$$;

comment on function public.bit_set(num bigint, pos int, val boolean)
    is 'Устанавливает для числа в заданной позиции бит в 1 или 0';

--TEST
do $$
begin
    assert public.bit_set(8, 4, false) = 0;
    assert public.bit_set(9, 4, false) = 1;
    assert public.bit_set(25, 5, false) = 9;
end;
$$;
