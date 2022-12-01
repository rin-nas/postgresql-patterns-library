cat DDL_log_to_table_1_table.do.sql \
    DDL_log_to_table_2_functions.do.sql \
    DDL_log_to_table_3_triggers.do.sql \
    DDL_log_to_table_4_views.do.sql \
    | psql --username=postgres \
           --echo-errors \
           --set="ON_ERROR_STOP=1" \
           --dbname=test
