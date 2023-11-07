--Depends on function public.html_entities() !
create or replace function public.html_entity_decode(str text)
    returns text
    immutable
    returns null on null input
    parallel safe -- postgres 10 or later
    language plpgsql
    set search_path = ''
as $func$
    declare
        rec record;
        protect_char constant char(1) not null default e'\u0001'; --protect incorrect chain process, like &amp;quot

        /*
        Protect chr() errors:
            [54000] ERROR: null character not permitted
            [54000] ERROR: requested character not valid for encoding: DDDDD
        The maximum valid code point in Unicode is U+10FFFF
        There are also a set of code points that are the surrogates for UTF-16. These are in the range U+D800 .. U+DFFF.
        Details at https://stackoverflow.com/questions/27415935/does-unicode-have-a-defined-maximum-number-of-code-points
        */
        codepoints_ranges constant int4range[] not null default array[
            int4range(1,            x'D800'::int,   '[)'),
            int4range(x'DFFF'::int, x'10FFFF'::int, '(]')
        ];

        is_replaced bool not null default false;
    begin

        if position('&' in str) = 0 then --speed improvements
            return str;
        end if;

        for rec in
            with t as materialized (
                select distinct
                    r.m[1] as entity
                from regexp_matches(str, '&[a-zA-Z][a-zA-Z\d]+;?', 'g') as r(m)
            )
            select *
            from t
            cross join lateral (select public.html_entities()->t.entity->>'characters') as x(characters)
            where x.characters is not null
        loop
            str := replace(str, rec.entity, concat(protect_char, rec.characters, protect_char));
            is_replaced := true;
        end loop;

        if position('&#' in str) > 0 then --speed improvements
            for rec in
                select distinct
                    r.m[1] as entity,
                    r.m[2]::int as codepoint
                from regexp_matches(str, '(&#(\d{1,7});)', 'g') as r(m) -- maximum valid code point in Unicode is 1114111 (U+10FFFF)
                where r.m[2]::int <@ any (codepoints_ranges) -- https://postgrespro.ru/docs/postgresql/12/functions-range
            loop
                str := replace(str, rec.entity, concat(protect_char, chr(rec.codepoint), protect_char));
                is_replaced := true;
            end loop;

            if position('&#x' in str) > 0 then --speed improvements
                for rec in
                    select distinct
                        r.m[1] as entity,
                        x.codepoint
                    from regexp_matches(str, '(&#x([\da-fA-F]{1,6});)', 'g') as r(m) -- maximum valid code point in Unicode is U+10FFFF
                    -- https://stackoverflow.com/questions/8316164/convert-hex-in-text-representation-to-decimal-number
                    cross join lateral (select ('x' || lpad(r.m[2], 8, '0'))::bit(32)::int) as x(codepoint)
                    where x.codepoint <@ any (codepoints_ranges) -- https://postgrespro.ru/docs/postgresql/12/functions-range
                loop
                    str := replace(str, rec.entity, concat(protect_char, chr(rec.codepoint), protect_char));
                    is_replaced := true;
                end loop;
            end if;

        end if;

        if is_replaced then
            return replace(str, protect_char, '');
        end if;

        return str;
    end;
$func$;

comment on function public.html_entity_decode(str text) is $$
    Convert HTML entities to their corresponding characters. 
    Depends on function public.html_entities()
$$;

-- TEST

DO $$
DECLARE
    rec record;
    str_out_returned text;
BEGIN
    for rec in select * from (values
        (null, null),

        -- Positive
        ('&Afr; &acE; &frac12; &quot &amp, &amp;quot, &gt; &Ouml; &Bopf;', '𝔄 ∾̳ ½ " &, &quot, > Ö 𝔹'), --Named entities
        ('&#34; &#055; &#120171; &#1114111;', '" 7 𝕫 􏿿'), --Dec code entities
        ('&#x25a0; &#x02DC; &#x1D539; &#x10FFFF;', '■ ˜ 𝔹 􏿿'), --Hex code entities

        -- Negative
        ('abcde', 'abcde'),
        ('&unknown; &unk', '&unknown; &unk'), --Named entities
        ('&#0; &#55296; &#57343; &#1234567; &#9999999; &#05_5', '&#0; &#55296; &#57343; &#1234567; &#9999999; &#05_5'), --Dec code entities
        ('&#x0; &#xD800; &#xDFFF; &#x12d687; &#xffffff; &#x25g0;', '&#x0; &#xD800; &#xDFFF; &#x12d687; &#xffffff; &#x25g0;') --Hex code entities
    ) as t(str_in, str_out_expected)
    loop
        str_out_returned = public.html_entity_decode(rec.str_in);
        assert
            -- the result of the comparison should return boolean
            str_out_returned is not distinct from rec.str_out_expected,
            -- if the comparison result is not true, an error message will be returned
            format('in %L, out expected %L, out returned %L', rec.str_in, rec.str_out_expected, str_out_returned);
    end loop;
END $$;
