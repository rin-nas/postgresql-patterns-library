-- Adapted by Rinat from https://stackoverflow.com/questions/8316164/convert-hex-in-text-representation-to-decimal-number/8316731

-- maximum length(hexval) is 32!
create or replace function hex_to_bigint(hexval text)
    returns bigint
    returns null on null input
    stable
    parallel safe
    language sql
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
        assert hex_to_bigint(md5('test')) = -3756160627640895497; --convert MD5 to BigInt
    end
$$;
