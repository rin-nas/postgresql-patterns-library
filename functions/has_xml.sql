create or replace function public.has_xml(str text) returns boolean
    immutable
    strict -- returns null if any parameter is null
    parallel safe -- Postgres 10 or later
    language plpgsql
    set search_path = ''
    cost 2
as
$function$
declare
    xmlCdataOpen    text default '<!\[CDATA\[';
    xmlCdataClose   text default '\]\]>';
    xmlCommentOpen  text default '<!--';
    xmlCommentClose text default '-->';
    xmlTagAttrs     text default $$
                                 (?:
                                      [^>"']
                                   |  "  [^"]*  "  #attribute value in double quotes
                                   |  '  [^']*  '  #attribute value in single quotes
                                 )*
                                 $$;
    xmlTagOpenOrDoctype text default '<!?[a-zA-Z]' || xmlTagAttrs || '>';
    xmlTagClose         text default '<\/[a-zA-Z][a-zA-Z\d]*>';
    xml                 text default '(?:' || xmlTagOpenOrDoctype
                                           || ' | ' || xmlTagClose
                                           || ' | ' || xmlCdataOpen   || ' .*? ' || xmlCdataClose
                                           || ' | ' || xmlCommentOpen || ' .*? ' || xmlCommentClose
                                           || ')';
begin
    --raise notice '%', xml;
    return octet_length(str) > 2 --speed improves
       and regexp_match(str, xml, 'sx') is not null;
end;
$function$;

comment on function public.has_xml(text) is 'Проверяет, что текст содержит xml или html';

--TEST

do $do$
begin
    --positive
    assert public.has_xml('<B>');
    assert public.has_xml('<br/>');
    assert public.has_xml('</a>');
    assert public.has_xml($$<a href='#'title="do it">$$);
    assert public.has_xml('<a href="do.it?a<b&a>c">');
    assert public.has_xml('<!-- -->');
    assert public.has_xml('<![CDATA[ ]]>');

    --negative
    assert public.has_xml(null) is null;
    assert not public.has_xml('');
    assert not public.has_xml('a<b');
    assert not public.has_xml('a>b');
    assert not public.has_xml('a < b > c');
    assert not public.has_xml('<!--');
    assert not public.has_xml('-->');
    assert not public.has_xml('<![CDATA[');
    assert not public.has_xml(']]>');
end
$do$;
