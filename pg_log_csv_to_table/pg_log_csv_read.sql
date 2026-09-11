CREATE EXTENSION IF NOT EXISTS file_fdw;
CREATE SERVER pg_log /*IF NOT EXISTS*/ FOREIGN DATA WRAPPER file_fdw;
CREATE SCHEMA /*IF NOT EXISTS*/ _pg_log;

--DROP FOREIGN TABLE /*IF EXISTS*/ _pg_log.alldays CASCADE; -- для тестов

-- выборка данных будет из всех наследуемых таблиц
CREATE FOREIGN TABLE _pg_log.alldays (
    log_time timestamp(3) with time zone,
    user_name text,
    database_name text,
    process_id integer,
    connection_from text,
    session_id text,
    session_line_num bigint,
    command_tag text,
    session_start_time timestamp with time zone,
    virtual_transaction_id text,
    transaction_id bigint,
    error_severity text,
    sql_state_code text,
    message text,
    detail text,
    hint text,
    internal_query text,
    internal_query_pos integer,
    context text,
    query text,
    query_pos integer,
    location text,
    application_name text,
    backend_type text,
    leader_pid integer, -- PostgreSQL v14+
    query_id bigint -- PostgreSQL v14+
)
SERVER pg_log
OPTIONS (program 'true', format 'csv');

CREATE FOREIGN TABLE _pg_log.today ()
INHERITS (_pg_log.alldays)
SERVER pg_log
OPTIONS (program '/var/lib/pgsql/pg_log_csv_read.sh 1', format 'csv');

CREATE FOREIGN TABLE _pg_log.yesterday ()
INHERITS (_pg_log.alldays)
SERVER pg_log
OPTIONS (program '/var/lib/pgsql/pg_log_csv_read.sh 2', format 'csv');

CREATE FOREIGN TABLE _pg_log.day_3 ()
INHERITS (_pg_log.alldays)
SERVER pg_log
OPTIONS (program '/var/lib/pgsql/pg_log_csv_read.sh 3', format 'csv');

CREATE FOREIGN TABLE _pg_log.day_4 ()
INHERITS (_pg_log.alldays)
SERVER pg_log
OPTIONS (program '/var/lib/pgsql/pg_log_csv_read.sh 4', format 'csv');

CREATE FOREIGN TABLE _pg_log.day_5 ()
INHERITS (_pg_log.alldays)
SERVER pg_log
OPTIONS (program '/var/lib/pgsql/pg_log_csv_read.sh 5', format 'csv');

CREATE FOREIGN TABLE _pg_log.day_6 ()
INHERITS (_pg_log.alldays)
SERVER pg_log
OPTIONS (program '/var/lib/pgsql/pg_log_csv_read.sh 6', format 'csv');

CREATE FOREIGN TABLE _pg_log.day_7 ()
INHERITS (_pg_log.alldays)
SERVER pg_log
OPTIONS (program '/var/lib/pgsql/pg_log_csv_read.sh 7', format 'csv');

/*
-- Тестирование:
TABLE _pg_log.alldays LIMIT 10;
TABLE _pg_log.today LIMIT 10;
TABLE _pg_log.yesterday LIMIT 10;
SELECT count(*) FROM _pg_log.alldays;
*/