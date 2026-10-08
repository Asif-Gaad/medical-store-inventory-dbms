-- =====================================================================
-- 04_sample_data.sql   (Phase 5)
-- Run ONLY on empty tables (IDs 1,2,3... are assumed by the inserts).
-- To redo: run 01_reset.sql, 02_create_tables.sql, 03_create_indexes.sql.
-- The '&' character is avoided in text; SET DEFINE OFF is a safety net.
-- Dates use SYSDATE offsets so expiry categories stay correct any day.
-- =====================================================================
SET DEFINE OFF;

-- ---------- Categories (IDs 1-6) -------------------------------------
INSERT INTO category (category_name, description) VALUES ('Pain and Fever', 'Painkillers and fever reducers');
INSERT INTO category (category_name, description) VALUES ('Antibiotics', 'Medicines that fight bacterial infections');
INSERT INTO category (category_name, description) VALUES ('Cough and Cold', 'Syrups and remedies for cough and allergies');
INSERT INTO category (category_name, description) VALUES ('Vitamins and Supplements', 'Multivitamins and mineral supplements');
INSERT INTO category (category_name, description) VALUES ('Digestive and Antacids', 'Stomach acid and digestion medicines');
INSERT INTO category (category_name, description) VALUES ('Diabetes Care', 'Medicines for blood sugar control');

-- ---------- Users (IDs 1-4) - demo passwords hashed with SHA-256 ------
INSERT INTO users (username, password_hash, full_name, role)
VALUES ('admin',    RAWTOHEX(STANDARD_HASH('admin123',  'SHA256')), 'Zubair Ahmed', 'ADMIN');
INSERT INTO users (username, password_hash, full_name, role)
VALUES ('hina.p',   RAWTOHEX(STANDARD_HASH('hina123',   'SHA256')), 'Hina Parveen', 'PHARMACIST');
INSERT INTO users (username, password_hash, full_name, role)
VALUES ('kamran.s', RAWTOHEX(STANDARD_HASH('kamran123', 'SHA256')), 'Kamran Shah',  'PHARMACIST');
INSERT INTO users (username, password_hash, full_name, role)
VALUES ('imran.k',  RAWTOHEX(STANDARD_HASH('imran123',  'SHA256')), 'Imran Khalid', 'STOREKEEPER');

-- ---------- Suppliers (IDs 1-4) --------------------------------------
INSERT INTO supplier (supplier_name, contact_person, phone, email, address)
VALUES ('Al-Shifa Medical Distributors', 'Tariq Mehmood', '021-32111111', 'sales@alshifa.example', 'Saddar, Karachi');
INSERT INTO supplier (supplier_name, contact_person, phone, email, address)
VALUES ('Karachi Pharma Traders', 'Nadeem Akhtar', '021-34222222', 'orders@kpt.example', 'SITE Area, Karachi');
INSERT INTO supplier (supplier_name, contact_person, phone, email, address)
VALUES ('Medico Wholesale', 'Sana Iqbal', '042-35333333', 'info@medico.example', 'Ravi Road, Lahore');
INSERT INTO supplier (supplier_name, contact_person, phone, email, address)
VALUES ('Healthline Distributors', 'Faisal Raza', '021-35444444', 'contact@healthline.example', 'Korangi Industrial Area, Karachi');

-- ---------- Customers (IDs 1-6) --------------------------------------
INSERT INTO customer (customer_name, phone, address) VALUES ('Ahmed Khan',      '0301-1234567', 'Gulshan-e-Iqbal, Karachi');
INSERT INTO customer (customer_name, phone, address) VALUES ('Sara Malik',      '0321-2345678', 'Clifton, Karachi');
INSERT INTO customer (customer_name, phone, address) VALUES ('Bilal Hussain',   '0333-3456789', 'North Nazimabad, Karachi');
INSERT INTO customer (customer_name, phone, address) VALUES ('Ayesha Siddiqui', '0345-4567890', 'DHA Phase 5, Karachi');
INSERT INTO customer (customer_name, phone, address) VALUES ('Usman Tariq',     '0300-5678901', 'Korangi, Karachi');
INSERT INTO customer (customer_name, phone, address) VALUES ('Fatima Noor',     '0312-6789012', 'Saddar, Karachi');

-- ---------- Medicines (IDs 1-12) -------------------------------------
INSERT INTO medicine (medicine_name, generic_name, strength, manufacturer, category_id, unit, selling_price, reorder_level)
VALUES ('Panadol',    'Paracetamol',                   '500 mg',      'GSK',                 1, 'Packet', 100, 10);
INSERT INTO medicine (medicine_name, generic_name, strength, manufacturer, category_id, unit, selling_price, reorder_level)
VALUES ('Brufen',     'Ibuprofen',                     '400 mg',      'Abbott',              1, 'Packet', 150, 15);
INSERT INTO medicine (medicine_name, generic_name, strength, manufacturer, category_id, unit, selling_price, reorder_level)
VALUES ('Calpol',     'Paracetamol',                   '120 mg/5 ml', 'GSK',                 1, 'Bottle', 180, 10);
INSERT INTO medicine (medicine_name, generic_name, strength, manufacturer, category_id, unit, selling_price, reorder_level)
VALUES ('Augmentin',  'Amoxicillin + Clavulanic acid', '625 mg',      'GSK',                 2, 'Packet', 520, 8);
INSERT INTO medicine (medicine_name, generic_name, strength, manufacturer, category_id, unit, selling_price, reorder_level)
VALUES ('Flagyl',     'Metronidazole',                 '400 mg',      'Sanofi',              2, 'Packet', 130, 10);
INSERT INTO medicine (medicine_name, generic_name, strength, manufacturer, category_id, unit, selling_price, reorder_level)
VALUES ('Benadryl',   'Diphenhydramine',               '120 ml',      'Johnson and Johnson', 3, 'Bottle', 250, 10);
INSERT INTO medicine (medicine_name, generic_name, strength, manufacturer, category_id, unit, selling_price, reorder_level)
VALUES ('Surbex-Z',   'Multivitamin + Zinc',           '30 tablets',  'Abbott',              4, 'Bottle', 450, 8);
INSERT INTO medicine (medicine_name, generic_name, strength, manufacturer, category_id, unit, selling_price, reorder_level)
VALUES ('Celin',      'Ascorbic acid (Vitamin C)',     '500 mg',      'GSK',                 4, 'Bottle', 120, 15);
INSERT INTO medicine (medicine_name, generic_name, strength, manufacturer, category_id, unit, selling_price, reorder_level)
VALUES ('Risek',      'Omeprazole',                    '20 mg',       'Getz Pharma',         5, 'Packet', 300, 12);
INSERT INTO medicine (medicine_name, generic_name, strength, manufacturer, category_id, unit, selling_price, reorder_level)
VALUES ('Motilium',   'Domperidone',                   '10 mg',       'Johnson and Johnson', 5, 'Packet', 220, 10);
INSERT INTO medicine (medicine_name, generic_name, strength, manufacturer, category_id, unit, selling_price, reorder_level)
VALUES ('Glucophage', 'Metformin',                     '500 mg',      'Merck',               6, 'Packet', 190, 10);
INSERT INTO medicine (medicine_name, generic_name, strength, manufacturer, category_id, unit, selling_price, reorder_level)
VALUES ('Disprin',    'Aspirin',                       '300 mg',      'Reckitt',             1, 'Packet', 60, 20);

-- ---------- Purchase headers (IDs 1-6) -------------------------------
INSERT INTO purchase (supplier_id, user_id, purchase_date, invoice_no, total_amount) VALUES (1, 4, TRUNC(SYSDATE) - 90, 'AS-1001',  27200);
INSERT INTO purchase (supplier_id, user_id, purchase_date, invoice_no, total_amount) VALUES (2, 4, TRUNC(SYSDATE) - 75, 'KPT-554',  16300);
INSERT INTO purchase (supplier_id, user_id, purchase_date, invoice_no, total_amount) VALUES (3, 4, TRUNC(SYSDATE) - 60, 'MW-2207',  22500);
INSERT INTO purchase (supplier_id, user_id, purchase_date, invoice_no, total_amount) VALUES (4, 4, TRUNC(SYSDATE) - 40, 'HL-3391',  16500);
INSERT INTO purchase (supplier_id, user_id, purchase_date, invoice_no, total_amount) VALUES (1, 1, TRUNC(SYSDATE) - 20, 'AS-1042',   9100);
INSERT INTO purchase (supplier_id, user_id, purchase_date, invoice_no, total_amount) VALUES (2, 4, TRUNC(SYSDATE) - 5,  'KPT-601', 12280);

-- ---------- Purchase lines (IDs 1-16) --------------------------------
-- columns: purchase_id, medicine_id, quantity, purchase_price
INSERT INTO purchase_detail (purchase_id, medicine_id, quantity, purchase_price) VALUES (1, 1,  100,  80);  -- 1  Panadol    P001
INSERT INTO purchase_detail (purchase_id, medicine_id, quantity, purchase_price) VALUES (1, 2,   60, 120);  -- 2  Brufen     B101
INSERT INTO purchase_detail (purchase_id, medicine_id, quantity, purchase_price) VALUES (1, 4,   30, 400);  -- 3  Augmentin  A201
INSERT INTO purchase_detail (purchase_id, medicine_id, quantity, purchase_price) VALUES (2, 5,   50, 100);  -- 4  Flagyl     F301
INSERT INTO purchase_detail (purchase_id, medicine_id, quantity, purchase_price) VALUES (2, 6,   40, 195);  -- 5  Benadryl   BN401
INSERT INTO purchase_detail (purchase_id, medicine_id, quantity, purchase_price) VALUES (2, 3,   25, 140);  -- 6  Calpol     C501
INSERT INTO purchase_detail (purchase_id, medicine_id, quantity, purchase_price) VALUES (3, 7,   20, 360);  -- 7  Surbex-Z   S601
INSERT INTO purchase_detail (purchase_id, medicine_id, quantity, purchase_price) VALUES (3, 8,   60,  95);  -- 8  Celin      V701
INSERT INTO purchase_detail (purchase_id, medicine_id, quantity, purchase_price) VALUES (3, 9,   40, 240);  -- 9  Risek      R801
INSERT INTO purchase_detail (purchase_id, medicine_id, quantity, purchase_price) VALUES (4, 10,  30, 175);  -- 10 Motilium   M901
INSERT INTO purchase_detail (purchase_id, medicine_id, quantity, purchase_price) VALUES (4, 11,  45, 150);  -- 11 Glucophage G1001
INSERT INTO purchase_detail (purchase_id, medicine_id, quantity, purchase_price) VALUES (4, 12, 100,  45);  -- 12 Disprin    D1101
INSERT INTO purchase_detail (purchase_id, medicine_id, quantity, purchase_price) VALUES (5, 1,   50,  82);  -- 13 Panadol    P002
INSERT INTO purchase_detail (purchase_id, medicine_id, quantity, purchase_price) VALUES (5, 2,   40, 125);  -- 14 Brufen     B102
INSERT INTO purchase_detail (purchase_id, medicine_id, quantity, purchase_price) VALUES (6, 4,   20, 410);  -- 15 Augmentin  A202
INSERT INTO purchase_detail (purchase_id, medicine_id, quantity, purchase_price) VALUES (6, 5,   40, 102);  -- 16 Flagyl     F302

-- ---------- Batches (one per purchase line) --------------------------
-- quantity_remaining = received - already sold (historical load).
-- In Phase 7 a procedure will maintain this automatically.
INSERT INTO medicine_batch (purchase_detail_id, batch_no, expiry_date, quantity_remaining) VALUES (1,  'P001',  DATE '2028-12-31',    45);
INSERT INTO medicine_batch (purchase_detail_id, batch_no, expiry_date, quantity_remaining) VALUES (2,  'B101',  TRUNC(SYSDATE) + 25,  20);  -- expires within 30 days
INSERT INTO medicine_batch (purchase_detail_id, batch_no, expiry_date, quantity_remaining) VALUES (3,  'A201',  TRUNC(SYSDATE) + 300, 15);
INSERT INTO medicine_batch (purchase_detail_id, batch_no, expiry_date, quantity_remaining) VALUES (4,  'F301',  TRUNC(SYSDATE) - 20,  20);  -- EXPIRED
INSERT INTO medicine_batch (purchase_detail_id, batch_no, expiry_date, quantity_remaining) VALUES (5,  'BN401', TRUNC(SYSDATE) + 50,  32);  -- expires within 60 days
INSERT INTO medicine_batch (purchase_detail_id, batch_no, expiry_date, quantity_remaining) VALUES (6,  'C501',  TRUNC(SYSDATE) + 400,  8);
INSERT INTO medicine_batch (purchase_detail_id, batch_no, expiry_date, quantity_remaining) VALUES (7,  'S601',  TRUNC(SYSDATE) + 200,  7);
INSERT INTO medicine_batch (purchase_detail_id, batch_no, expiry_date, quantity_remaining) VALUES (8,  'V701',  TRUNC(SYSDATE) + 500, 50);
INSERT INTO medicine_batch (purchase_detail_id, batch_no, expiry_date, quantity_remaining) VALUES (9,  'R801',  TRUNC(SYSDATE) + 20,  10);  -- expires within 30 days
INSERT INTO medicine_batch (purchase_detail_id, batch_no, expiry_date, quantity_remaining) VALUES (10, 'M901',  TRUNC(SYSDATE) + 600, 21);
INSERT INTO medicine_batch (purchase_detail_id, batch_no, expiry_date, quantity_remaining) VALUES (11, 'G1001', TRUNC(SYSDATE) + 700, 20);
INSERT INTO medicine_batch (purchase_detail_id, batch_no, expiry_date, quantity_remaining) VALUES (12, 'D1101', TRUNC(SYSDATE) + 450, 50);
INSERT INTO medicine_batch (purchase_detail_id, batch_no, expiry_date, quantity_remaining) VALUES (13, 'P002',  TRUNC(SYSDATE) + 900, 35);
INSERT INTO medicine_batch (purchase_detail_id, batch_no, expiry_date, quantity_remaining) VALUES (14, 'B102',  TRUNC(SYSDATE) + 600, 34);
INSERT INTO medicine_batch (purchase_detail_id, batch_no, expiry_date, quantity_remaining) VALUES (15, 'A202',  TRUNC(SYSDATE) + 550, 17);
INSERT INTO medicine_batch (purchase_detail_id, batch_no, expiry_date, quantity_remaining) VALUES (16, 'F302',  TRUNC(SYSDATE) + 420, 40);

-- ---------- Sale headers (IDs 1-13); customer NULL = walk-in ---------
INSERT INTO sale (customer_id, user_id, sale_date, total_amount) VALUES (1,    2, TRUNC(SYSDATE) - 60 + 10/24, 2500);  -- S1
INSERT INTO sale (customer_id, user_id, sale_date, total_amount) VALUES (2,    3, TRUNC(SYSDATE) - 55 + 11/24, 3800);  -- S2
INSERT INTO sale (customer_id, user_id, sale_date, total_amount) VALUES (NULL, 2, TRUNC(SYSDATE) - 50 + 15/24, 3200);  -- S3 walk-in
INSERT INTO sale (customer_id, user_id, sale_date, total_amount) VALUES (3,    3, TRUNC(SYSDATE) - 45 + 12/24, 3080);  -- S4
INSERT INTO sale (customer_id, user_id, sale_date, total_amount) VALUES (NULL, 2, TRUNC(SYSDATE) - 35 + 16/24, 5600);  -- S5 walk-in
INSERT INTO sale (customer_id, user_id, sale_date, total_amount) VALUES (4,    2, TRUNC(SYSDATE) - 30 + 10/24, 6400);  -- S6
INSERT INTO sale (customer_id, user_id, sale_date, total_amount) VALUES (5,    3, TRUNC(SYSDATE) - 25 + 13/24, 4825);  -- S7
INSERT INTO sale (customer_id, user_id, sale_date, total_amount) VALUES (NULL, 2, TRUNC(SYSDATE) - 18 + 17/24, 4300);  -- S8 walk-in
INSERT INTO sale (customer_id, user_id, sale_date, total_amount) VALUES (1,    3, TRUNC(SYSDATE) - 12 + 11/24, 4230);  -- S9
INSERT INTO sale (customer_id, user_id, sale_date, total_amount) VALUES (6,    2, TRUNC(SYSDATE) - 8  + 14/24, 9600);  -- S10
INSERT INTO sale (customer_id, user_id, sale_date, total_amount) VALUES (2,    3, TRUNC(SYSDATE) - 3  + 12/24, 5150);  -- S11
INSERT INTO sale (customer_id, user_id, sale_date, total_amount) VALUES (NULL, 2, TRUNC(SYSDATE) + 9/24,      2580);  -- S12 today, walk-in
INSERT INTO sale (customer_id, user_id, sale_date, total_amount) VALUES (3,    3, TRUNC(SYSDATE) + 10/24,     2460);  -- S13 today

-- ---------- Sale lines (28 rows) -------------------------------------
-- columns: sale_id, batch_id (looked up by batch number), quantity, unit_price, discount
INSERT INTO sale_detail (sale_id, batch_id, quantity, unit_price, discount) SELECT 1,  batch_id, 10, 100,   0 FROM medicine_batch WHERE batch_no = 'P001';
INSERT INTO sale_detail (sale_id, batch_id, quantity, unit_price, discount) SELECT 1,  batch_id, 10, 150,   0 FROM medicine_batch WHERE batch_no = 'B101';
INSERT INTO sale_detail (sale_id, batch_id, quantity, unit_price, discount) SELECT 2,  batch_id,  5, 520, 100 FROM medicine_batch WHERE batch_no = 'A201';
INSERT INTO sale_detail (sale_id, batch_id, quantity, unit_price, discount) SELECT 2,  batch_id, 10, 130,   0 FROM medicine_batch WHERE batch_no = 'F301';
INSERT INTO sale_detail (sale_id, batch_id, quantity, unit_price, discount) SELECT 3,  batch_id, 20, 100,   0 FROM medicine_batch WHERE batch_no = 'P001';
INSERT INTO sale_detail (sale_id, batch_id, quantity, unit_price, discount) SELECT 3,  batch_id, 10, 120,   0 FROM medicine_batch WHERE batch_no = 'V701';
INSERT INTO sale_detail (sale_id, batch_id, quantity, unit_price, discount) SELECT 4,  batch_id,  8, 250,   0 FROM medicine_batch WHERE batch_no = 'BN401';
INSERT INTO sale_detail (sale_id, batch_id, quantity, unit_price, discount) SELECT 4,  batch_id,  6, 180,   0 FROM medicine_batch WHERE batch_no = 'C501';
INSERT INTO sale_detail (sale_id, batch_id, quantity, unit_price, discount) SELECT 5,  batch_id, 15, 300,   0 FROM medicine_batch WHERE batch_no = 'R801';
INSERT INTO sale_detail (sale_id, batch_id, quantity, unit_price, discount) SELECT 5,  batch_id,  5, 220,   0 FROM medicine_batch WHERE batch_no = 'M901';
INSERT INTO sale_detail (sale_id, batch_id, quantity, unit_price, discount) SELECT 6,  batch_id,  8, 450,  50 FROM medicine_batch WHERE batch_no = 'S601';
INSERT INTO sale_detail (sale_id, batch_id, quantity, unit_price, discount) SELECT 6,  batch_id, 15, 190,   0 FROM medicine_batch WHERE batch_no = 'G1001';
INSERT INTO sale_detail (sale_id, batch_id, quantity, unit_price, discount) SELECT 7,  batch_id, 20, 130,   0 FROM medicine_batch WHERE batch_no = 'F301';
INSERT INTO sale_detail (sale_id, batch_id, quantity, unit_price, discount) SELECT 7,  batch_id, 15, 150,  25 FROM medicine_batch WHERE batch_no = 'B101';
INSERT INTO sale_detail (sale_id, batch_id, quantity, unit_price, discount) SELECT 8,  batch_id, 25, 100,   0 FROM medicine_batch WHERE batch_no = 'P001';
INSERT INTO sale_detail (sale_id, batch_id, quantity, unit_price, discount) SELECT 8,  batch_id, 30,  60,   0 FROM medicine_batch WHERE batch_no = 'D1101';
INSERT INTO sale_detail (sale_id, batch_id, quantity, unit_price, discount) SELECT 9,  batch_id, 11, 180,   0 FROM medicine_batch WHERE batch_no = 'C501';
INSERT INTO sale_detail (sale_id, batch_id, quantity, unit_price, discount) SELECT 9,  batch_id,  5, 450,   0 FROM medicine_batch WHERE batch_no = 'S601';
INSERT INTO sale_detail (sale_id, batch_id, quantity, unit_price, discount) SELECT 10, batch_id, 15, 300, 100 FROM medicine_batch WHERE batch_no = 'R801';
INSERT INTO sale_detail (sale_id, batch_id, quantity, unit_price, discount) SELECT 10, batch_id, 10, 520,   0 FROM medicine_batch WHERE batch_no = 'A201';
INSERT INTO sale_detail (sale_id, batch_id, quantity, unit_price, discount) SELECT 11, batch_id, 15, 150,   0 FROM medicine_batch WHERE batch_no = 'B101';
INSERT INTO sale_detail (sale_id, batch_id, quantity, unit_price, discount) SELECT 11, batch_id, 10, 100,   0 FROM medicine_batch WHERE batch_no = 'P002';
INSERT INTO sale_detail (sale_id, batch_id, quantity, unit_price, discount) SELECT 11, batch_id, 10, 190,   0 FROM medicine_batch WHERE batch_no = 'G1001';
INSERT INTO sale_detail (sale_id, batch_id, quantity, unit_price, discount) SELECT 12, batch_id,  5, 100,   0 FROM medicine_batch WHERE batch_no = 'P002';
INSERT INTO sale_detail (sale_id, batch_id, quantity, unit_price, discount) SELECT 12, batch_id,  4, 220,   0 FROM medicine_batch WHERE batch_no = 'M901';
INSERT INTO sale_detail (sale_id, batch_id, quantity, unit_price, discount) SELECT 12, batch_id, 20,  60,   0 FROM medicine_batch WHERE batch_no = 'D1101';
INSERT INTO sale_detail (sale_id, batch_id, quantity, unit_price, discount) SELECT 13, batch_id,  3, 520,   0 FROM medicine_batch WHERE batch_no = 'A202';
INSERT INTO sale_detail (sale_id, batch_id, quantity, unit_price, discount) SELECT 13, batch_id,  6, 150,   0 FROM medicine_batch WHERE batch_no = 'B102';

COMMIT;
