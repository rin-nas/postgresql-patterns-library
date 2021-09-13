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


--TEST
do $$
BEGIN
    assert not bit_get(7, 4);
    assert bit_get(8, 4);
    assert bit_get(13, 4);
end;
$$;
