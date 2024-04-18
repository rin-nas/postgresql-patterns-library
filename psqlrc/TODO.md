# TODO list

* Get some ideas from https://github.com/zalando/pg_view
* Uptime: `select current_timestamp - pg_postmaster_start_time() as uptime;`
* Check config file `show config_file;` for errors: `select count(*) from pg_file_setings where not applied or error is not null;`
