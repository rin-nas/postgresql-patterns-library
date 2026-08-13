create or replace function public.interval_pretty(interval)
    returns text
    immutable
    returns null on null input
    parallel safe
    language sql
    set search_path = ''
return
    case when $1 = '0'::interval then '0ms'
         when greatest($1, $1 * -1) <  '1s'::interval then regexp_replace(to_char($1,                    'FMMS"ms"'), '(?<!\d)0+(?=\d+ms$)', '')
         when greatest($1, $1 * -1) < '10s'::interval then regexp_replace(to_char($1,            'FMSS"s" FMMS"ms"'), '(?<!\d)0+(?=\d+ms$)', '')
         when greatest($1, $1 * -1) <  '1m'::interval then to_char($1,                           'FMSS"s"')
         when greatest($1, $1 * -1) <  '1h'::interval then to_char($1,                   'FMMI"m" FMSS"s"')
         when greatest($1, $1 * -1) <  '1d'::interval then to_char($1,         'FMHH24"h" FMMI"m"')
         else                                              to_char($1, 'FMDD"d" FMHH24"h" FMMI"m"')
    end;

comment on function public.interval_pretty(interval) is 'Formats the interval (time period) to a human readable string';

/*
Без форматирования результат будет выглядеть примерно так:
7 days 17:20:48.576262  - длина 22 символа
00:00:00.000706         - минимальная длина 15 символов
Здесь много лишних нулей, а точность в микросекундах уже не интересна (миллисекунд достаточно).
Информационный шум ни к чему.
*/

--TEST
DO $do$
    DECLARE
        sign int;
        search text;
    BEGIN
        FOREACH sign IN ARRAY array[1, -1] LOOP
            search := case when sign = -1 then '(?!0)\d+' else '_' end;

            --positive
            assert public.interval_pretty(null) is null;
            assert public.interval_pretty('99d 23h 23m 59s 123ms'::interval * sign) = regexp_replace('99d 23h 23m',           search, '-\&', 'g');
            assert public.interval_pretty('10d 10h 10m 10s 100ms'::interval * sign) = regexp_replace('10d 10h 10m',           search, '-\&', 'g');
            assert public.interval_pretty( '0d 23h 23m 59s 101ms'::interval * sign) = regexp_replace(    '23h 23m',           search, '-\&', 'g');
            assert public.interval_pretty( '0d  0h 23m 59s 110ms'::interval * sign) = regexp_replace(        '23m 59s',       search, '-\&', 'g');
            assert public.interval_pretty( '0d  0h  0m 10s 123ms'::interval * sign) = regexp_replace(            '10s',       search, '-\&', 'g');
            assert public.interval_pretty( '0d  0h  0m 10s   0ms'::interval * sign) = regexp_replace(            '10s',       search, '-\&', 'g');
            assert public.interval_pretty( '0d  0h  0m  9s 123ms'::interval * sign) = regexp_replace(             '9s 123ms', search, '-\&', 'g');
            assert public.interval_pretty( '0d  0h  0m  1s   0ms'::interval * sign) = regexp_replace(               '1s 0ms', search, '-\&', 'g');
            assert public.interval_pretty( '0d  0h  0m  0s 100ms'::interval * sign) = regexp_replace(                '100ms', search, '-\&', 'g');
            assert public.interval_pretty( '0d  0h  0m  0s 101ms'::interval * sign) = regexp_replace(                '101ms', search, '-\&', 'g');
            assert public.interval_pretty( '0d  0h  0m  0s 110ms'::interval * sign) = regexp_replace(                '110ms', search, '-\&', 'g');
            assert public.interval_pretty( '0d  0h  0m  0s 999ms'::interval * sign) = regexp_replace(                '999ms', search, '-\&', 'g');
            assert public.interval_pretty( '0d  0h  0m  0s  99ms'::interval * sign) = regexp_replace(                 '99ms', search, '-\&', 'g');
            assert public.interval_pretty( '0d  0h  0m  0s  10ms'::interval * sign) = regexp_replace(                 '10ms', search, '-\&', 'g');
            assert public.interval_pretty( '0d  0h  0m  0s   1ms'::interval * sign) = regexp_replace(                  '1ms', search, '-\&', 'g');
            assert public.interval_pretty( '0d  0h  0m  0s   0ms'::interval * sign) = regexp_replace(                  '0ms', search, '-\&', 'g');
            assert public.interval_pretty('00:00:00.000706'      ::interval * sign) = regexp_replace(                  '0ms', search, '-\&', 'g');

            --negative
        END LOOP;

    END;
$do$;
