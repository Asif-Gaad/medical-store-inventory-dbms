-- =====================================================================
-- 03_create_indexes.sql   (Phase 4)
-- Oracle indexes PKs and UNIQUE columns automatically, but NOT foreign
-- keys. These indexes speed up JOINs, searches and date-based reports.
-- =====================================================================
CREATE INDEX idx_medicine_name     ON medicine (medicine_name);
CREATE INDEX idx_medicine_category ON medicine (category_id);
CREATE INDEX idx_purchase_supplier ON purchase (supplier_id);
CREATE INDEX idx_purchase_user     ON purchase (user_id);
CREATE INDEX idx_purchase_date     ON purchase (purchase_date);
CREATE INDEX idx_pd_purchase       ON purchase_detail (purchase_id);
CREATE INDEX idx_pd_medicine       ON purchase_detail (medicine_id);
CREATE INDEX idx_batch_expiry      ON medicine_batch (expiry_date);
CREATE INDEX idx_sale_customer     ON sale (customer_id);
CREATE INDEX idx_sale_user         ON sale (user_id);
CREATE INDEX idx_sale_date         ON sale (sale_date);
CREATE INDEX idx_sd_batch          ON sale_detail (batch_id);

-- Check: should list 10 tables
SELECT table_name FROM user_tables ORDER BY table_name;
