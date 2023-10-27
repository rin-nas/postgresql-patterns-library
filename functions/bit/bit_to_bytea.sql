create or replace function public.bit_to_bytea(bits bit varying)
    returns bytea
    immutable
    strict -- returns null if any parameter is null
    parallel safe -- Postgres 10 or later
    security invoker
    language sql
    set search_path = ''
as $func$
    select public.bytea_agg(
                decode(
                    lpad(
                        to_hex(substring(bits8 from i * 8 + 1 for 8)::int),
                        2,
                        '0'
                    ),
                    'hex'
                )
           )
    from octet_length(bits) as len
    cross join generate_series(0, len - 1) as i
    cross join public.bit_rpad(bits, len * 8, B'0') as bits8; --trailing with zeros (aligned with byte boundaries)
$func$;

comment on function public.bit_to_bytea(bits bit varying) is 'Converts bit varying to bytea type';

--TEST
do $$
    begin
        assert public.bit_to_bytea(B'1101100111011000111001101011000011100011010011') = '\xD9D8E6B0E34C';
    end;
$$;
