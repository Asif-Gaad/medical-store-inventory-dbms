-- =====================================================================
-- 07_views_functions.sql   (Phase 7, part 1)
-- 2 functions + 6 views. Safe to run again (CREATE OR REPLACE).
-- Run with F5 (Run Script). Each PL/SQL block ends with a "/" line.
-- =====================================================================

-- ---------------------------------------------------------------------
-- FUNCTION 1: expiry status of a date
-- Why: the same CASE logic (Expired / 30 / 60 / Valid) was copied in many
-- queries. Now it lives in ONE place; change it once, everything updates.
-- ---------------------------------------------------------------------
CREATE OR REPLACE FUNCTION fn_expiry_status (p_expiry_date IN DATE)
RETURN VARCHAR2
IS
BEGIN
    IF p_expiry_date < TRUNC(SYSDATE) THEN
        RETURN 'EXPIRED';
    ELSIF p_expiry_date <= TRUNC(SYSDATE) + 30 THEN
        RETURN 'EXPIRES IN 30 DAYS';
    ELSIF p_expiry_date <= TRUNC(SYSDATE) + 60 THEN
        RETURN 'EXPIRES IN 60 DAYS';
    ELSE
        RETURN 'VALID';
    END IF;
END fn_expiry_status;
/

-- ---------------------------------------------------------------------
-- FUNCTION 2: sellable stock of one medicine (expired batches excluded)
-- Why: the sale procedure and the frontend both need this number.
-- ---------------------------------------------------------------------
CREATE OR REPLACE FUNCTION fn_available_stock (p_medicine_id IN NUMBER)
RETURN NUMBER
IS
    v_stock NUMBER;
BEGIN
    SELECT NVL(SUM(b.quantity_remaining), 0)
    INTO   v_stock
    FROM   medicine_batch b
    JOIN   purchase_detail pd ON pd.purchase_detail_id = b.purchase_detail_id
    WHERE  pd.medicine_id = p_medicine_id
    AND    b.expiry_date >= TRUNC(SYSDATE);

    RETURN v_stock;
END fn_available_stock;
/

-- ---------------------------------------------------------------------
-- VIEW 1: every batch with medicine name, cost, days left, expiry status
-- Why: hides the long chain batch -> purchase_detail -> medicine
-- (created in Phase 3 normalization) behind one simple "table".
-- ---------------------------------------------------------------------
CREATE OR REPLACE VIEW v_batch_stock AS
SELECT b.batch_id,
       m.medicine_id,
       m.medicine_name,
       m.strength,
       b.batch_no,
       b.quantity_remaining,
       pd.purchase_price                  AS cost_price,
       m.selling_price,
       b.expiry_date,
       b.expiry_date - TRUNC(SYSDATE)     AS days_left,
       fn_expiry_status(b.expiry_date)    AS expiry_status
FROM   medicine_batch b
JOIN   purchase_detail pd ON pd.purchase_detail_id = b.purchase_detail_id
JOIN   medicine m         ON m.medicine_id = pd.medicine_id;

-- ---------------------------------------------------------------------
-- VIEW 2: stock per medicine with LOW STOCK / OUT OF STOCK / OK
-- Why: inventory screen, low-stock alert and dashboard all read this.
-- ---------------------------------------------------------------------
CREATE OR REPLACE VIEW v_medicine_stock AS
SELECT t.*,
       CASE WHEN t.available_stock = 0                THEN 'OUT OF STOCK'
            WHEN t.available_stock < t.reorder_level  THEN 'LOW STOCK'
            ELSE 'OK'
       END AS stock_status
FROM  (SELECT m.medicine_id,
              m.medicine_name,
              m.strength,
              c.category_name,
              m.unit,
              m.selling_price,
              m.reorder_level,
              NVL(SUM(b.quantity_remaining), 0) AS total_stock,
              NVL(SUM(CASE WHEN b.expiry_date >= TRUNC(SYSDATE)
                           THEN b.quantity_remaining END), 0) AS available_stock,
              NVL(SUM(CASE WHEN b.expiry_date <  TRUNC(SYSDATE)
                           THEN b.quantity_remaining END), 0) AS expired_stock
       FROM   medicine m
       JOIN   category c            ON c.category_id = m.category_id
       LEFT JOIN purchase_detail pd ON pd.medicine_id = m.medicine_id
       LEFT JOIN medicine_batch b   ON b.purchase_detail_id = pd.purchase_detail_id
       WHERE  m.is_active = 1
       GROUP BY m.medicine_id, m.medicine_name, m.strength, c.category_name,
                m.unit, m.selling_price, m.reorder_level) t;

-- ---------------------------------------------------------------------
-- VIEW 3: one row per sale line, with names, line total and profit
-- Why: receipts, best sellers and profit reports all start from here.
-- ---------------------------------------------------------------------
CREATE OR REPLACE VIEW v_sale_lines AS
SELECT s.sale_id,
       s.sale_date,
       NVL(c.customer_name, 'Walk-in Customer') AS customer_name,
       u.full_name                              AS sold_by,
       m.medicine_name,
       b.batch_no,
       sd.quantity,
       sd.unit_price,
       sd.discount,
       sd.quantity * sd.unit_price - sd.discount AS line_total,
       (sd.quantity * sd.unit_price - sd.discount)
         - sd.quantity * pd.purchase_price       AS profit
FROM   sale s
JOIN   sale_detail sd     ON sd.sale_id = s.sale_id
JOIN   medicine_batch b   ON b.batch_id = sd.batch_id
JOIN   purchase_detail pd ON pd.purchase_detail_id = b.purchase_detail_id
JOIN   medicine m         ON m.medicine_id = pd.medicine_id
JOIN   users u            ON u.user_id = s.user_id
LEFT JOIN customer c      ON c.customer_id = s.customer_id;

-- ---------------------------------------------------------------------
-- VIEW 4: daily sales      VIEW 5: monthly sales
-- ---------------------------------------------------------------------
CREATE OR REPLACE VIEW v_daily_sales AS
SELECT TRUNC(sale_date) AS sale_day,
       COUNT(*)         AS number_of_sales,
       SUM(total_amount) AS total_sales
FROM   sale
GROUP BY TRUNC(sale_date);

CREATE OR REPLACE VIEW v_monthly_sales AS
SELECT TO_CHAR(sale_date, 'YYYY-MM') AS sale_month,
       COUNT(*)                      AS number_of_sales,
       SUM(total_amount)             AS total_sales
FROM   sale
GROUP BY TO_CHAR(sale_date, 'YYYY-MM');

-- ---------------------------------------------------------------------
-- VIEW 6: dashboard numbers (one row) - used by the Phase 8 frontend
-- near_expiry / expired count BATCHES that still have stock
-- ---------------------------------------------------------------------
CREATE OR REPLACE VIEW v_dashboard AS
SELECT
  (SELECT COUNT(*) FROM medicine WHERE is_active = 1)                       AS total_medicines,
  (SELECT COUNT(*) FROM v_medicine_stock
    WHERE stock_status IN ('LOW STOCK', 'OUT OF STOCK'))                    AS low_stock,
  (SELECT COUNT(*) FROM medicine_batch
    WHERE quantity_remaining > 0
      AND expiry_date BETWEEN TRUNC(SYSDATE) AND TRUNC(SYSDATE) + 60)       AS near_expiry,
  (SELECT COUNT(*) FROM medicine_batch
    WHERE quantity_remaining > 0
      AND expiry_date < TRUNC(SYSDATE))                                     AS expired,
  (SELECT NVL(SUM(total_amount), 0) FROM sale
    WHERE sale_date >= TRUNC(SYSDATE) AND sale_date < TRUNC(SYSDATE) + 1)   AS todays_sales,
  (SELECT NVL(SUM(total_amount), 0) FROM purchase
    WHERE purchase_date >= TRUNC(SYSDATE) AND purchase_date < TRUNC(SYSDATE) + 1) AS todays_purchases
FROM dual;
