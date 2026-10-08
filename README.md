# Medical Store Inventory Management System

University DBMS project. A medicine inventory system built with Oracle Database and a PHP web frontend.

## Features
- Medicines, categories, suppliers, customers
- Purchases and sales with multiple batches per medicine
- Expiry tracking (expired, within 30 days, within 60 days)
- Low stock alerts based on reorder level
- Login system and dashboard

## Technologies
- Oracle Database (SQL, views, functions, procedures, triggers)
- PHP with OCI8
- XAMPP (Apache)

## Folder structure
- `sql/` : database scripts (tables, sample data, queries, views, triggers)
- `app/` : PHP web application
- `docs/` : project report and documents

## How to run
1. Install Oracle Database and run the scripts in `sql/` in order (01 to 09).
2. Install XAMPP and enable the OCI8 extension in PHP.
3. Copy the `app` folder into `htdocs`.
4. Edit `app/config.php` and set your own database username, password and service name.
5. Start Apache and open `login.php` in the browser.
