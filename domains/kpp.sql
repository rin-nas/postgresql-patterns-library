--https://www.banki.ru/wikibank/kod_prichinyi_postanovki_na_uchet/
--https://rg.ru/documents/2012/08/22/nalog-inn-dok.html

CREATE DOMAIN kpp AS text CHECK(is_kpp(VALUE));

COMMENT ON DOMAIN kpp IS 'КПП (код причины постановки на учёт)';
