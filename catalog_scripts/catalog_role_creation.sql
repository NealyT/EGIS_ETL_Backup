-- Role: catalog
-- DROP ROLE IF EXISTS catalog;
drop schema IF EXISTS sdsfie;
drop schema IF EXISTS catalog;
drop schema IF EXISTS ogr_system_tables;
drop role IF EXISTS catalog;

CREATE ROLE catalog WITH
  LOGIN
  NOSUPERUSER
  INHERIT
  NOCREATEDB
  NOCREATEROLE
  NOREPLICATION
  NOBYPASSRLS
  ENCRYPTED PASSWORD 'SCRAM-SHA-256$4096:dHJGMOrE9x24ChSVhlhklA==$EsPJ9a4szU4FeTTJTzUIl73Six63a9Amo/tQnIsUQ5c=:cOU8kpeZMne/tpQgVJzZdo0Cukv2GJJ0iTyRs8HA3J8=';

GRANT CREATE ON DATABASE egdb TO catalog;
GRANT pg_write_all_data TO catalog WITH ADMIN OPTION;