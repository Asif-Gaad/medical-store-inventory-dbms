<?php
require 'config.php'; guard();
page_header('Inventory');
$view = $_GET['v'] ?? 'medicine';
echo '<div class="tabs"><a class="' . ($view === 'medicine' ? 'on' : '') . '" href="?v=medicine">By medicine</a><a class="' . ($view === 'batch' ? 'on' : '') . '" href="?v=batch">By batch</a></div>';
if ($view === 'batch') {
    table(q('SELECT medicine_name, batch_no, quantity_remaining, cost_price, selling_price, expiry_date, days_left, expiry_status
             FROM v_batch_stock ORDER BY medicine_name, expiry_date'));
} else {
    table(q('SELECT medicine_name, strength, category_name, available_stock, expired_stock, reorder_level, stock_status
             FROM v_medicine_stock ORDER BY medicine_name'));
}
page_footer();
