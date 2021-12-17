DROP DOMAIN IF EXISTS phone;
CREATE DOMAIN phone AS text CHECK(
    octet_length(VALUE)
        BETWEEN 1/*+*/ + 8  --https://stackoverflow.com/questions/14894899/what-is-the-minimum-length-of-a-valid-international-phone-number
            AND 1/*+*/ + 15 --https://en.wikipedia.org/wiki/E.164 and https://en.wikipedia.org/wiki/Telephone_numbering_plan
                       + 3  --reserved for depersonalization
    AND VALUE ~ '^\+\d+$' --international E.164 format
);
COMMENT ON DOMAIN phone IS 'Валидация номера телефона в международном формате E.164';
