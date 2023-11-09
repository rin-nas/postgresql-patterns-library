create or replace function public.bwt_decode(s text, eob char)
    returns text
    immutable
    strict -- returns null if any parameter is null
    parallel safe -- Postgres 10 or later
    security invoker
    language sql
    set search_path = ''
as $func$

    --https://youtu.be/meKCBruvPZ0?t=1110
    --http://guanine.evolbio.mpg.de/cgi-bin/bwt/bwt.cgi.pl
    --https://www.dcode.fr/burrows-wheeler-transform
    with recursive s as (
        select row_number() over (order by t.char collate "C", next_pos) as pos,
               t.char,
               t.next_pos
        from unnest(string_to_array(bwt_decode.s, null)) with ordinality as t(char, next_pos)
        where t.char != ''
    )
    --select * from s; --test
    , r as (
        select s.char, s.next_pos
        from s
        where s.char = bwt_decode.eob --end of block
        union all
        select s.char, s.next_pos
        from r
        inner join s on s.pos = r.next_pos and s.char != bwt_decode.eob
    )
    , o as (
        select array_to_string(array(
                   select r.char
                   from r
                   offset 1 --without eob
               ), '') as s
    )
    select case when octet_length(o.s) + octet_length(bwt_decode.eob) = octet_length(bwt_decode.s) then o.s end
    from o

$func$;

comment on function public.bwt_decode(s text, eob char) is $$
    https://en.wikipedia.org/wiki/Burrows%E2%80%93Wheeler_transform
    Returns null for invalid input string
$$;

--TEST
do $$
    begin
        --positive
        assert public.bwt_decode('cc$aabb', '$') = 'abcabc';
        assert public.bwt_decode('ard$rcaaaabb', '$') = 'abracadabra';
        assert public.bwt_decode('ард$краааабб', '$') = 'абракадабра';
        assert public.bwt_decode('sinniieffcc$eie', '$') = 'inefficiencies';
        assert public.bwt_decode('aa$nmnnPBaaaa', '$') = 'PanamaBanana';
        select public.bwt_decode('TOOOBBBRRTTTEEENNOOOOR$TO', '$') = 'TOBEORNOTTOBEORTOBEORNOT';

        assert public.bwt_decode('STEXYDST.E.IXXIIXXSSMPPS.B..EE.$.USFXDIIOIIIT', '$')
                               = 'SIX.MIXED.PIXIES.SIFT.SIXTY.PIXIE.DUST.BOXES';

        select public.bwt_decode('.тллу..аукевзваауап!уук     $  кзккРрхц  икррррррррче Вдааееееууеееуауа еГГГ Г    икккккррнСЕ  ', '$')
                               = 'Ехал Грека через реку. Видит Грека в реке рак. Сунул Грека руку в реку. Рак за руку Греку цап!';

        --negative
        assert public.bwt_decode('ardr$caaaabb', '$') is null;
        assert public.bwt_decode('ardrcaaaabb', '$') is null;
        assert public.bwt_decode('ardrcaaaabb', '') is null;
        assert public.bwt_decode('', '') = '';
    end;
$$;
