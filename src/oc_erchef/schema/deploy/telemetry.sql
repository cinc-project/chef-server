-- Deploy telemetry

BEGIN;

CREATE TABLE IF NOT EXISTS telemetry(
  property CHAR(512),
  value_string CHAR(512) NOT NULL,
  event_timestamp TIMESTAMP
);

CREATE OR REPLACE FUNCTION telemetry_check_send(
  hostname VARCHAR
)
RETURNS boolean
LANGUAGE plpgsql
AS $$
DECLARE
  host_timestamp telemetry.property%TYPE;
  last_send_timestamp telemetry.event_timestamp%TYPE;
BEGIN
  -- Delete any existing entry for the given hostname
  DELETE FROM telemetry
  WHERE property = hostname;

  -- Insert a new entry for the given hostname
  INSERT INTO telemetry(property, value_string, event_timestamp)
  VALUES (hostname, '', current_timestamp);

  -- Always update the 'last_send' entry
  DELETE FROM telemetry
  WHERE property = 'last_send';
  INSERT INTO telemetry(property, value_string, event_timestamp)
  VALUES ('last_send', hostname, current_timestamp);

  RETURN true;
END;
$$;

COMMIT;
