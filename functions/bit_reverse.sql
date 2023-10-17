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
    loop
        exit when n = 0;
        rev = rev << 1;
        if (n & 1) = 1 then
            rev = rev # 1;
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
    assert public.bit_reverse(B'00001011'::int) = B'00001101'::int;
    assert public.bit_reverse(B'11101001'::int) = B'10010111'::int;
end;
$$;
