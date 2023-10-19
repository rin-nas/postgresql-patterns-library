create or replace function public.bin(n int)
    returns bit
    immutable
    strict -- returns null if any parameter is null
    parallel safe -- Postgres 10 or later
    security invoker
    language sql
    set search_path = ''
AS $func$
select
    case (case when pos = 0 then 1 else 33 - pos end)
        when 1 then n::bit(1)
        when 2 then n::bit(2)
        when 3 then n::bit(3)
        when 4 then n::bit(4)
        when 5 then n::bit(5)
        when 6 then n::bit(6)
        when 7 then n::bit(7)
        when 8 then n::bit(8)
        when 9 then n::bit(9)
        when 10 then n::bit(10)
        when 11 then n::bit(11)
        when 12 then n::bit(12)
        when 13 then n::bit(13)
        when 14 then n::bit(14)
        when 15 then n::bit(15)
        when 16 then n::bit(16)
        when 17 then n::bit(17)
        when 18 then n::bit(18)
        when 19 then n::bit(19)
        when 20 then n::bit(20)
        when 21 then n::bit(21)
        when 22 then n::bit(22)
        when 23 then n::bit(23)
        when 24 then n::bit(24)
        when 25 then n::bit(25)
        when 26 then n::bit(26)
        when 27 then n::bit(27)
        when 28 then n::bit(28)
        when 29 then n::bit(29)
        when 30 then n::bit(30)
        when 31 then n::bit(31)
        when 32 then n::bit(32)
    end
from position(B'1' in n::bit(32)) as pos
$func$;

comment on function public.bin(n int) is 'Convert from an integer into a bit representation';

--TEST
DO $$
    BEGIN
        assert bin(-2147483648) = B'10000000000000000000000000000000';
        assert bin(-4)          = B'11111111111111111111111111111100';
        assert bin(-3)          = B'11111111111111111111111111111101';
        assert bin(-2)          = B'11111111111111111111111111111110';
        assert bin(-1)          = B'11111111111111111111111111111111';
        assert bin(0)           = B'0';
        assert bin(1)           = B'1';
        assert bin(2)           = B'10';
        assert bin(3)           = B'11';
        assert bin(4)           = B'100';
        assert bin(8)           = B'1000';
        assert bin(16)          = B'10000';
        assert bin(2147483647)  = B'1111111111111111111111111111111';
    END
$$;
