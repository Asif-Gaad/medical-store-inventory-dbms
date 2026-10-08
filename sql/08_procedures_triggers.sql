-- =====================================================================
-- 08_procedures_triggers.sql   (Phase 7, part 2)
-- 2 triggers + 5 procedures. Safe to run again (CREATE OR REPLACE).
-- IMPORTANT: run 04_sample_data.sql BEFORE this file on a fresh database,
-- because trigger trg_batch_expiry_check rejects expired batches (the
-- sample data contains one expired batch on purpose).
-- Procedures do NOT commit. The caller decides COMMIT or ROLLBACK, so a
-- whole purchase or sale is saved all together or not at all.
-- =====================================================================

-- ---------------------------------------------------------------------
-- TRIGGER 1: refuse to receive a batch that is already expired
-- Why: a CHECK constraint cannot use SYSDATE, so a trigger is the right tool.
-- ---------------------------------------------------------------------
CREATE OR REPLACE TRIGGER trg_batch_expiry_check
BEFORE INSERT ON medicine_batch
FOR EACH ROW
BEGIN
    IF :NEW.expiry_date < TRUNC(SYSDATE) THEN
        RAISE_APPLICATION_ERROR(-20010,
            'Cannot receive batch ' || :NEW.batch_no || ': it is already expired.');
    END IF;
END;
/

-- ---------------------------------------------------------------------
-- TRIGGER 2: keep stock correct whenever a sale line changes
--   INSERT : block expired batch, block overselling, then reduce stock
--   DELETE : give the quantity back to the batch
--   UPDATE of quantity/batch : not allowed (delete the line and add again)
-- Why: it protects stock even if someone inserts into SALE_DETAIL directly
-- (SQL Developer, a buggy frontend, ...). FOR UPDATE locks the batch row
-- so two cashiers cannot sell the same last units at the same time.
-- ---------------------------------------------------------------------
CREATE OR REPLACE TRIGGER trg_sale_detail_stock
BEFORE INSERT OR UPDATE OF quantity, batch_id OR DELETE ON sale_detail
FOR EACH ROW
DECLARE
    v_remaining medicine_batch.quantity_remaining%TYPE;
    v_expiry    medicine_batch.expiry_date%TYPE;
BEGIN
    IF INSERTING THEN
        SELECT quantity_remaining, expiry_date
        INTO   v_remaining, v_expiry
        FROM   medicine_batch
        WHERE  batch_id = :NEW.batch_id
        FOR UPDATE;

        IF v_expiry < TRUNC(SYSDATE) THEN
            RAISE_APPLICATION_ERROR(-20011, 'This batch is expired and cannot be sold.');
        END IF;
        IF :NEW.quantity > v_remaining THEN
            RAISE_APPLICATION_ERROR(-20012,
                'Not enough stock in this batch. Available: ' || v_remaining);
        END IF;

        UPDATE medicine_batch
        SET    quantity_remaining = quantity_remaining - :NEW.quantity
        WHERE  batch_id = :NEW.batch_id;

    ELSIF DELETING THEN
        UPDATE medicine_batch
        SET    quantity_remaining = quantity_remaining + :OLD.quantity
        WHERE  batch_id = :OLD.batch_id;

    ELSE
        RAISE_APPLICATION_ERROR(-20013,
            'Sale lines cannot be edited. Delete the line and add it again.');
    END IF;
END;
/

-- ---------------------------------------------------------------------
-- PROCEDURE 1: start a purchase (header only)
-- ---------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE sp_create_purchase (
    p_supplier_id IN  purchase.supplier_id%TYPE,
    p_user_id     IN  purchase.user_id%TYPE,
    p_invoice_no  IN  purchase.invoice_no%TYPE,
    p_purchase_id OUT purchase.purchase_id%TYPE
)
IS
BEGIN
    INSERT INTO purchase (supplier_id, user_id, invoice_no)
    VALUES (p_supplier_id, p_user_id, p_invoice_no)
    RETURNING purchase_id INTO p_purchase_id;
END sp_create_purchase;
/

-- ---------------------------------------------------------------------
-- PROCEDURE 2: add one medicine line to a purchase
-- Creates the purchase line AND its batch (stock increases) and updates
-- the purchase total. This is the only place that writes purchase total.
-- ---------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE sp_add_purchase_item (
    p_purchase_id    IN purchase.purchase_id%TYPE,
    p_medicine_id    IN medicine.medicine_id%TYPE,
    p_batch_no       IN medicine_batch.batch_no%TYPE,
    p_quantity       IN NUMBER,
    p_purchase_price IN NUMBER,
    p_expiry_date    IN DATE
)
IS
    v_detail_id purchase_detail.purchase_detail_id%TYPE;
BEGIN
    INSERT INTO purchase_detail (purchase_id, medicine_id, quantity, purchase_price)
    VALUES (p_purchase_id, p_medicine_id, p_quantity, p_purchase_price)
    RETURNING purchase_detail_id INTO v_detail_id;

    INSERT INTO medicine_batch (purchase_detail_id, batch_no, expiry_date, quantity_remaining)
    VALUES (v_detail_id, p_batch_no, p_expiry_date, p_quantity);

    UPDATE purchase
    SET    total_amount = total_amount + (p_quantity * p_purchase_price)
    WHERE  purchase_id = p_purchase_id;
END sp_add_purchase_item;
/

-- ---------------------------------------------------------------------
-- PROCEDURE 3: start a sale (header only). Customer NULL = walk-in.
-- ---------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE sp_create_sale (
    p_customer_id IN  sale.customer_id%TYPE,
    p_user_id     IN  sale.user_id%TYPE,
    p_sale_id     OUT sale.sale_id%TYPE
)
IS
BEGIN
    INSERT INTO sale (customer_id, user_id)
    VALUES (p_customer_id, p_user_id)
    RETURNING sale_id INTO p_sale_id;
END sp_create_sale;
/

-- ---------------------------------------------------------------------
-- PROCEDURE 4: add one medicine to a sale  (FEFO)
--   * checks quantity, discount, medicine, enough sellable stock
--   * sells from the batch that expires FIRST; if that batch is not
--     enough, continues with the next batch (one sale line per batch)
--   * the discount is shared between batch lines in proportion
--   * stock is reduced by trigger trg_sale_detail_stock
--   * updates the sale total
-- ---------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE sp_add_sale_item (
    p_sale_id     IN sale.sale_id%TYPE,
    p_medicine_id IN medicine.medicine_id%TYPE,
    p_quantity    IN NUMBER,
    p_discount    IN NUMBER DEFAULT 0
)
IS
    v_price      medicine.selling_price%TYPE;
    v_available  NUMBER;
    v_already    NUMBER;
    v_left       NUMBER := p_quantity;
    v_take       NUMBER;
    v_disc_left  NUMBER := p_discount;
    v_line_disc  NUMBER;
    v_sale_total NUMBER := 0;

    CURSOR c_batches IS
        SELECT   b.batch_id, b.quantity_remaining
        FROM     medicine_batch b
        JOIN     purchase_detail pd ON pd.purchase_detail_id = b.purchase_detail_id
        WHERE    pd.medicine_id = p_medicine_id
        AND      b.expiry_date >= TRUNC(SYSDATE)
        AND      b.quantity_remaining > 0
        ORDER BY b.expiry_date, b.batch_id;
BEGIN
    IF p_quantity IS NULL OR p_quantity <= 0 THEN
        RAISE_APPLICATION_ERROR(-20001, 'Quantity must be greater than zero.');
    END IF;
    IF p_discount IS NULL OR p_discount < 0 THEN
        RAISE_APPLICATION_ERROR(-20005, 'Discount cannot be negative.');
    END IF;

    BEGIN
        SELECT selling_price INTO v_price
        FROM   medicine
        WHERE  medicine_id = p_medicine_id AND is_active = 1;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE_APPLICATION_ERROR(-20002, 'Medicine not found or not active.');
    END;

    IF p_discount > p_quantity * v_price THEN
        RAISE_APPLICATION_ERROR(-20003, 'Discount cannot be more than the line amount.');
    END IF;

    SELECT COUNT(*) INTO v_already
    FROM   sale_detail sd
    JOIN   medicine_batch b   ON b.batch_id = sd.batch_id
    JOIN   purchase_detail pd ON pd.purchase_detail_id = b.purchase_detail_id
    WHERE  sd.sale_id = p_sale_id AND pd.medicine_id = p_medicine_id;

    IF v_already > 0 THEN
        RAISE_APPLICATION_ERROR(-20004, 'This medicine is already on the sale. Add it only once.');
    END IF;

    v_available := fn_available_stock(p_medicine_id);
    IF v_available < p_quantity THEN
        RAISE_APPLICATION_ERROR(-20006,
            'Not enough stock. Requested ' || p_quantity || ', available ' || v_available || '.');
    END IF;

    FOR r IN c_batches LOOP
        EXIT WHEN v_left = 0;

        v_take := LEAST(v_left, r.quantity_remaining);

        IF v_take = v_left THEN
            v_line_disc := v_disc_left;                       -- last line gets the rest
        ELSE
            v_line_disc := ROUND(p_discount * v_take / p_quantity, 2);
        END IF;

        INSERT INTO sale_detail (sale_id, batch_id, quantity, unit_price, discount)
        VALUES (p_sale_id, r.batch_id, v_take, v_price, v_line_disc);

        v_disc_left  := v_disc_left - v_line_disc;
        v_sale_total := v_sale_total + (v_take * v_price - v_line_disc);
        v_left       := v_left - v_take;
    END LOOP;

    IF v_left > 0 THEN
        RAISE_APPLICATION_ERROR(-20008, 'Stock changed while selling. Please try again.');
    END IF;

    UPDATE sale
    SET    total_amount = total_amount + v_sale_total
    WHERE  sale_id = p_sale_id;
END sp_add_sale_item;
/

-- ---------------------------------------------------------------------
-- PROCEDURE 5: cancel a whole sale (stock is given back by the trigger)
-- ---------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE sp_cancel_sale (p_sale_id IN sale.sale_id%TYPE)
IS
BEGIN
    DELETE FROM sale_detail WHERE sale_id = p_sale_id;
    DELETE FROM sale        WHERE sale_id = p_sale_id;

    IF SQL%ROWCOUNT = 0 THEN
        RAISE_APPLICATION_ERROR(-20007, 'Sale not found.');
    END IF;
END sp_cancel_sale;
/
