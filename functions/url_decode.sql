--see also extension https://github.com/okbob/url_encode with C implementation

CREATE OR REPLACE FUNCTION public.url_decode(input text)
    returns text
    immutable
    strict -- returns null if any parameter is null
    language plpgsql
    set search_path = ''
AS $$
DECLARE
 bin bytea = '';
 byte text;
BEGIN
 FOR byte IN (select (regexp_matches(input, '(%..|.)', 'g'))[1]) LOOP
   IF length(byte) = 3 THEN
     bin = bin || decode(substring(byte, 2, 2), 'hex');
   ELSE
     bin = bin || byte::bytea;
   END IF;
 END LOOP;
 RETURN convert_from(bin, 'utf8');
END
$$;

--TEST
--select public.url_decode('Hell%C3%B6%20World%21') = 'Hellö World!'
