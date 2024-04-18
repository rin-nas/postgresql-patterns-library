# TODO list

1. Get some ideas from https://github.com/zalando/pg_view
1. Uptime: `select current_timestamp - pg_postmaster_start_time() as uptime;`
1. Check config file `show config_file;` for errors: `select count(*) from pg_file_setings where error is not null or not applied;`
1. Check hba file `show hba_file;` for errors: `select count(*) from pg_hba_file_rules where error is not null;`
