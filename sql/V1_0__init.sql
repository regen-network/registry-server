CREATE EXTENSION
IF NOT EXISTS postgis;
CREATE EXTENSION
IF NOT EXISTS "uuid-ossp";

CREATE ROLE app_user;

COMMENT ON ROLE app_user IS
  'This is the user role that all logged in users inherit from and should be used when creating role-level security policies.';

DROP SCHEMA IF EXISTS private CASCADE;
CREATE SCHEMA private;
