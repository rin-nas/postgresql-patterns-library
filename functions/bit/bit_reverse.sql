create or replace function public.bit_reverse(n int)
    returns int
    immutable
    strict -- returns null if any parameter is null
    parallel safe -- Postgres 10 or later
    security invoker
    language plpgsql
    set search_path = ''
AS $func$
DECLARE
    rev int := 0;
BEGIN
    -- adapted from https://www.geeksforgeeks.org/reverse-actual-bits-given-number/
    while n > 0 loop
        rev := rev << 1;
        if (n & 1) = 1 then
            rev := rev # 1;
        end if;
        n = n >> 1;
    end loop;
    return rev;
END;
$func$;

comment on function public.bit_reverse(n int) is $$
    Given a non-negative integer n.
    The problem is to reverse the bits of n and print the number obtained after reversing the bits.
    Note that the actual binary representation of the number is being considered for reversing the bits, no leadings 0’s are being considered.
$$;

--TEST
do $$
    begin
        --negative
        assert public.bit_reverse(-1) = 0;

        --zero
        assert public.bit_reverse(0) = 0;

        --positive
        assert public.bit_reverse(B'00001011'::int) = B'00001101'::int;
        assert public.bit_reverse(B'11101001'::int) = B'10010111'::int;

        assert public.bit_reverse(11) = 13;
        assert public.bit_reverse(10) = 5;

    end;
$$;

------------------------------------------------------------------------------------------------------------------------

create or replace function public.bit_reverse(n int, r int)
    returns int
    immutable
    strict -- returns null if any parameter is null
    parallel safe -- Postgres 10 or later
    security invoker
    language plpgsql
    set search_path = ''
AS $func$
DECLARE
    rev int := 0;
BEGIN
    -- adapted from https://www.geeksforgeeks.org/reverse-actual-bits-given-number/
    for i in 1..r loop
        rev := rev << 1;
        if (n & 1) = 1 then
            rev := rev # 1;
        end if;
        n = n >> 1;
    end loop;
    return rev;
END;
$func$;

comment on function public.bit_reverse(n int, r int) is $$
    Given a non-negative integer n.
    The problem is to reverse the bits of n and print the number obtained after reversing the bits.
    Note that the actual binary representation of the number is being considered for reversing the bits, no leadings 0’s are being considered.
$$;


--TEST
do $$
    begin
        --negative
        assert public.bit_reverse(-1) = 0;

        --zero
        assert public.bit_reverse(0) = 0;

        --positive
        assert public.bit_reverse(B'01'::int, 2) = B'10'::int;
        assert public.bit_reverse(B'10'::int, 2) = B'01'::int;
        assert public.bit_reverse(B'1011'::int, 4) = B'1101'::int;
        assert public.bit_reverse(B'1011'::int, 5) = B'11010'::int;
        assert public.bit_reverse(B'1011'::int, 6) = B'110100'::int;
        assert public.bit_reverse(B'10110'::int, 5) = B'01101'::int;
        assert public.bit_reverse(B'01011'::int, 5) = B'11010'::int;
    end;
$$;
