-- =====================================================================
-- 01_reset.sql   (ONLY when you want to start over)
-- Deletes all project tables. On the very first run you will see
-- ORA-00942 (table does not exist). That is harmless.
-- =====================================================================
DROP TABLE sale_detail     CASCADE CONSTRAINTS PURGE;
DROP TABLE sale            CASCADE CONSTRAINTS PURGE;
DROP TABLE medicine_batch  CASCADE CONSTRAINTS PURGE;
DROP TABLE purchase_detail CASCADE CONSTRAINTS PURGE;
DROP TABLE purchase        CASCADE CONSTRAINTS PURGE;
DROP TABLE medicine        CASCADE CONSTRAINTS PURGE;
DROP TABLE category        CASCADE CONSTRAINTS PURGE;
DROP TABLE customer        CASCADE CONSTRAINTS PURGE;
DROP TABLE supplier        CASCADE CONSTRAINTS PURGE;
DROP TABLE users           CASCADE CONSTRAINTS PURGE;
