<?php
require 'config.php'; guard();
page_header('Alerts');
$cols = 'medicine_name, batch_no, quantity_remaining, expiry_date, days_left';
echo '<h2>Low stock</h2>';
table(q("SELECT medicine_name, available_stock, reorder_level, stock_status FROM v_medicine_stock WHERE stock_status <> 'OK' ORDER BY medicine_name"), 'No low-stock medicines.');
echo '<h2>Expired (still in stock - remove from shelf)</h2>';
table(q("SELECT $cols FROM v_batch_stock WHERE quantity_remaining > 0 AND expiry_status = 'EXPIRED' ORDER BY expiry_date"), 'No expired batches.');
echo '<h2>Expiring within 30 days</h2>';
table(q("SELECT $cols FROM v_batch_stock WHERE quantity_remaining > 0 AND expiry_status = 'EXPIRES IN 30 DAYS' ORDER BY expiry_date"), 'None.');
echo '<h2>Expiring within 60 days</h2>';
table(q("SELECT $cols FROM v_batch_stock WHERE quantity_remaining > 0 AND expiry_status = 'EXPIRES IN 60 DAYS' ORDER BY expiry_date"), 'None.');
page_footer();
