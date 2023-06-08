# PostgreSQL SQL syntax check

## Usage

```sql
select is_sql($is_sql$
   -- insert your SQL code here
$is_sql$);
```

## Restrinctions

When your code has

```sql
SAVEPOINT test_start; 
...; 
ROLLBACK TO SAVEPOINT test_start;
```

you will get an error: SQLSTATE[42601]: Syntax error: 7 ERROR:  syntax error at or near "TO".

Code above does not work in PL/PgSQL code, for example, procedure or function. 
But you can use workaround with "substransaction":

```sql
DO $TEST$
    BEGIN
        -- here you can write DDL commands, for example, adding or deleting a table or its section
        -- and/or
        -- here you can write DML commands that modify data in tables and, thus, check the operation of triggers
     
        -- rollback all test queries
        raise exception using errcode = 'query_canceled';
     
    EXCEPTION WHEN query_canceled THEN
        --don't do anything
    END
$TEST$;
```
