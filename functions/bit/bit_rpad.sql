create or replace function public.bit_rpad(bits bit varying, length int, fill bit)
    returns bit varying
    immutable
    strict -- returns null if any parameter is null
    parallel safe -- Postgres 10 or later
    security invoker
    language sql
    set search_path = ''
AS $func$
    select case when len > length then substring(bits from 1 for length)
                when len < length then bits || public.bin(fill::int, length - len)
                else bits
           end
    from bit_length(bits) as len
$func$;

comment on function public.bit_rpad(bits bit varying, length int, fill bit) is 'Right pad for bit string';
