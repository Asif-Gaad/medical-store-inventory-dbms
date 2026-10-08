-- =====================================================================
-- 05_tests.sql   (Phase 5 - verify the sample data)
-- =====================================================================

-- TEST 1: row counts. Expected: 6, 4, 12, 6, 4, 6, 16, 16, 13, 28
SELECT 'CATEGORY' AS tbl, COUNT(*) AS rows_count FROM category        UNION ALL
SELECT 'SUPPLIER',        COUNT(*) FROM supplier        UNION ALL
SELECT 'MEDICINE',        COUNT(*) FROM medicine        UNION ALL
SELECT 'CUSTOMER',        COUNT(*) FROM customer        UNION ALL
SELECT 'USERS',           COUNT(*) FROM users           UNION ALL
SELECT 'PURCHASE',        COUNT(*) FROM purchase        UNION ALL
SELECT 'PURCHASE_DETAIL', COUNT(*) FROM purchase_detail UNION ALL
SELECT 'MEDICINE_BATCH',  COUNT(*) FROM medicine_batch  UNION ALL
SELECT 'SALE',            COUNT(*) FROM sale            UNION ALL
SELECT 'SALE_DETAIL',     COUNT(*) FROM sale_detail;

-- TEST 2: stock consistency. Expected: NO ROWS
SELECT b.batch_no,
       pd.quantity - NVL(SUM(sd.quantity), 0) AS expected_remaining,
       b.quantity_remaining                    AS actual_remaining
FROM   medicine_batch b
JOIN   purchase_detail pd ON pd.purchase_detail_id = b.purchase_detail_id
LEFT JOIN sale_detail sd  ON sd.batch_id = b.batch_id
GROUP BY b.batch_no, pd.quantity, b.quantity_remaining
HAVING pd.quantity - NVL(SUM(sd.quantity), 0) <> b.quantity_remaining;

-- TEST 3a: sale totals match their lines. Expected: NO ROWS
SELECT s.sale_id, s.total_amount,
       SUM(sd.quantity * sd.unit_price - sd.discount) AS calculated
FROM   sale s JOIN sale_detail sd ON sd.sale_id = s.sale_id
GROUP BY s.sale_id, s.total_amount
HAVING s.total_amount <> SUM(sd.quantity * sd.unit_price - sd.discount);

-- TEST 3b: purchase totals match their lines. Expected: NO ROWS
SELECT p.purchase_id, p.total_amount,
       SUM(pd.quantity * pd.purchase_price) AS calculated
FROM   purchase p JOIN purchase_detail pd ON pd.purchase_id = p.purchase_id
GROUP BY p.purchase_id, p.total_amount
HAVING p.total_amount <> SUM(pd.quantity * pd.purchase_price);

-- TEST 4: low-stock preview.
-- Expected LOW STOCK: Calpol (8 vs 10), Surbex-Z (7 vs 8), Risek (10 vs 12)
SELECT m.medicine_name,
       SUM(b.quantity_remaining) AS total_stock,
       m.reorder_level,
       CASE WHEN SUM(b.quantity_remaining) < m.reorder_level
            THEN 'LOW STOCK' ELSE 'OK' END AS status
FROM   medicine m
JOIN   purchase_detail pd ON pd.medicine_id = m.medicine_id
JOIN   medicine_batch b   ON b.purchase_detail_id = pd.purchase_detail_id
GROUP BY m.medicine_name, m.reorder_level
ORDER BY m.medicine_name;
