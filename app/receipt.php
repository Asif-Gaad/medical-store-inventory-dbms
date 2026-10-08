<?php
require 'config.php'; guard(['ADMIN', 'PHARMACIST']);
$id = $_GET['id'] ?? '';
page_header('Receipt #' . $id);
$lines = q("SELECT medicine_name, batch_no, quantity, unit_price, discount, line_total, customer_name, sold_by,
                   TO_CHAR(sale_date,'YYYY-MM-DD HH24:MI') AS sale_date
            FROM v_sale_lines WHERE sale_id = :id ORDER BY medicine_name", ['id' => $id]);
if (!$lines) { echo '<p class="muted">Sale not found.</p>'; page_footer(); exit; }
echo '<p>Date: ' . h($lines[0]['SALE_DATE']) . '<br>Customer: ' . h($lines[0]['CUSTOMER_NAME']) . '<br>Sold by: ' . h($lines[0]['SOLD_BY']) . '</p>';
$total = 0; $out = [];
foreach ($lines as $l) { $total += $l['LINE_TOTAL'];
    $out[] = ['Medicine' => $l['MEDICINE_NAME'], 'Batch' => $l['BATCH_NO'], 'Qty' => $l['QUANTITY'], 'Price' => $l['UNIT_PRICE'], 'Discount' => $l['DISCOUNT'], 'Total' => $l['LINE_TOTAL']]; }
table($out);
echo '<h2>Grand total: Rs. ' . h(number_format($total, 2)) . '</h2>';
echo '<p class="noprint"><button onclick="window.print()">Print</button> <a href="sales.php">New sale</a></p>';
page_footer();
