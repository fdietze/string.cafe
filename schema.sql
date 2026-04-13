-- Desired-state Postgres schema for string.cafe.
--
-- Keep this file authoritative for schema design. Add or change objects here
-- first, then generate a migration to reconcile migrations/ with this file.

CREATE TABLE channels (
  id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  name TEXT NOT NULL UNIQUE
);
