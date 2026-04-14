--TODO доделать, добавить карту МИР в рег. выражение
--https://en.wikipedia.org/wiki/Payment_card_number
--Most credit cards use the Luhn algorithm to validate their numbers. It is a simple checksum that helps detect single digit typos and adjacent digit transposition errors. 

create or replace function public.is_payment_card(smallint[])
    returns boolean
    immutable
    language sql
    set search_path = ''
begin atomic
  select sum(
             case when (pos % 2 = 0) then
               2*digit - (case when digit < 5 then 0 else 9 end)
             else
               digit
             end
         ) % 10 = 0
  from
    unnest(array( -- loop over digit/position
      select $1[i] -- ... which we read backward
      from generate_subscripts($1,1) as s(i)
      order by i desc
    )
  ) with ordinality as t (digit, pos);
end;

-- CREATE DOMAIN payment_card AS smallint[] CHECK ( public.is_payment_card(VALUE) );

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
