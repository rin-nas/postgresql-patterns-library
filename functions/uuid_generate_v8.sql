-- Source: https://gist.github.com/kjmph/5bd772b2c2df145aa645b837da7eca74

-- Based off IETF draft, https://datatracker.ietf.org/doc/draft-peabody-dispatch-new-uuid-format/

-- Generate a custom UUID v8 with microsecond precision
create or replace function uuid_generate_v8()
returns uuid
as $$
declare
  unix_ts_ms bytea;
  uuid_bytes bytea;
  timestamp    timestamptz;
  microseconds int;
begin
  timestamp    = clock_timestamp();
  unix_ts_ms = substring(int8send(floor(extract(epoch from timestamp) * 1000)::bigint) from 3);
  microseconds = (cast(extract(microseconds from timestamp)::int - (floor(extract(milliseconds from timestamp))::int * 1000) as double precision) * 4.096)::int;

  -- use random v4 uuid as starting point (which has the same variant we need)
  uuid_bytes = uuid_send(gen_random_uuid());

  -- overlay timestamp
  uuid_bytes = overlay(uuid_bytes placing unix_ts_ms from 1 for 6);

  -- set version 8
  uuid_bytes = set_byte(uuid_bytes, 6, (b'1000' || (microseconds >> 8)::bit(4))::bit(8)::int);
  uuid_bytes = set_byte(uuid_bytes, 7, microseconds::bit(8)::int);

  return encode(uuid_bytes, 'hex')::uuid;
end
$$
language plpgsql
volatile;
