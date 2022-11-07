create or replace function grep_inet(str text)
    returns table (order_num int, "all" text, addr inet, port int, mask int)
    stable
    returns null on null input
    parallel safe -- Postgres 10 or later
    language sql
as $func$
    select (row_number() over ())::int as order_num,
        m[1] as all,
        array_to_string(m[2:5], '.')::inet as addr,
        m[6]::int as port,
        m[7]::int as mask
    from regexp_matches(str,
                        $$
                          ( #1 all
                              (?<![\d.:/]) #boundary
                              (\d{1,3}) \. (\d{1,3}) \. (\d{1,3}) \. (\d{1,3}) #2-5 addr 0..255
                              (?:
                                  : (\d{1,5}) #6 port 1..65535
                                | / (\d{1,2}) #7 mask 0..32
                              )?
                              (?![\d.:/]) #boundary
                          )
                        $$, 'xg') as t(m)
    where not exists(select
                     from unnest(m[2:5]) u(e)
                     where e::int not between 0 and 255)
      and (m[6] is null or m[6]::int between 1 and 65535)
      and (m[7] is null or m[7]::int between 0 and 32);
$func$;

comment on function grep_inet(str text) is $$
    Захватывает из строки все существующие IP адреса.
    IP адрес может иметь необязательный порт или маску.
$$;

--TEST
do $do$
declare
    str_in constant text not null default $$
    #valid
    0.0.0.0
    1.2.3.4
    -1.2.3.4
    1.2.3.4-
    01.02.03.04
    001.002.003.004
    9.9.9.9
    10.10.10.10
    99.99.99.99
    100.100.100.100
    255.255.255.255
    127.0.0.1
    192.168.1.1:1
    192.168.1.255:65535
    192.168.1.1/0
    192.168.1.255/32

    #invalid octet range
    256.2.3.4
    1.256.3.4
    1.2.256.4
    1.2.3.256

    #invalid boundary
    1.1.1.1.
    1.1.1.1/
    1.1.1.1:

    1.1.1.1:9.
    1.1.1.1:99:
    1.1.1.1:999/

    1.1.1.1/0.
    1.1.1.1/32:
    1.1.1.1/32/

    .2.2.2.2
    :2.2.2.2
    /2.2.2.2

    #invalid length
    1.2.3.4.5
    1.2.3
    0.1
    3...3

    #invalid mask
    5.5.5.5/-1
    5.5.5.5/33

    #invalid port
    5.5.5.5:0
    5.5.5.5:65536
    $$;

    str_out constant text not null default '[{"order_num":1,"all":"0.0.0.0","addr":"0.0.0.0","port":null,"mask":null}, {"order_num":2,"all":"1.2.3.4","addr":"1.2.3.4","port":null,"mask":null}, {"order_num":3,"all":"1.2.3.4","addr":"1.2.3.4","port":null,"mask":null}, {"order_num":4,"all":"1.2.3.4","addr":"1.2.3.4","port":null,"mask":null}, {"order_num":5,"all":"01.02.03.04","addr":"1.2.3.4","port":null,"mask":null}, {"order_num":6,"all":"001.002.003.004","addr":"1.2.3.4","port":null,"mask":null}, {"order_num":7,"all":"9.9.9.9","addr":"9.9.9.9","port":null,"mask":null}, {"order_num":8,"all":"10.10.10.10","addr":"10.10.10.10","port":null,"mask":null}, {"order_num":9,"all":"99.99.99.99","addr":"99.99.99.99","port":null,"mask":null}, {"order_num":10,"all":"100.100.100.100","addr":"100.100.100.100","port":null,"mask":null}, {"order_num":11,"all":"255.255.255.255","addr":"255.255.255.255","port":null,"mask":null}, {"order_num":12,"all":"127.0.0.1","addr":"127.0.0.1","port":null,"mask":null}, {"order_num":13,"all":"192.168.1.1:1","addr":"192.168.1.1","port":1,"mask":null}, {"order_num":14,"all":"192.168.1.255:65535","addr":"192.168.1.255","port":65535,"mask":null}, {"order_num":15,"all":"192.168.1.1/0","addr":"192.168.1.1","port":null,"mask":0}, {"order_num":16,"all":"192.168.1.255/32","addr":"192.168.1.255","port":null,"mask":32}]';
begin
    --positive and negative both
    assert (select json_agg(to_json(t))::text = str_out
            from grep_inet(str_in) as t);
end;
$do$;
