CREATE DOMAIN public.timezone AS CITEXT CHECK (public.is_timezone(VALUE));

COMMENT ON DOMAIN public.timezone IS 'Timezone';