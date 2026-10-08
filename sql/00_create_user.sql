-- =====================================================================
-- 00_create_user.sql   (OPTIONAL - run ONCE as SYSTEM)
-- Creates a dedicated schema (user) called MEDSTORE for the project.
-- Connect as SYSTEM to the pluggable database (XEPDB1 on Oracle XE 21c).
-- If you get ORA-65096, you are in the container root. Run first:
--     ALTER SESSION SET CONTAINER = XEPDB1;
-- =====================================================================
CREATE USER medstore IDENTIFIED BY "MedStore#123"
  DEFAULT TABLESPACE users
  QUOTA UNLIMITED ON users;

GRANT CREATE SESSION, CREATE TABLE, CREATE VIEW, CREATE SEQUENCE,
      CREATE PROCEDURE, CREATE TRIGGER TO medstore;
