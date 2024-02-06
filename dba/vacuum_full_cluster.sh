# VACUUM FULL for cluster
for dd in \
         psql -U postgres -h [ host ] -p [ port ] -t -c "SELECT datname FROM pg_catalog.pg_database WHERE datname NOT IN ('postgres', 'template0', 'template1');";
     do echo $dd; \
     for tt in psql -U postgres -h [ host ] -p [ port ] $dd -c "SELECT '\"' || schemaname || '\".\"' ||  tablename || '\"' FROM pg_tables WHERE schemaname NOT IN ('pg_catalog', 'pg_toast', 'information_schema');" -t; \
         do echo $tt; \
         psql -U postgres -h [ host ] -p [ port ] $dd -c "VACUUM FULL $tt;";
     done;
done
