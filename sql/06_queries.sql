-- =====================================================================
-- 06_queries.sql   (Phase 6 - SQL queries)
-- Run ONE query at a time: click inside the query, press Ctrl+Enter.
-- Every query ends with a semicolon (;).
-- "Expected" comments are for the sample data of 04_sample_data.sql.
-- =====================================================================

-- ---------------------------------------------------------------------
-- Q1. ALL MEDICINES (with category name)            [JOIN]
-- Expected: 12 rows
-- ---------------------------------------------------------------------
SELECT m.medicine_id,
       m.medicine_name,
       m.strength,
       m.manufacturer,
       c.category_name,
       m.unit,
       m.selling_price,
       m.reorder_level
FROM   medicine m
JOIN   category c ON c.category_id = m.category_id
ORDER BY m.medicine_name;

-- ---------------------------------------------------------------------
-- Q2. SEARCH MEDICINE (by brand or generic name, any letter case)
-- Change 'pan' to anything you want to search.
-- Expected for 'pan': 1 row (Panadol).
-- Try 'paracetamol' instead: 2 rows (Panadol and Calpol).
-- ---------------------------------------------------------------------
SELECT medicine_id, medicine_name, generic_name, strength, selling_price
FROM   medicine
WHERE  UPPER(medicine_name) LIKE '%' || UPPER('pan') || '%'
   OR  UPPER(generic_name)  LIKE '%' || UPPER('pan') || '%';

-- ---------------------------------------------------------------------
-- Q3. BATCH-WISE STOCK WITH EXPIRY STATUS
-- Shows every batch, its medicine, quantity and how many days are left.
-- Expected: 16 rows; F301 = EXPIRED, R801 and B101 = EXPIRES IN 30 DAYS,
--           BN401 = EXPIRES IN 60 DAYS, all others = VALID
-- ---------------------------------------------------------------------
SELECT m.medicine_name,
       b.batch_no,
       b.quantity_remaining,
       b.expiry_date,
       b.expiry_date - TRUNC(SYSDATE) AS days_left,
       CASE
            WHEN b.expiry_date <  TRUNC(SYSDATE)      THEN 'EXPIRED'
            WHEN b.expiry_date <= TRUNC(SYSDATE) + 30 THEN 'EXPIRES IN 30 DAYS'
            WHEN b.expiry_date <= TRUNC(SYSDATE) + 60 THEN 'EXPIRES IN 60 DAYS'
            ELSE 'VALID'
       END AS expiry_status
FROM   medicine_batch b
JOIN   purchase_detail pd ON pd.purchase_detail_id = b.purchase_detail_id
JOIN   medicine m         ON m.medicine_id = pd.medicine_id
ORDER BY b.expiry_date;

-- ---------------------------------------------------------------------
-- Q4. AVAILABLE (SELLABLE) STOCK PER MEDICINE
-- Expired batches are NOT counted, because they cannot be sold.
-- Expected: Flagyl = 40 (not 60), Calpol = 8, Panadol = 80, Surbex-Z = 7
-- ---------------------------------------------------------------------
SELECT m.medicine_name,
       NVL(SUM(b.quantity_remaining), 0) AS available_stock
FROM   medicine m
LEFT JOIN purchase_detail pd ON pd.medicine_id = m.medicine_id
LEFT JOIN medicine_batch  b  ON b.purchase_detail_id = pd.purchase_detail_id
                            AND b.expiry_date >= TRUNC(SYSDATE)
GROUP BY m.medicine_name
ORDER BY m.medicine_name;

-- ---------------------------------------------------------------------
-- Q5. LOW STOCK MEDICINES                            [GROUP BY + HAVING]
-- Expected: Calpol (8 / 10), Risek (10 / 12), Surbex-Z (7 / 8)
-- ---------------------------------------------------------------------
SELECT m.medicine_name,
       NVL(SUM(b.quantity_remaining), 0) AS available_stock,
       m.reorder_level,
       'LOW STOCK' AS status
FROM   medicine m
LEFT JOIN purchase_detail pd ON pd.medicine_id = m.medicine_id
LEFT JOIN medicine_batch  b  ON b.purchase_detail_id = pd.purchase_detail_id
                            AND b.expiry_date >= TRUNC(SYSDATE)
WHERE  m.is_active = 1
GROUP BY m.medicine_name, m.reorder_level
HAVING NVL(SUM(b.quantity_remaining), 0) < m.reorder_level
ORDER BY m.medicine_name;

-- ---------------------------------------------------------------------
-- Q6. EXPIRED MEDICINES (still in the shelf)
-- cost_lost = money we paid for the units we can no longer sell.
-- Expected: 1 row: Flagyl, batch F301, 20 units, cost_lost = 2000
-- ---------------------------------------------------------------------
SELECT m.medicine_name,
       b.batch_no,
       b.expiry_date,
       b.quantity_remaining,
       b.quantity_remaining * pd.purchase_price AS cost_lost
FROM   medicine_batch b
JOIN   purchase_detail pd ON pd.purchase_detail_id = b.purchase_detail_id
JOIN   medicine m         ON m.medicine_id = pd.medicine_id
WHERE  b.expiry_date < TRUNC(SYSDATE)
  AND  b.quantity_remaining > 0
ORDER BY b.expiry_date;

-- ---------------------------------------------------------------------
-- Q7. NEAR-EXPIRY MEDICINES (valid today, but expiring within 60 days)
-- Expected: R801 (20 days), B101 (25 days) -> 30-day group
--           BN401 (50 days)                 -> 60-day group
-- ---------------------------------------------------------------------
SELECT m.medicine_name,
       b.batch_no,
       b.quantity_remaining,
       b.expiry_date,
       b.expiry_date - TRUNC(SYSDATE) AS days_left,
       CASE WHEN b.expiry_date <= TRUNC(SYSDATE) + 30
            THEN 'WITHIN 30 DAYS' ELSE 'WITHIN 60 DAYS' END AS alert_group
FROM   medicine_batch b
JOIN   purchase_detail pd ON pd.purchase_detail_id = b.purchase_detail_id
JOIN   medicine m         ON m.medicine_id = pd.medicine_id
WHERE  b.expiry_date BETWEEN TRUNC(SYSDATE) AND TRUNC(SYSDATE) + 60
  AND  b.quantity_remaining > 0
ORDER BY b.expiry_date;

-- ---------------------------------------------------------------------
-- Q8. TODAY'S SALES (list of receipts)
-- A date range is used (not TRUNC on the column) so the index is usable.
-- Expected: 2 rows (sale 12 = 2580 walk-in, sale 13 = 2460 Bilal Hussain)
-- ---------------------------------------------------------------------
SELECT s.sale_id,
       s.sale_date,
       NVL(c.customer_name, 'Walk-in Customer') AS customer,
       u.full_name AS sold_by,
       s.total_amount
FROM   sale s
LEFT JOIN customer c ON c.customer_id = s.customer_id
JOIN   users u       ON u.user_id = s.user_id
WHERE  s.sale_date >= TRUNC(SYSDATE)
  AND  s.sale_date <  TRUNC(SYSDATE) + 1
ORDER BY s.sale_date;

-- Q8b. Today's total sales
-- Expected: 5040
SELECT NVL(SUM(total_amount), 0) AS todays_sales
FROM   sale
WHERE  sale_date >= TRUNC(SYSDATE)
  AND  sale_date <  TRUNC(SYSDATE) + 1;

-- ---------------------------------------------------------------------
-- Q9. MONTHLY SALES                                  [GROUP BY]
-- Numbers per month depend on the day you run it, but the sum of all
-- rows must be 57725.
-- ---------------------------------------------------------------------
SELECT TO_CHAR(sale_date, 'YYYY-MM') AS sale_month,
       COUNT(*)                      AS number_of_sales,
       SUM(total_amount)             AS total_sales
FROM   sale
GROUP BY TO_CHAR(sale_date, 'YYYY-MM')
ORDER BY sale_month;

-- ---------------------------------------------------------------------
-- Q10. SUPPLIER PURCHASES (all suppliers, with totals)
-- Expected: Al-Shifa 2 purchases 36300; Karachi Pharma 2 purchases 28580;
--           Medico 1 purchase 22500; Healthline 1 purchase 16500
-- ---------------------------------------------------------------------
SELECT s.supplier_name,
       COUNT(p.purchase_id)             AS number_of_purchases,
       NVL(SUM(p.total_amount), 0)      AS total_purchased
FROM   supplier s
LEFT JOIN purchase p ON p.supplier_id = s.supplier_id
GROUP BY s.supplier_name
ORDER BY total_purchased DESC;

-- Q10b. Suppliers we spent MORE than Rs. 20,000 with         [HAVING]
-- Expected: Al-Shifa (36300), Karachi Pharma (28580), Medico (22500)
SELECT s.supplier_name,
       SUM(p.total_amount) AS total_purchased
FROM   supplier s
JOIN   purchase p ON p.supplier_id = s.supplier_id
GROUP BY s.supplier_name
HAVING SUM(p.total_amount) > 20000
ORDER BY total_purchased DESC;

-- Q10c. Purchase history: every purchase line with supplier and medicine
-- Expected: 16 rows
SELECT p.purchase_date,
       p.invoice_no,
       s.supplier_name,
       m.medicine_name,
       pd.quantity,
       pd.purchase_price,
       pd.quantity * pd.purchase_price AS line_total
FROM   purchase p
JOIN   supplier s         ON s.supplier_id = p.supplier_id
JOIN   purchase_detail pd ON pd.purchase_id = p.purchase_id
JOIN   medicine m         ON m.medicine_id = pd.medicine_id
ORDER BY p.purchase_date, p.invoice_no;

-- ---------------------------------------------------------------------
-- Q11. CUSTOMER PURCHASES (walk-in customers grouped together)
-- Expected: Walk-in 4 sales 15680; Bilal 2 / 5540; Ahmed 2 / 6730;
--           Sara 2 / 8950; Ayesha 1 / 6400; Usman 1 / 4825; Fatima 1 / 9600
-- ---------------------------------------------------------------------
SELECT NVL(c.customer_name, 'Walk-in Customer') AS customer,
       COUNT(s.sale_id)                          AS number_of_sales,
       SUM(s.total_amount)                       AS total_spent
FROM   sale s
LEFT JOIN customer c ON c.customer_id = s.customer_id
GROUP BY NVL(c.customer_name, 'Walk-in Customer')
ORDER BY total_spent DESC;

-- ---------------------------------------------------------------------
-- Q12. TOTAL SALES and TOTAL PURCHASES
-- Expected: total_sales = 57725, total_purchases = 103880
-- ---------------------------------------------------------------------
SELECT (SELECT SUM(total_amount) FROM sale)     AS total_sales,
       (SELECT SUM(total_amount) FROM purchase) AS total_purchases
FROM   dual;

-- ---------------------------------------------------------------------
-- Q13. ESTIMATED PROFIT
-- profit = what we received (price x qty - discount)
--          minus what those units cost us (purchase price x qty)
-- Expected: revenue 57725, cost 45755, profit 11970
-- ---------------------------------------------------------------------
SELECT SUM(sd.quantity * sd.unit_price - sd.discount) AS revenue,
       SUM(sd.quantity * pd.purchase_price)           AS cost_of_goods,
       SUM(sd.quantity * sd.unit_price - sd.discount)
         - SUM(sd.quantity * pd.purchase_price)       AS estimated_profit
FROM   sale_detail sd
JOIN   medicine_batch b   ON b.batch_id = sd.batch_id
JOIN   purchase_detail pd ON pd.purchase_detail_id = b.purchase_detail_id;

-- Q13b. Profit per medicine
-- Expected top: Augmentin 2030, Risek 1700, Panadol 1370, Brufen 1325 ...
SELECT m.medicine_name,
       SUM(sd.quantity * sd.unit_price - sd.discount)                     AS revenue,
       SUM(sd.quantity * sd.unit_price - sd.discount
           - sd.quantity * pd.purchase_price)                             AS profit
FROM   sale_detail sd
JOIN   medicine_batch b   ON b.batch_id = sd.batch_id
JOIN   purchase_detail pd ON pd.purchase_detail_id = b.purchase_detail_id
JOIN   medicine m         ON m.medicine_id = pd.medicine_id
GROUP BY m.medicine_name
ORDER BY profit DESC;

-- ---------------------------------------------------------------------
-- Q14. BEST-SELLING MEDICINES (top 5 by units sold)
-- Expected: Panadol 70, Disprin 50, Brufen 46, Flagyl 30, Risek 30
-- ---------------------------------------------------------------------
SELECT m.medicine_name,
       SUM(sd.quantity) AS units_sold,
       SUM(sd.quantity * sd.unit_price - sd.discount) AS revenue
FROM   sale_detail sd
JOIN   medicine_batch b   ON b.batch_id = sd.batch_id
JOIN   purchase_detail pd ON pd.purchase_detail_id = b.purchase_detail_id
JOIN   medicine m         ON m.medicine_id = pd.medicine_id
GROUP BY m.medicine_name
ORDER BY units_sold DESC, m.medicine_name
FETCH FIRST 5 ROWS ONLY;

-- ---------------------------------------------------------------------
-- Q15. SUBQUERY EXAMPLE: sales bigger than the average sale
-- Average sale = 57725 / 13 = 4440.38
-- Expected: 5 sales: 5600, 6400, 4825, 9600, 5150
-- ---------------------------------------------------------------------
SELECT sale_id, sale_date, total_amount
FROM   sale
WHERE  total_amount > (SELECT AVG(total_amount) FROM sale)
ORDER BY total_amount DESC;

-- ---------------------------------------------------------------------
-- Q16. FEFO HELPER: which batch should we sell first for Panadol?
-- (First Expiry, First Out: earliest expiry that is valid and in stock)
-- Expected: P001 (45 units, expires 2028-12-31) comes before P002
-- ---------------------------------------------------------------------
SELECT b.batch_no, b.expiry_date, b.quantity_remaining
FROM   medicine_batch b
JOIN   purchase_detail pd ON pd.purchase_detail_id = b.purchase_detail_id
JOIN   medicine m         ON m.medicine_id = pd.medicine_id
WHERE  m.medicine_name = 'Panadol'
  AND  b.expiry_date >= TRUNC(SYSDATE)
  AND  b.quantity_remaining > 0
ORDER BY b.expiry_date;
