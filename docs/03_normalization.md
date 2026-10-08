# Phase 3: Normalization

Normalization = every fact stored in exactly one place, avoiding insert,
update and delete anomalies. "Every column depends on the key, the whole key,
and nothing but the key."

## Unnormalized
| purchase_id | purchase_date | supplier_name | supplier_phone | medicines |
|---|---|---|---|---|
| 1 | 2026-09-01 | Getz Pharma | 0300-1111111 | Panadol (100, Rs.80), Brufen (50, Rs.120) |

## 1NF: one value per cell, unique rows
One row per medicine per purchase; key = (purchase_id, medicine_name).

## 2NF: no partial dependency on a composite key
purchase_date, supplier_name, supplier_phone depend only on purchase_id.
Split into PURCHASE (header) and PURCHASE_DETAIL (lines).

## 3NF: no transitive dependency
supplier_phone depends on the supplier, not the purchase. Move supplier facts
into SUPPLIER and reference it with supplier_id. Same for medicine and category.

## Correction found during normalization
PURCHASE_DETAIL and MEDICINE_BATCH both stored quantity, price, batch number,
expiry date and medicine. Fixed so each fact has one home:
- PURCHASE_DETAIL: medicine, quantity received, purchase price
- MEDICINE_BATCH: batch number, expiry date, quantity remaining

## Deliberate exceptions (documented)
- total_amount in PURCHASE and SALE: derived, but kept on purpose (receipts are
  historical records; faster reports). Only one procedure will write it inside a transaction.
- unit_price in SALE_DETAIL: a price snapshot at time of sale, not duplicate data.
