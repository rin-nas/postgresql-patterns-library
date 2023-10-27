create or replace function public.bit_from_bytea(data bytea)
    returns bit varying
    immutable
    strict -- returns null if any parameter is null
    parallel safe -- Postgres 10 or later
    security invoker
    language sql
    set search_path = ''
as $func$
    select public.bit_agg(
               get_byte(
                   substring(bit_from_bytea.data from g.i for 1),
                   0
               )::bit(8)
           )
    from generate_series(1, octet_length(bit_from_bytea.data)) as g(i);
$func$;

comment on function public.bit_from_bytea(data bytea) is 'Converts bytea to bit varying type';

--TEST
do $$
    begin
        assert public.bit_from_bytea('\x11d481c8e032988e9763fd2780')
               = B'00010001110101001000000111001000111000000011001010011000100011101001011101100011111111010010011110000000';
    end;
$$;
