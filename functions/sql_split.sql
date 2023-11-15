create or replace function public.sql_split(
    sql text,
    is_remove_empty_query boolean default true, --удалять пустые запросы (даже если там есть только комментарии)
    is_remove_comments boolean default false --удалять комментарии (однострочные и многострочные)
)
    returns text[]
    immutable
    returns null on null input
    parallel safe -- postgres 10 or later
    language plpgsql
    set search_path = ''
    cost 10
as
$func$
declare
    rec record;
    query text not null default '';
    query_alt text not null default ''; --query с удалёнными комментариями
    queries text[] not null default array[]::text[];
    pattern constant text not null default $regexp$
        (  #1 all
             (--[^\r\n]*?)                    #2 singe-line comment
          |  (/\*                            #3 multi-line comment (can be nested)
               [^*/]*? #speed improves
               (?: [^*/]+
                 | \*[^/] #not end comment
                 | /[^*]  #not begin comment
                 |   #recursive:
                     /\*                            #multi-line comment (can be nested)
                       [^*/]*? #speed improves
                       (?: [^*/]+?
                         | \*[^/] #not end comment
                         | /[^*]  #not begin comment
                         |   #recursive:
                             /\*                            #multi-line comment (can be nested)
                               [^*/]*? #speed improves
                               (?: [^*/]+?
                                 | \*[^/] #not end comment
                                 | /[^*]  #not begin comment
                                 #| #recursive
                               )*?
                             \*/
                       )*?
                     \*/
               )*?
             \*/)
          |  ("(?:[^"]+?|"")*?")            #1 identifiers
          |  ('(?:[^']+?|'')*?')            #5 string constants
          |  (\m[Ee]'(?:[^\\']+?|''|\\.)*?')  #6 string constants with c-style escapes
          |  (  #7
                (\$[a-zA-Z]*?\$)                #8 dollar-quoted string
                    [^$]*?  #speed improves
                    .*?
                \8
             )
          |  (;)  #9 semicolon
          |  \s+?  #spaces and new lines
          |  \d+?  #digits
          |  [a-zA-Z]{2,}? #word
          |  [^;\s\d] #any char with exceptions
        )
    $regexp$;
begin

    --speed improvements
    if position(';' in sql) = 0 then
        return array[trim(sql, E' \r\n\t')];
    end if;

    for rec in
        select m[1] as "all",
               m[2] as "comment1",
               m[3] as "comment2",
               m[4] as identifier,
               m[5] as string1,
               m[6] as string2,
               m[7] as string3,
               m[9] as semicolon
        from regexp_matches(sql || E'\n;', pattern, 'gx') as m
    loop
        if rec.semicolon is not null then
            if not is_remove_empty_query or trim(query_alt, E' \r\n\t') != '' then
                queries := array_append(queries, trim(query, E' \r\n\t'));
                query := '';
                query_alt := '';
            end if;
        elsif not is_remove_comments or coalesce(rec.comment1, rec.comment2) is null then
            query := query || rec."all";
            query_alt := query_alt || case when coalesce(rec.comment1, rec.comment2) is null then rec."all" else ' ' end;
        else
            query := query || ' ';
        end if;
    end loop;

    return queries;
end
$func$;

comment on function public.sql_split(sql text, is_remove_empty_query boolean, is_remove_comments boolean) is $$
    SQL парсер, разбивает SQL скрипт на отдельные команды по разделителю ';'.
    SQL parser, splits multiple SQL statements into individual SQL statements by simicolon delimiter.
$$;

--TEST
do $do$
    declare
        sql constant text not null default $sql$
                       --comm;ent1
                       select -11.22 as "1;1", 's'';tr', E'e\';f' from t;
                       /*comm;ent2 */
                       select $$test;$$ from t;--la;st1
                       /*la;st2*/
                   $sql$;
    begin

        assert (select queries = array[$sql$select -11.22 as "1;1", 's'';tr', E'e\';f' from t$sql$,
                                       $sql$select $$test;$$ from t$sql$]
                 from public.sql_split(sql, true, true) as t(queries));

        assert (select queries = array[$sql$--comm;ent1
                       select -11.22 as "1;1", 's'';tr', E'e\';f' from t$sql$,
                       $sql$/*comm;ent2 */
                       select $$test;$$ from t$sql$]
                   from public.sql_split(sql, true, false) as t(queries));

    end;
$do$;
