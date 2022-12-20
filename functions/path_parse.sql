create or replace function path_parse(
    path text,
    root out text,
    dir  out text,
    base out text,
    name out text,
    ext  out text
)
    /*
    The function returns an object whose properties represent significant elements of the path.
    The returned record will have the following properties:
        dir text
        root text
        base text
        name text
        ext text
    Compatible with https://nodejs.org/api/path.html#pathparsepath
    */
    returns record
    immutable
    returns null on null input
    parallel safe
    language sql
    set search_path = ''
as
$$
select coalesce(case when left(m[1], 1) = '/' then '/' else '' end, '') as root,
       coalesce(case when m[1] = '/' then '/' else rtrim(m[1], '\/') end, '') as dir,
       coalesce(m[2], '') as base,
       coalesce(m[3], '') as name,
       coalesce(m[4], '') as ext
from regexp_match(
             path,
             $regexp$
                   ^
                   ( #1 dir
                     (?:[^":;*?<>|])*
                     [\\/]
                   )?
                   ( #2 base
                     ( #3 name
                       \.?
                       (?:
                         (?!\.[^.":;*?<>|\\/]+$)
                         [^":;*?<>|\\/]
                       )*
                     )
                     (\. #4 ext
                       [^.":;*?<>|\\/]+
                     )?
                   )
                   $
               $regexp$,
             'x'
         ) as m;
$$;

-- TEST
do $$
    begin
        --positive

        -- проверка парсинга директорий
        assert (select to_json(t)::text = '{"root":"","dir":"","base":"","name":"","ext":""}' from path_parse('') as t);
        assert (select to_json(t)::text = '{"root":"/","dir":"/","base":"","name":"","ext":""}' from path_parse('/') as t);
        assert (select to_json(t)::text = '{"root":"/","dir":"/","base":"file","name":"file","ext":""}' from path_parse('/file') as t);
        assert (select to_json(t)::text = '{"root":"/","dir":"/dir","base":"file","name":"file","ext":""}' from path_parse('/dir/file') as t);
        assert (select to_json(t)::text = '{"root":"/","dir":"/dir/to","base":"file","name":"file","ext":""}' from path_parse('/dir/to/file') as t);
        assert (select to_json(t)::text = '{"root":"","dir":"dir","base":"file","name":"file","ext":""}' from path_parse('dir/file') as t);
        assert (select to_json(t)::text = '{"root":"","dir":"dir/to","base":"file","name":"file","ext":""}' from path_parse('dir/to/file') as t);

        -- проверка парсинга файлов
        assert (select to_json(t)::text = '{"root":"","dir":"","base":"файл","name":"файл","ext":""}' from path_parse('файл') as t);
        assert (select to_json(t)::text = '{"root":"","dir":"","base":"файл.ext","name":"файл","ext":".ext"}' from path_parse('файл.ext') as t);
        assert (select to_json(t)::text = '{"root":"","dir":"","base":"файл.tar.gz","name":"файл.tar","ext":".gz"}' from path_parse('файл.tar.gz') as t);
        assert (select to_json(t)::text = '{"root":"","dir":"","base":".file.tar.gz","name":".file.tar","ext":".gz"}' from path_parse('.file.tar.gz') as t);
        assert (select to_json(t)::text = '{"root":"","dir":"","base":".file","name":".file","ext":""}' from path_parse('.file') as t);
        assert (select to_json(t)::text = '{"root":"","dir":"","base":"..file","name":".","ext":".file"}' from path_parse('..file') as t);
        assert (select to_json(t)::text = '{"root":"","dir":"","base":".file.ext","name":".file","ext":".ext"}' from path_parse('.file.ext') as t);

        --negative
        assert (select to_json(t)::text = '{"root":"","dir":"","base":"","name":"","ext":""}' from path_parse('www.ru/office-rent/index.php?id=30') as t);

    end
$$;
