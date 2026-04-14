create or replace function public.is_email(email text)
    returns boolean
    parallel safe
    language sql
    set search_path = ''
    immutable
    returns null on null input
    cost 10
return
    -- https://regex101.com/r/Q4dsL5/14
    regexp_match(email, $regexp$
    ^
    #(?<![-!#$%&'*+/=?^_`{|}~@."\]\\a-zA-Zа-яА-ЯёЁ\d]) #граница начала email для захвата в тексте (здесь не используется)
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
        )
        #(?![a-zA-Zа-яА-ЯёЁ\d@])  #граница окончания email для захвата в тексте (здесь не используется)
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
    $regexp$, 'sx') is not null;

comment on function public.is_email(email text) is $$
Проверяет email по спецификации https://en.wikipedia.org/wiki/Email_address с небольшими отклонениями.
В email допускаются только английские и русские слова.
$$;

--TEST

--positive
do $$
    begin
        --Valid email addresses
        assert public.is_email('ПишитеМне@ИвановИван.почта.рф');
        assert public.is_email('Иванов.Иван@Санкт-Петербург.онлайн');
        assert public.is_email('Ivanov.Иван@москва.ru');
        --assert public.is_email('Ivanov.Иван+facebook@москва.ru'); --TODO !!! ???
        assert public.is_email('c++@test.com');
        assert public.is_email('prettyandsimple@example.com');
        assert public.is_email('very.common@example.com');
        assert public.is_email('disposable.style.email.with+symbol@example.com');
        assert public.is_email('other.email-with-dash@example.com');
        assert public.is_email('x@example.com'); --one-letter local part
        assert public.is_email('"much.more unusual"@example.com');
        assert public.is_email('"very.unusual.@.unusual.com"@example.com');
        assert public.is_email('"very.(),:;<>[]\".VERY.\"very@\\ \"very\".unusual"@strange.example.com');
        assert public.is_email('example-indeed@strange-example.com');
        assert public.is_email($email$#!$%&'*+-/=?^_`{}|~@example.org$email$);
        assert public.is_email($email$"()<>[]:,;@\\\"!#$%&'*+-/=?^_`{}| ~.a"@example.org$email$);
        assert public.is_email('" "@example.org'); --space between the quotes
        assert public.is_email('example@s.solutions'); --see the List of Internet top-level domains
        assert public.is_email('?prettyandsimple@example.com');
    end
$$;

--negative
do $$
    begin
        --Эти email валидные только среде разработки. В продуктивной среде такие email пользователи применять не могут и поэтому считаются невалидными:
        assert not public.is_email('admin@mailserver1'); --local domain name with no TLD
        assert not public.is_email('example@localhost'); --sent from localhost
        assert not public.is_email('user@com');
        assert not public.is_email('user@localserver');
        assert not public.is_email('user@[IPv6:2001:db8::1]');
        assert not public.is_email('©other.email-with-dash@example.com');
    end
$$;

--Valid Email address	Reason
do $$
    begin
        assert public.is_email('email@domain.com'); --Valid email
        assert public.is_email('firstname.lastname@domain.com'); --Email contains dot in the address field
        assert public.is_email('email@subdomain.domain.com'); --Email contains dot with subdomain
        assert public.is_email('firstname+lastname@domain.com'); --Plus sign is considered valid character
        assert public.is_email('email@123.123.123.123'); --Domain is valid IP address
        assert public.is_email('email@[123.123.123.123]'); --Square bracket around IP address is considered valid
        assert public.is_email('"email"@domain.com'); --Quotes around email is considered valid
        assert public.is_email('1234567890@domain.com'); --Digits in address are valid
        assert public.is_email('email@domain-one.com'); --Dash in domain name is valid
        assert public.is_email('_______@domain.com'); --Underscore in the address field is valid
        assert public.is_email('email@domain.name'); --.name is valid Top Level Domain name
        assert public.is_email('email@domain.co.jp'); --Dot in Top Level Domain name also considered valid (use co.jp as example here)
        assert public.is_email('firstname-lastname@domain.com'); --Dash in address field is valid
    end
$$;


--Invalid Email address	Reason
do $$
    begin
        assert not public.is_email('plainaddress'); --Missing @ sign and domain
        assert not public.is_email('#@%^%#$@#$@#.com'); --Garbage
        assert not public.is_email('@domain.com'); --Missing username
        assert not public.is_email('Joe Smith <email@domain.com>'); --Encoded html within email is invalid
        assert not public.is_email('email.domain.com'); --Missing @
        assert not public.is_email('email@domain@domain.com'); --Two @ sign
        assert not public.is_email('.email@domain.com'); --Leading dot in address is not allowed
        assert not public.is_email('email.@domain.com'); --Trailing dot in address is not allowed
        assert not public.is_email('email..email@domain.com'); --Multiple dots
        assert not public.is_email('あいうえお@domain.com'); --Unicode char as address
        assert not public.is_email('email@domain'); --Missing top level domain (.com/.net/.org/etc)
        assert not public.is_email('email@-domain.com'); --Leading dash in front of domain is invalid
        --assert not public.is_email('email@domain.web'); --.web is not a valid top level domain
        assert not public.is_email('email@111.222.333.44444'); --Invalid IP format
        assert not public.is_email('email@domain..com'); --Multiple dot in the domain portion is invalid
        assert not public.is_email('Abc.example.com'); --(no @ character)
        assert not public.is_email('A@b@c@example.com'); --(only one @ is allowed outside quotation marks)
        assert not public.is_email('a"b(c)d,e:f;g<h>i[j\k]l@example.com'); --(none of the special characters in this local part are allowed outside quotation marks)
        assert not public.is_email('just"not"right@example.com'); --(quoted strings must be dot separated or the only element making up the local part)
        assert not public.is_email('this is"not\allowed@example.com'); --(spaces, quotes, and backslashes may only exist when within quoted strings and preceded by a backslash)
        assert not public.is_email('this\ still\"not\\allowed@example.com'); --(even if escaped (preceded by a backslash), spaces, quotes, and backslashes must still be contained by quotes)
        assert not public.is_email('john..doe@example.com'); --(double dot before @)
        assert not public.is_email('john.doe@example..com'); -- (double dot after @)
    end
$$;
