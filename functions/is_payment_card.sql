--https://en.wikipedia.org/wiki/Payment_card_number
--Most credit cards use the Luhn algorithm to validate their numbers. It is a simple checksum that helps detect single digit typos and adjacent digit transposition errors. 

CREATE FUNCTION is_payment_card(smallint[]) RETURNS boolean AS $$
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
$$
LANGUAGE SQL
IMMUTABLE;

CREATE DOMAIN cc_number AS smallint[] CHECK ( is_valid_cc(VALUE) );

/* alternately, store as text for user friendliness

  CREATE DOMAIN cc_number AS text CHECK (
    is_valid_cc(string_to_array(VALUE, null)::smallint[])
  );

*/

--TEST
--4556214349109, 4539146807121309, 4539 1468 0712 1309
