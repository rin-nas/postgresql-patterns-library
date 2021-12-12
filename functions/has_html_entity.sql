create or replace function has_html_entity(str text)
    returns boolean
    immutable
    returns null on null input
    parallel safe -- Postgres 10 or later
    language sql
as
$$
select position('&' in str) > 0 --speed improves
       and regexp_match(
            str,
            --https://stackoverflow.com/questions/15532252/why-is-reg-being-rendered-as-without-the-bounding-semicolon
            --https://html.spec.whatwg.org/multipage/named-characters.html#named-character-references
            $regexp$
            (&
            (?:  (?:AElig|AMP|Aacute|Acirc|Agrave|Aring|Atilde|Auml|COPY|Ccedil|ETH|Eacute|Ecirc|Egrave|Euml|GT|Iacute|Icirc|Igrave|Iuml|LT|Ntilde|Oacute|Ocirc|Ograve|Oslash|Otilde|Ouml|QUOT|REG|THORN|Uacute|Ucirc|Ugrave|Uuml|Yacute|aacute|acirc|acute|aelig|agrave|amp|aring|atilde|auml|brvbar|ccedil|cedil|cent|copy|curren|deg|divide|eacute|ecirc|egrave|eth|euml|frac12|frac14|frac34|gt|iacute|icirc|iexcl|igrave|iquest|iuml|laquo|lt|macr|micro|middot|nbsp|not|ntilde|oacute|ocirc|ograve|ordf|ordm|oslash|otilde|ouml|para|plusmn|pound|quot|raquo|reg|sect|shy|sup1|sup2|sup3|szlig|thorn|times|uacute|ucirc|ugrave|uml|uuml|yacute|yen|yuml) #name
                 (?![=_\da-zA-Z]) ;?
              |  [a-zA-Z][a-zA-Z\d]+ #name
                 ;
              |  \# (?:  \d+ #dec
                      |  x[\da-fA-F]+ #hex
                    ) ;
            ))
            $regexp$, 'x') is not null
$$;

comment on function has_html_entity(text) is 'Проверяет, что переданная строка содержит HTML сущность';

--TEST

DO $$
BEGIN
    --positive
    --assert has_html_entity('');

    --negative
    --assert not has_html_entity('');
END $$;
