-- https://developer.mozilla.org/en-US/docs/Web/CSS/color_value
-- https://regex101.com/r/CMQKwv/3/

CREATE DOMAIN css_color AS text CHECK(
    octet_length(VALUE) BETWEEN 4 AND 9 
    AND VALUE ~ '^#[a-fA-F\d]{3}(?:[a-fA-F\d]{3})?$|^#[a-fA-F\d]{4}(?:[a-fA-F\d]{4})?$'
);

COMMENT ON DOMAIN css_color IS 'CSS color';

--TEST
select '#777'::css_color; --ok
select '$777'::css_color; --error
