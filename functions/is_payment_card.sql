--TODO доделать, добавить карту МИР в рег. выражение
--https://en.wikipedia.org/wiki/Payment_card_number
--Most credit cards use the Luhn algorithm to validate their numbers. It is a simple checksum that helps detect single digit typos and adjacent digit transposition errors. 

CREATE FUNCTION is_payment_card(smallint[]) RETURNS boolean
    IMMUTABLE
    LANGUAGE SQL
    set search_path = ''
AS $$
  SELECT SUM(
    CASE WHEN (pos % 2 = 0) THEN
      2*digit - (CASE WHEN digit < 5 THEN 0 ELSE 9 END)
    ELSE
      digit
    END
  ) % 10 = 0
  FROM
    unnest(ARRAY( -- loop over digit/position
      SELECT $1[i] -- ... which we read backward
      FROM generate_subscripts($1,1) AS s(i)
      ORDER BY i DESC
    )
  ) WITH ordinality AS t (digit, pos)
$$;

CREATE DOMAIN cc_number AS smallint[] CHECK ( is_valid_cc(VALUE) );

/* alternately, store as text for user friendliness

  CREATE DOMAIN cc_number AS text CHECK (
    is_valid_cc(string_to_array(VALUE, null)::smallint[])
  );
*/

/*
--http://www.regular-expressions.info/creditcard.html
(?=\b \d{13,16} \b)
(?:  4[0-9]{12}(?:[0-9]{3})?          # Visa
  |  (?: 5[1-5][0-9]{2}               # MasterCard
       | 222[1-9]|22[3-9][0-9]|2[3-6][0-9]{2}|27[01][0-9]|2720
     ) [0-9]{12}
  |  3[47][0-9]{13}                   # American Express
  |  3(?:0[0-5]|[68][0-9])[0-9]{11}   # Diners Club
  |  6(?:011|5[0-9]{2})[0-9]{12}      # Discover
  |  (?:2131|1800|35\d{3})\d{11}      # JCB
)
*/

--TEST
--4556214349109, 4539146807121309, 4539 1468 0712 1309
