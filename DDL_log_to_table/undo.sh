cat DDL_log_to_table.undo.sql \
    | psql --username=postgres \
           --echo-errors \
           --set="ON_ERROR_STOP=1" \
           --dbname=test
