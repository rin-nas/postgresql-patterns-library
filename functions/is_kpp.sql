create or replace function is_kpp(str text)
    returns boolean
    immutable
    returns null on null input
    parallel safe
    language sql
    set search_path = ''
    cost 5
as
$$
select
    octet_length(str) = 9
    and regexp_match(
        str,
        --https://www.banki.ru/wikibank/kod_prichinyi_postanovki_na_uchet/
        --https://rg.ru/documents/2012/08/22/nalog-inn-dok.html
        $regexp$
          ^
           [0-9]{4}    #NNNN – код налогового органа, где была поставлена на учет организация
           [0-9A-Z]{2} #PP – причина постановки на учет (эти символы могут принимать значения для российских организаций – от 1 до 50, для иностранных – от 51 до 99)
           [0-9]{3}    #XXX – порядковый номер постановки на учет в территориальном налоговом органе (цифры показывают, сколько раз организация вставала на учет по данной причине)
          $
        $regexp$, 'x') is not null
    and str !~ '^([1-9])\1+$'
$$;

comment on function is_kpp(text) is 'Проверяет, что переданная строка является КПП (код причины постановки на учёт)';

--TEST

DO $$
BEGIN
    --positive
    assert is_kpp('000000000');
    assert is_kpp('123456789');
    assert is_kpp('0000AZ000');

    --negative
    assert not is_kpp('12345');
    assert not is_kpp('1234567890');
    assert not is_kpp('111111111');

END $$;
