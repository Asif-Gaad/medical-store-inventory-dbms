-- =====================================================================
-- 09_phase7_tests.sql   (Phase 7 tests)
-- Run with F5 (Run Script), ONCE, on the baseline data
-- (04_sample_data.sql loaded, 07 and 08 created).
-- These tests ADD data (a purchase and some sales). Running them twice
-- gives different numbers. To go back to the baseline:
--    run 01, 02, 03, 04, 07, 08 again (in this order).
-- Read the "EXPECTED" comments and compare with Script Output.
-- =====================================================================
SET SERVEROUTPUT ON;

PROMPT ===== TEST 0: all Phase 7 objects must be VALID (15 rows) =====
SELECT object_type, object_name, status
FROM   user_objects
WHERE  object_type IN ('VIEW', 'FUNCTION', 'PROCEDURE', 'TRIGGER')
ORDER BY object_type, object_name;
-- EXPECTED: 6 VIEW, 2 FUNCTION, 5 PROCEDURE, 2 TRIGGER, all VALID

PROMPT ===== TEST 1: views (baseline data) =====
SELECT * FROM v_dashboard;
-- EXPECTED: total_medicines 12, low_stock 3, near_expiry 3, expired 1,
--           todays_purchases 0, and todays_sales:
--             5040 if you loaded 04_sample_data.sql TODAY,
--             0    if you loaded it on an earlier day (the two "today" sales
--                  belong to the day you loaded the data)

SELECT medicine_name, total_stock, available_stock, expired_stock,
       reorder_level, stock_status
FROM   v_medicine_stock
ORDER BY medicine_name;
-- EXPECTED: Flagyl total 60, available 40, expired 20 (OK)
--           LOW STOCK: Calpol, Risek, Surbex-Z

SELECT medicine_name, batch_no, days_left, expiry_status
FROM   v_batch_stock
WHERE  expiry_status <> 'VALID'
ORDER BY days_left;
-- EXPECTED: F301 EXPIRED, R801 30 DAYS, B101 30 DAYS, BN401 60 DAYS

PROMPT ===== TEST 2: functions =====
SELECT fn_available_stock(5) AS flagyl_available_stock FROM dual;
-- EXPECTED: 40

SELECT fn_expiry_status(TRUNC(SYSDATE) - 1)   AS yesterday,
       fn_expiry_status(TRUNC(SYSDATE) + 10)  AS in_10_days,
       fn_expiry_status(TRUNC(SYSDATE) + 45)  AS in_45_days,
       fn_expiry_status(TRUNC(SYSDATE) + 100) AS in_100_days
FROM dual;
-- EXPECTED: EXPIRED, EXPIRES IN 30 DAYS, EXPIRES IN 60 DAYS, VALID

PROMPT ===== TEST 3: purchase 30 x Calpol (batch C502), then COMMIT =====
DECLARE
    v_purchase_id NUMBER;
BEGIN
    sp_create_purchase(1, 4, 'AS-2001', v_purchase_id);
    sp_add_purchase_item(v_purchase_id, 3, 'C502', 30, 140, TRUNC(SYSDATE) + 365);
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('Purchase created, id = ' || v_purchase_id);
END;
/
SELECT fn_available_stock(3) AS calpol_stock FROM dual;
-- EXPECTED: 38   (it was 8, +30). Calpol is no longer LOW STOCK.
SELECT invoice_no, total_amount FROM purchase WHERE invoice_no = 'AS-2001';
-- EXPECTED: AS-2001, 4200

PROMPT ===== TEST 4: sell 5 x Panadol (FEFO), then COMMIT =====
DECLARE
    v_sale_id NUMBER;
BEGIN
    sp_create_sale(1, 2, v_sale_id);
    sp_add_sale_item(v_sale_id, 1, 5);
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('Sale created, id = ' || v_sale_id);
END;
/
SELECT batch_no, quantity_remaining FROM medicine_batch
WHERE  batch_no IN ('P001', 'P002') ORDER BY batch_no;
-- EXPECTED: P001 = 40 (was 45, earliest expiry sold first), P002 = 35
SELECT sale_id, medicine_name, batch_no, quantity, unit_price, line_total
FROM   v_sale_lines
WHERE  sale_id = (SELECT MAX(sale_id) FROM sale);
-- EXPECTED: 1 line: Panadol, P001, 5, 100, 500

PROMPT ===== TEST 5: sell 25 x Brufen with discount 75 (needs 2 batches) =====
DECLARE
    v_sale_id NUMBER;
BEGIN
    sp_create_sale(NULL, 3, v_sale_id);
    sp_add_sale_item(v_sale_id, 2, 25, 75);
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('Sale created, id = ' || v_sale_id);
END;
/
SELECT batch_no, quantity_remaining FROM medicine_batch
WHERE  batch_no IN ('B101', 'B102') ORDER BY batch_no;
-- EXPECTED: B101 = 0 (all 20 taken), B102 = 29 (5 taken)
SELECT sale_id, batch_no, quantity, discount, line_total
FROM   v_sale_lines
WHERE  sale_id = (SELECT MAX(sale_id) FROM sale)
ORDER BY batch_no;
-- EXPECTED: B101 20 units discount 60 total 2940; B102 5 units discount 15 total 735
SELECT total_amount FROM sale WHERE sale_id = (SELECT MAX(sale_id) FROM sale);
-- EXPECTED: 3675

PROMPT ===== TEST 6: try to sell 500 x Panadol (must FAIL and rollback) =====
DECLARE
    v_sale_id NUMBER;
BEGIN
    sp_create_sale(NULL, 2, v_sale_id);
    sp_add_sale_item(v_sale_id, 1, 500);
    COMMIT;
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('ERROR (expected): ' || SQLERRM);
END;
/
-- EXPECTED message: ORA-20006: Not enough stock. Requested 500, available 75.

PROMPT ===== TEST 7: sell from the EXPIRED batch F301 directly (trigger must stop it) =====
DECLARE
    v_sale_id NUMBER;
    v_batch   NUMBER;
BEGIN
    SELECT batch_id INTO v_batch FROM medicine_batch WHERE batch_no = 'F301';
    sp_create_sale(NULL, 2, v_sale_id);
    INSERT INTO sale_detail (sale_id, batch_id, quantity, unit_price, discount)
    VALUES (v_sale_id, v_batch, 1, 130, 0);
    COMMIT;
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('ERROR (expected): ' || SQLERRM);
END;
/
-- EXPECTED message: ORA-20011: This batch is expired and cannot be sold.

PROMPT ===== TEST 8: purchase an already expired batch (trigger must stop it) =====
DECLARE
    v_purchase_id NUMBER;
BEGIN
    sp_create_purchase(1, 4, 'AS-2002', v_purchase_id);
    sp_add_purchase_item(v_purchase_id, 1, 'X001', 10, 80, TRUNC(SYSDATE) - 1);
    COMMIT;
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('ERROR (expected): ' || SQLERRM);
END;
/
-- EXPECTED message: ORA-20010: Cannot receive batch X001: it is already expired.

PROMPT ===== TEST 9: ROLLBACK demo (sale is made, checked, then undone) =====
DECLARE
    v_sale_id NUMBER;
    v_qty     NUMBER;
BEGIN
    SELECT quantity_remaining INTO v_qty FROM medicine_batch WHERE batch_no = 'A201';
    DBMS_OUTPUT.PUT_LINE('A201 stock before sale  : ' || v_qty);

    sp_create_sale(2, 3, v_sale_id);
    sp_add_sale_item(v_sale_id, 4, 3);

    SELECT quantity_remaining INTO v_qty FROM medicine_batch WHERE batch_no = 'A201';
    DBMS_OUTPUT.PUT_LINE('A201 stock after sale   : ' || v_qty);

    ROLLBACK;

    SELECT quantity_remaining INTO v_qty FROM medicine_batch WHERE batch_no = 'A201';
    DBMS_OUTPUT.PUT_LINE('A201 stock after ROLLBACK: ' || v_qty);
END;
/
-- EXPECTED: 15, then 12, then 15

PROMPT ===== TEST 10: cancel a sale (stock must come back) =====
DECLARE
    v_sale_id NUMBER;
    v_qty     NUMBER;
BEGIN
    SELECT quantity_remaining INTO v_qty FROM medicine_batch WHERE batch_no = 'D1101';
    DBMS_OUTPUT.PUT_LINE('D1101 stock before sale  : ' || v_qty);

    sp_create_sale(NULL, 2, v_sale_id);
    sp_add_sale_item(v_sale_id, 12, 4);
    SELECT quantity_remaining INTO v_qty FROM medicine_batch WHERE batch_no = 'D1101';
    DBMS_OUTPUT.PUT_LINE('D1101 stock after sale   : ' || v_qty);

    sp_cancel_sale(v_sale_id);
    SELECT quantity_remaining INTO v_qty FROM medicine_batch WHERE batch_no = 'D1101';
    DBMS_OUTPUT.PUT_LINE('D1101 stock after cancel : ' || v_qty);

    COMMIT;
END;
/
-- EXPECTED: 50, then 46, then 50

PROMPT ===== TEST 11: integrity checks (all must return NO ROWS) =====
SELECT b.batch_no,
       pd.quantity - NVL(SUM(sd.quantity), 0) AS expected_remaining,
       b.quantity_remaining                    AS actual_remaining
FROM   medicine_batch b
JOIN   purchase_detail pd ON pd.purchase_detail_id = b.purchase_detail_id
LEFT JOIN sale_detail sd  ON sd.batch_id = b.batch_id
GROUP BY b.batch_no, pd.quantity, b.quantity_remaining
HAVING pd.quantity - NVL(SUM(sd.quantity), 0) <> b.quantity_remaining;

SELECT s.sale_id, s.total_amount,
       SUM(sd.quantity * sd.unit_price - sd.discount) AS calculated
FROM   sale s JOIN sale_detail sd ON sd.sale_id = s.sale_id
GROUP BY s.sale_id, s.total_amount
HAVING s.total_amount <> SUM(sd.quantity * sd.unit_price - sd.discount);

SELECT p.purchase_id, p.total_amount,
       SUM(pd.quantity * pd.purchase_price) AS calculated
FROM   purchase p JOIN purchase_detail pd ON pd.purchase_id = p.purchase_id
GROUP BY p.purchase_id, p.total_amount
HAVING p.total_amount <> SUM(pd.quantity * pd.purchase_price);

PROMPT ===== TEST 12: dashboard after all tests =====
SELECT * FROM v_dashboard;
-- EXPECTED: total_medicines 12, low_stock 2 (Risek, Surbex-Z), near_expiry 2
--           (R801, BN401), expired 1, todays_purchases 4200, and todays_sales:
--             9215 if the sample data was loaded today (5040 + 500 + 3675),
--             4175 if it was loaded on an earlier day (500 + 3675)
