# TODO list

1. Get some ideas from https://github.com/zalando/pg_view
1. Uptime: `select current_timestamp - pg_postmaster_start_time() as uptime;`
1. Check config file `show config_file;` for errors: `select count(*) from pg_file_setings where error is not null or not applied;`
1. Check hba file `show hba_file;` for errors: `select count(*) from pg_hba_file_rules where error is not null;`
1. Databases count and total size: `select count(*), pg_size_pretty(sum(pg_database_size(datname))) from pg_database;` TODO add tables size, indexes size, toast size, total size
1. Databases used space in percent
