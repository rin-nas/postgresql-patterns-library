-- TODO переделать и упростить, см. https://stackoverflow.com/questions/8316164/convert-hex-in-text-representation-to-decimal-number/8335376#8335376

-- Adapted by Rinat from https://stackoverflow.com/questions/8316164/convert-hex-in-text-representation-to-decimal-number/8316731

-- maximum length(hexval) is 32!
create or replace function public.hex_to_bigint(hexval text)
    returns bigint
    returns null on null input
    stable
    parallel safe
    language sql
    set search_path = ''
as
$$
select bit_or(get_byte(
                      decode(lpad(hexval, 32, '0'), 'hex')
                  , g)::int8 << ((15 - g) * 8))
from generate_series(0, 15) as g
$$;

-- TEST
do $$
    begin
        assert public.hex_to_bigint(md5('test')) = -3756160627640895497; --convert MD5 to BigInt
    end
$$;
