create or replace function public.bwt_encode(s text, eob char)
    returns text
    immutable
    strict -- returns null if any parameter is null
    parallel safe -- Postgres 10 or later
    security invoker
    language sql
    set search_path = ''
as $func$

    --https://www.geeksforgeeks.org/burrows-wheeler-data-transform-algorithm/
    --http://guanine.evolbio.mpg.de/cgi-bin/bwt/bwt.cgi.pl
    --https://www.dcode.fr/burrows-wheeler-transform
    with recursive r (pos, suffix) as (
        select 1, bwt_encode.s || bwt_encode.eob --end of block
        union all
        select pos + 1, right(r.suffix, -1)
        from r
        where r.suffix != bwt_encode.eob
    )
    --select * from r order by suffix collate "C"; --test
    select array_to_string(array(
        select --r.*,
               (select left(o.suffix, 1)
                from r as o
                where case when r.pos - 1 = 0 then length(r.suffix)
                           else r.pos - 1
                      end = o.pos
                limit 1
               )
        from r
        order by suffix collate "C"
    ), '');

$func$;

comment on function public.bwt_encode(s text, eob char) is 'https://en.wikipedia.org/wiki/Burrows%E2%80%93Wheeler_transform';

--TEST
do $$
    begin
        assert public.bwt_encode('abracadabra', '$') = 'ard$rcaaaabb';
        assert public.bwt_encode('абракадабра', '$') = 'ард$краааабб';
        assert public.bwt_encode('inefficiencies', '$') = 'sinniieffcc$eie';
        assert public.bwt_encode('PanamaBanana', '$') = 'aa$nmnnPBaaaa';
        assert public.bwt_encode('SIX.MIXED.PIXIES.SIFT.SIXTY.PIXIE.DUST.BOXES', '$') = 'STEXYDST.E.IXXIIXXSSMPPS.B..EE.$.USFXDIIOIIIT';
    end;
$$;
