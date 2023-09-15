create or replace function public.has_html_entity(str text)
    returns boolean
    immutable
    returns null on null input
    parallel safe -- Postgres 10 or later
    language sql
    set search_path = ''
    cost 3
as
$$
select position('&' in str) > 0 --speed improves
       and regexp_match(
            str,
            -- https://stackoverflow.com/questions/15532252/why-is-reg-being-rendered-as-without-the-bounding-semicolon
            -- https://html.spec.whatwg.org/multipage/named-characters.html#named-character-references TODO update regexp entities list from last version
            $regexp$
            (&
            (?:  (?=[a-zA-Z]{2}) #speed improves
                 (?: AElig|AMP|Aacute|Acirc|Agrave|Aring|Atilde|Auml|COPY|Ccedil|ETH|Eacute|Ecirc|Egrave|Euml|GT|Iacute|Icirc|Igrave|Iuml|LT|Ntilde|Oacute|Ocirc|Ograve|Oslash|Otilde|Ouml|QUOT|REG|THORN|Uacute|Ucirc|Ugrave|Uuml|Yacute
                   | aacute|acirc|acute|aelig|agrave|amp|aring|atilde|auml|brvbar|ccedil|cedil|cent|copy|curren|deg|divide|eacute|ecirc|egrave|eth|euml|frac12|frac14|frac34|gt|iacute|icirc|iexcl|igrave|iquest|iuml|laquo|lt|macr|micro|middot|nbsp|not|ntilde|oacute|ocirc|ograve|ordf|ordm|oslash|otilde|ouml|para|plusmn|pound|quot|raquo|reg|sect|shy|sup1|sup2|sup3|szlig|thorn|times|uacute|ucirc|ugrave|uml|uuml|yacute|yen|yuml
                 ) #name
                 (?![=_\da-zA-Z]) ;?
              |  [a-zA-Z][a-zA-Z\d]+ #name
                 ;
              |  \# (?:  \d+ #dec
                      |  x[\da-fA-F]+ #hex
                    ) ;
            ))
            $regexp$, 'x') is not null
$$;

comment on function public.has_html_entity(text) is 'Проверяет, что переданная строка содержит HTML сущность';

------------------------------------------------------------------------------------------------------------------------
create or replace function public.has_html_entity(data json)
    returns boolean
    immutable
    returns null on null input
    parallel safe -- Postgres 10 or later
    language sql
    set search_path = ''
    cost 3
as
$$
    select public.has_html_entity(data::text);
$$;

comment on function public.has_html_entity(json) is 'Проверяет, что JSON содержит HTML сущность';

------------------------------------------------------------------------------------------------------------------------
create or replace function public.has_html_entity(data jsonb)
    returns boolean
    immutable
    returns null on null input
    parallel safe -- Postgres 10 or later
    language sql
    set search_path = ''
    cost 3
as
$$
    select public.has_html_entity(data::text);
$$;

comment on function public.has_html_entity(jsonb) is 'Проверяет, что JSONB содержит HTML сущность';

------------------------------------------------------------------------------------------------------------------------
--TEST

DO $$
BEGIN
    --positive
    assert public.has_html_entity(' &quot ');
    assert public.has_html_entity(' &amp ');
    assert public.has_html_entity(' &hellip; ');
    assert public.has_html_entity(' &gt; ');
    assert public.has_html_entity(' &Ouml; ');
    assert public.has_html_entity(' &#34; ');
    assert public.has_html_entity(' &#x02DC; ');

    --negative
    assert not public.has_html_entity(' &qot ');
    assert not public.has_html_entity(' &amper ');
    assert not public.has_html_entity(' &ampER ');
    assert not public.has_html_entity(' &amp1 ');
    assert not public.has_html_entity(' &amp_1 ');
    assert not public.has_html_entity(' &hellip ');
    assert not public.has_html_entity(' &Gt ');
    assert not public.has_html_entity(' &#oDC; ');
    assert not public.has_html_entity(' &#xDG; ');
END $$;
