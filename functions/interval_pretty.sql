create or replace function public.interval_pretty(interval)
    returns text
    immutable
    returns null on null input
    parallel safe
    language sql
    set search_path = ''
return
    case when $1 =   '0'::interval then '0ms'
         when $1 <  '1s'::interval then regexp_replace(to_char($1,                    'FMMS"ms"'),       '^0+(?=\d+ms$)', '')
         when $1 < '10s'::interval then regexp_replace(to_char($1,            'FMSS"s" FMMS"ms"'), '(?<!\d)0+(?=\d+ms$)', '')
         when $1 <  '1m'::interval then to_char($1,                           'FMSS"s"')
         when $1 <  '1h'::interval then to_char($1,                   'FMMI"m" FMSS"s"')
         when $1 <  '1d'::interval then to_char($1,         'FMHH24"h" FMMI"m" FMSS"s"')
         else                           to_char($1, 'FMDD"d" FMHH24"h" FMMI"m" FMSS"s"')
    end;

comment on function public.interval_pretty(interval) is 'Форматирует интервал (период времени) в читабельном виде';

/*
Без форматирования результат будет выглядеть примерно так:
7 days 17:20:48.576262  - длина 22 символа
00:00:00.000706         - минимальная длина 15 символов
Здесь много лишних нулей, а точность в микросекундах уже не интересна (миллисекунд достаточно).
Информационный шум ни к чему.
*/

--TEST
DO $do$
    BEGIN
        --positive
        assert public.interval_pretty(null) is null;
        assert public.interval_pretty('99d 23h 23m 59s 123ms'::interval) = '99d 23h 23m 59s';
        assert public.interval_pretty('10d 10h 10m 10s 100ms'::interval) = '10d 10h 10m 10s';
        assert public.interval_pretty( '0d 23h 23m 59s 101ms'::interval) =     '23h 23m 59s';
        assert public.interval_pretty( '0d  0h 23m 59s 110ms'::interval) =         '23m 59s';
        assert public.interval_pretty( '0d  0h  0m 10s 123ms'::interval) =             '10s';
        assert public.interval_pretty( '0d  0h  0m 10s   0ms'::interval) =             '10s';
        assert public.interval_pretty( '0d  0h  0m  9s 123ms'::interval) =              '9s 123ms';
        assert public.interval_pretty( '0d  0h  0m  1s   0ms'::interval) =                '1s 0ms';
        assert public.interval_pretty( '0d  0h  0m  0s 100ms'::interval) =                 '100ms';
        assert public.interval_pretty( '0d  0h  0m  0s 101ms'::interval) =                 '101ms';
        assert public.interval_pretty( '0d  0h  0m  0s 110ms'::interval) =                 '110ms';
        assert public.interval_pretty( '0d  0h  0m  0s 999ms'::interval) =                 '999ms';
        assert public.interval_pretty( '0d  0h  0m  0s  99ms'::interval) =                  '99ms';
        assert public.interval_pretty( '0d  0h  0m  0s  10ms'::interval) =                  '10ms';
        assert public.interval_pretty( '0d  0h  0m  0s   1ms'::interval) =                   '1ms';
        assert public.interval_pretty( '0d  0h  0m  0s   0ms'::interval) =                   '0ms';
        assert public.interval_pretty('00:00:00.000706'::interval)       =                   '0ms';

        --negative

    END;
$do$;
