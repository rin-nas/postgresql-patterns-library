create function is_email(email text) returns boolean
    PARALLEL SAFE
    LANGUAGE SQL
    STABLE
    RETURNS NULL ON NULL INPUT
as
$BODY$
-- Регулярное выражение взято и адаптировано из https://github.com/rin-nas/regexp-patterns-library/
select regexp_match($1, $REGEXP$
^
(?<![-!#$%&'*+/=?^_`{|}~@."\]\\a-zA-Zа-яА-ЯёЁ\d])
(?:
    [-!#$%&'*+/=?^_`{|}~a-zA-Z\d]+
  | [-!#$%&'*+/=?^_`{|}~а-яА-ЯёЁ\d]+
  | "(?:(?:[^"\\]|\\.)+)"
)
(?:
  \.
  (?:
      [-!#$%&'*+/=?^_`{|}~a-zA-Z\d]+
    | [-!#$%&'*+/=?^_`{|}~а-яА-ЯёЁ\d]+
    | "(?:[^"\\]|\\.)+"
  )
)*
@
(?:
    (?:
       (?: #домены 2-го и последующих уровней
         (?!-)
         (?:
             (?:[a-zA-Z\d]|-(?!-)){1,63}
           | (?:[а-яА-ЯёЁ\d]|-(?!-)){1,63}
         )
         (?<!-)
         \.
       )+
       (?:  #домен 1-го уровня
           [a-zA-Z]{2,63}
         | [а-яА-ЯёЁ]{2,63}
       )
    )\M
  | (?: #IPv4
      (?<!\d)
      (?!0+\.)
      (?:1?\d\d?|2(?:[0-4]\d|5[0-5]))(?:\.(?:1?\d\d?|2(?:[0-4]\d|5[0-5]))){3}
      (?!\d)
    )
  | \[ #IPv4 в квадратных скобках
    (?:
      (?<!\d)
      (?!0+\.)
      (?:1?\d\d?|2(?:[0-4]\d|5[0-5]))(?:\.(?:1?\d\d?|2(?:[0-4]\d|5[0-5]))){3}
      (?!\d)
    )
    \]
)
$
$REGEXP$, 'sx') is not null;

$BODY$;

SELECT is_email('test.@domain.com'), is_email('test@domain.com');
       
/*
TODO add tests with email from 
	https://en.wikipedia.org/wiki/Email_address
	https://en.wikipedia.org/wiki/International_email
*/
