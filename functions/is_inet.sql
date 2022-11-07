create or replace function public.is_inet(str text, is_notice boolean default false)
    returns boolean
    returns null on null input
    parallel unsafe --(ERROR:  cannot start subtransactions during a parallel operation)
    stable
    language plpgsql
    cost 5
as
$func$
DECLARE
    exception_sqlstate text;
    exception_message text;
    exception_context text;
    oct_length constant int default octet_length(str);

BEGIN
    --https://en.wikipedia.org/wiki/Classless_Inter-Domain_Routing

    --try to detect IPv4
    if oct_length between 7  --0.0.0.0
                      and 18 --255.255.255.255/32
                      and str like '%.%.%.%'
                      and exists(
        select
        from regexp_matches(str,
                            $regexp$
                              ^
                              (\d{1,3}) \. (\d{1,3}) \. (\d{1,3}) \. (\d{1,3}) #1-4 addr 0..255
                              (?:
                                  / (\d{1,2}) #5 mask 0..32
                              )?
                              $
                            $regexp$, 'x') as t(m)
        where not exists(select
                         from unnest(m[1:4]) u(e)
                         where e::int > 255)
          and (m[5] is null or m[5]::int < 33)
    )
    then
        return true;
    end if;

    --try to detect IPv6
    --https://stackoverflow.com/questions/166132/maximum-length-of-the-textual-representation-of-an-ipv6-address
    --https://stackoverflow.com/questions/53497/regular-expression-that-matches-valid-ipv6-addresses
    if not (oct_length between 2  --::
                           and 45 --0000:0000:0000:0000:0000:ffff:255.255.255.255
                           and str like '%:%:%') then
        return false;
    end if;

    --slow exception block
    BEGIN
        return (str::inet is not null);
    EXCEPTION WHEN others THEN
        IF is_notice THEN
            GET STACKED DIAGNOSTICS
                exception_sqlstate := RETURNED_SQLSTATE,
                exception_message  := MESSAGE_TEXT,
                exception_context  := PG_EXCEPTION_CONTEXT;
            RAISE NOTICE 'exception_sqlstate = %', exception_sqlstate;
            RAISE NOTICE 'exception_context = %', exception_context;
            RAISE NOTICE 'exception_message = %', exception_message;
        END IF;
        RETURN FALSE;
    END;
END;
$func$;

comment on function public.is_inet(str text, is_notice boolean) is 'Check IPv4 or IPv6 host address, and optionally its subnet';

--TEST
do $do$
    begin
        --positive IPv4
        assert public.is_inet('0.0.0.0');
        assert public.is_inet('1.2.3.4');
        assert public.is_inet('11.22.33.44');
        assert public.is_inet('255.255.255.255');
        assert public.is_inet('1.2.3.4/0');
        assert public.is_inet('1.2.3.4/32');

        --positive IPv6
        assert public.is_inet('::');
        assert public.is_inet('1::');
        assert public.is_inet('::1');
        assert public.is_inet('1:2:3:4:5:6:7:8');
        assert public.is_inet('fe80::71d0:1c39:21c7:e566');
        assert public.is_inet('::255.255.255.255');
        assert public.is_inet('::ffff:0:255.255.255.255');
        assert public.is_inet('0000:0000:0000:0000:0000:ffff:255.255.255.255');
        assert public.is_inet('1:2:3:4:5:6:7:8/0');
        assert public.is_inet('1:2:3:4:5:6:7:8/128');

        --negative IPv4
        assert not public.is_inet('1.2.3.4.');
        assert not public.is_inet('.1.2.3.4');
        assert not public.is_inet('1:2:3.4');
        assert not public.is_inet('0.0.0');
        assert not public.is_inet('255.255.255.256');
        assert not public.is_inet('192.168.0.1/-1');
        assert not public.is_inet('192.168.0.1/33');

        --negative IPv6
        assert not public.is_inet(':1:2:3:4:5:6:7:8');
        assert not public.is_inet('1:2:3:4:5:6:7:8:');
        assert not public.is_inet('1:2:3:4:5:6:7:8/-1');
        assert not public.is_inet('1:2:3:4:5:6:7:8/129');
        assert not public.is_inet('98:fa:9b:52:59:f3');
    end
$do$;
