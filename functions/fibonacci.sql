CREATE OR REPLACE FUNCTION fibonacci(pstop int = 10)
  RETURNS SETOF int
  LANGUAGE plpgsql IMMUTABLE STRICT AS
$func$
DECLARE
    a int := 0;
    b int := 1;
BEGIN
   -- optional sanity check:
   -- function starts operating at 2
   -- and int4 computation overflows past Fibonacci Nr. 1836311903
   IF pstop NOT BETWEEN 2 AND 1836311903 THEN
      RAISE EXCEPTION 'Pass integer betwen 2 and 1836311903. Received %', pstop;
   END IF;

   RETURN NEXT 0;
   RETURN NEXT 1;
   LOOP
      a := a + b;
      EXIT WHEN a >= pstop;
      RETURN NEXT a;

      b := b + a;
      EXIT WHEN b >= pstop;
      RETURN NEXT b;
   END LOOP;
END;
$func$;
--source: https://stackoverflow.com/questions/75588188/generating-fibonacci-sequence-with-pl-pgsql-function

comment on function fibonacci(pstop int) is 'Generates Fibonacci sequence';

--TEST
do $$
    begin
        assert (select count(*) = 32 and sum(i) = 3524577
                from fibonacci(1346270) as t(i)
               );
    end;
$$;

/*
See also:
https://wiki.postgresql.org/wiki/Fibonacci_Numbers
https://stackoverflow.com/questions/37479718/how-to-turn-integers-into-fibonacci-coding-efficiently
*/
