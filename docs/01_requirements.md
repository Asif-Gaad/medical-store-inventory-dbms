# Phase 1: Requirements Analysis

## Purpose
Replace paper/Excel stock keeping in a medical store with a database that records
purchases and sales, tracks stock per batch with expiry dates, warns about low or
expiring stock, and produces business reports.

Stock is tracked **per batch** because the same medicine bought at different
times has different expiry dates and prices. Sales should use the earliest-expiring
batch first (FEFO: First Expiry, First Out).

## Users
| User | Responsibilities |
|---|---|
| Admin (Owner/Manager) | Full control, users, all reports and profit |
| Pharmacist / Salesperson | Sales (POS), search medicines, check stock and expiry |
| Store Keeper | Record purchases and batches, check low stock and expiry |

## Functional requirements
- FR-1 User management: roles, login, password hashes, audit of who created records
- FR-2 Categories and medicines: add/update/search, reorder level
- FR-3 Supplier management and supplier purchase history
- FR-4 Purchases: header + lines; each line creates a batch (batch no., expiry, quantity, price); stock increases
- FR-5 Customer management, including walk-in customers
- FR-6 Sales (POS): multiple items, batch, quantity, price, discount, total, date, user; stock decreases; block insufficient stock or expired batch
- FR-7 Inventory: stock per medicine and per batch
- FR-8 Expiry classes: Expired, within 30 days, within 60 days, Valid
- FR-9 Low stock: total stock below reorder level shows LOW STOCK
- FR-10 Reports: current inventory, low stock, expired, near-expiry, daily/monthly sales, purchase history, supplier history, best sellers, totals, profit estimate
- FR-11 Dashboard: totals of medicines, low stock, near expiry, expired, today's sales and purchases

## Non-functional requirements
Data integrity, accuracy (transactions), security (roles, hashed passwords),
performance (indexes), reliability (rollback on failure), maintainability
(3NF, naming), usability, scalability, auditability.

## Modules
1. User and Authentication  2. Medicine Catalog  3. Supplier and Purchase
4. Inventory (batches)  5. Customer and Sales  6. Reports and Alerts

## Data flow
```
BUYING:  Supplier -> Purchase -> Purchase Details -> Medicine Batch -> Stock up
SELLING: Customer -> Sale -> Sale Details -> Medicine Batch -> Stock down
```
