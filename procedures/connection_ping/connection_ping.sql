CREATE OR REPLACE PROCEDURE connection_ping(
    max_attempts int,
    sleep_seconds double precision
)
    LANGUAGE plpgsql
AS
$$
BEGIN
  FOR i IN 1..max_attempts LOOP
    RAISE NOTICE 'ping %, client %:%, server (%) %:%',
      -- clock_timestamp()::timestamptz(3),
      i,
      inet_client_addr(), inet_client_port(),
      case when pg_is_in_recovery() then 'standby' else 'primary' end,
      inet_server_addr(), inet_server_port();
    PERFORM pg_sleep(sleep_seconds);
  END LOOP;
END
$$;
