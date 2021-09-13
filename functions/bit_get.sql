CREATE OR REPLACE FUNCTION bit_get(num bigint, pos int)
    -- проверяет для числа в заданной позиции, установлен ли бит в 1
    RETURNS bool
    stable
    returns null on null input
    SECURITY INVOKER
    PARALLEL SAFE
    LANGUAGE plpgsql
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

CREATE OR REPLACE FUNCTION bit_set(num bigint, pos int, val boolean)
    -- устанавливает для числа в заданной позиции бит в 1 или 0
    RETURNS bigint
    stable
    returns null on null input
    SECURITY INVOKER
    PARALLEL SAFE
    LANGUAGE plpgsql
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

--TEST
do $$
BEGIN
    assert (bit_get(7, 4) is false);
    assert (bit_get(8, 4) is true);
    assert (bit_get(13, 4) is true);
end;
$$;
