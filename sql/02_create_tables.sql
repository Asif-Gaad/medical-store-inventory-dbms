-- =====================================================================
-- 02_create_tables.sql   (Phase 4)
-- Creates the 10 tables. Parent tables come first.
-- Requires Oracle 12c or newer (identity columns).
-- =====================================================================

-- 1. USERS ------------------------------------------------------------
CREATE TABLE users (
    user_id        NUMBER(10)    GENERATED ALWAYS AS IDENTITY,
    username       VARCHAR2(50)  NOT NULL,
    password_hash  VARCHAR2(255) NOT NULL,
    full_name      VARCHAR2(100) NOT NULL,
    role           VARCHAR2(20)  NOT NULL,
    is_active      NUMBER(1)     DEFAULT 1 NOT NULL,
    created_at     TIMESTAMP     DEFAULT SYSTIMESTAMP NOT NULL,
    CONSTRAINT pk_users          PRIMARY KEY (user_id),
    CONSTRAINT uq_users_username UNIQUE (username),
    CONSTRAINT ck_users_role     CHECK (role IN ('ADMIN', 'PHARMACIST', 'STOREKEEPER')),
    CONSTRAINT ck_users_active   CHECK (is_active IN (0, 1))
);

-- 2. CATEGORY ---------------------------------------------------------
CREATE TABLE category (
    category_id    NUMBER(10)    GENERATED ALWAYS AS IDENTITY,
    category_name  VARCHAR2(60)  NOT NULL,
    description    VARCHAR2(200),
    CONSTRAINT pk_category      PRIMARY KEY (category_id),
    CONSTRAINT uq_category_name UNIQUE (category_name)
);

-- 3. SUPPLIER ---------------------------------------------------------
CREATE TABLE supplier (
    supplier_id     NUMBER(10)    GENERATED ALWAYS AS IDENTITY,
    supplier_name   VARCHAR2(100) NOT NULL,
    contact_person  VARCHAR2(100),
    phone           VARCHAR2(20)  NOT NULL,
    email           VARCHAR2(100),
    address         VARCHAR2(200),
    CONSTRAINT pk_supplier      PRIMARY KEY (supplier_id),
    CONSTRAINT uq_supplier_name UNIQUE (supplier_name)
);

-- 4. CUSTOMER ---------------------------------------------------------
CREATE TABLE customer (
    customer_id    NUMBER(10)    GENERATED ALWAYS AS IDENTITY,
    customer_name  VARCHAR2(100) NOT NULL,
    phone          VARCHAR2(20),
    address        VARCHAR2(200),
    CONSTRAINT pk_customer       PRIMARY KEY (customer_id),
    CONSTRAINT uq_customer_phone UNIQUE (phone)
);

-- 5. MEDICINE ---------------------------------------------------------
CREATE TABLE medicine (
    medicine_id    NUMBER(10)    GENERATED ALWAYS AS IDENTITY,
    medicine_name  VARCHAR2(100) NOT NULL,
    generic_name   VARCHAR2(100),
    strength       VARCHAR2(50)  NOT NULL,
    manufacturer   VARCHAR2(100) NOT NULL,
    category_id    NUMBER(10)    NOT NULL,
    unit           VARCHAR2(20)  NOT NULL,
    selling_price  NUMBER(10,2)  NOT NULL,
    reorder_level  NUMBER(6)     DEFAULT 10 NOT NULL,
    is_active      NUMBER(1)     DEFAULT 1 NOT NULL,
    CONSTRAINT pk_medicine          PRIMARY KEY (medicine_id),
    CONSTRAINT uq_medicine          UNIQUE (medicine_name, strength, manufacturer),
    CONSTRAINT fk_medicine_category FOREIGN KEY (category_id) REFERENCES category (category_id),
    CONSTRAINT ck_medicine_price    CHECK (selling_price >= 0),
    CONSTRAINT ck_medicine_reorder  CHECK (reorder_level >= 0),
    CONSTRAINT ck_medicine_active   CHECK (is_active IN (0, 1))
);

-- 6. PURCHASE (header) ------------------------------------------------
CREATE TABLE purchase (
    purchase_id    NUMBER(10)    GENERATED ALWAYS AS IDENTITY,
    supplier_id    NUMBER(10)    NOT NULL,
    user_id        NUMBER(10)    NOT NULL,
    purchase_date  DATE          DEFAULT SYSDATE NOT NULL,
    invoice_no     VARCHAR2(30),
    total_amount   NUMBER(12,2)  DEFAULT 0 NOT NULL,
    CONSTRAINT pk_purchase          PRIMARY KEY (purchase_id),
    CONSTRAINT uq_purchase_invoice  UNIQUE (supplier_id, invoice_no),
    CONSTRAINT fk_purchase_supplier FOREIGN KEY (supplier_id) REFERENCES supplier (supplier_id),
    CONSTRAINT fk_purchase_user     FOREIGN KEY (user_id)     REFERENCES users (user_id),
    CONSTRAINT ck_purchase_total    CHECK (total_amount >= 0)
);

-- 7. PURCHASE_DETAIL (lines) -----------------------------------------
CREATE TABLE purchase_detail (
    purchase_detail_id  NUMBER(10)   GENERATED ALWAYS AS IDENTITY,
    purchase_id         NUMBER(10)   NOT NULL,
    medicine_id         NUMBER(10)   NOT NULL,
    quantity            NUMBER(6)    NOT NULL,
    purchase_price      NUMBER(10,2) NOT NULL,
    CONSTRAINT pk_purchase_detail PRIMARY KEY (purchase_detail_id),
    CONSTRAINT fk_pd_purchase     FOREIGN KEY (purchase_id) REFERENCES purchase (purchase_id),
    CONSTRAINT fk_pd_medicine     FOREIGN KEY (medicine_id) REFERENCES medicine (medicine_id),
    CONSTRAINT ck_pd_quantity     CHECK (quantity > 0),
    CONSTRAINT ck_pd_price        CHECK (purchase_price >= 0)
);

-- 8. MEDICINE_BATCH (physical stock lots) ----------------------------
CREATE TABLE medicine_batch (
    batch_id            NUMBER(10)   GENERATED ALWAYS AS IDENTITY,
    purchase_detail_id  NUMBER(10)   NOT NULL,
    batch_no            VARCHAR2(30) NOT NULL,
    expiry_date         DATE         NOT NULL,
    quantity_remaining  NUMBER(6)    NOT NULL,
    CONSTRAINT pk_medicine_batch  PRIMARY KEY (batch_id),
    CONSTRAINT uq_batch_pd        UNIQUE (purchase_detail_id),
    CONSTRAINT fk_batch_pd        FOREIGN KEY (purchase_detail_id) REFERENCES purchase_detail (purchase_detail_id),
    CONSTRAINT ck_batch_remaining CHECK (quantity_remaining >= 0)
);

-- 9. SALE (header) ----------------------------------------------------
CREATE TABLE sale (
    sale_id       NUMBER(10)    GENERATED ALWAYS AS IDENTITY,
    customer_id   NUMBER(10),                       -- NULL = walk-in customer
    user_id       NUMBER(10)    NOT NULL,
    sale_date     DATE          DEFAULT SYSDATE NOT NULL,
    total_amount  NUMBER(12,2)  DEFAULT 0 NOT NULL,
    CONSTRAINT pk_sale          PRIMARY KEY (sale_id),
    CONSTRAINT fk_sale_customer FOREIGN KEY (customer_id) REFERENCES customer (customer_id),
    CONSTRAINT fk_sale_user     FOREIGN KEY (user_id)     REFERENCES users (user_id),
    CONSTRAINT ck_sale_total    CHECK (total_amount >= 0)
);

-- 10. SALE_DETAIL (lines) --------------------------------------------
CREATE TABLE sale_detail (
    sale_detail_id  NUMBER(10)   GENERATED ALWAYS AS IDENTITY,
    sale_id         NUMBER(10)   NOT NULL,
    batch_id        NUMBER(10)   NOT NULL,
    quantity        NUMBER(6)    NOT NULL,
    unit_price      NUMBER(10,2) NOT NULL,
    discount        NUMBER(10,2) DEFAULT 0 NOT NULL,   -- discount in Rs. for this line
    CONSTRAINT pk_sale_detail  PRIMARY KEY (sale_detail_id),
    CONSTRAINT uq_sale_batch   UNIQUE (sale_id, batch_id),
    CONSTRAINT fk_sd_sale      FOREIGN KEY (sale_id)  REFERENCES sale (sale_id),
    CONSTRAINT fk_sd_batch     FOREIGN KEY (batch_id) REFERENCES medicine_batch (batch_id),
    CONSTRAINT ck_sd_quantity  CHECK (quantity > 0),
    CONSTRAINT ck_sd_price     CHECK (unit_price >= 0),
    CONSTRAINT ck_sd_discount  CHECK (discount >= 0 AND discount <= quantity * unit_price)
);
