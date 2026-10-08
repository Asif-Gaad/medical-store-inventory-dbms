<?php
require 'config.php'; guard(['ADMIN']);
$reports = [
 'totals'   => ['Total sales, purchases and profit', "SELECT (SELECT SUM(total_amount) FROM sale) AS total_sales, (SELECT SUM(total_amount) FROM purchase) AS total_purchases,
                 (SELECT SUM(profit) FROM v_sale_lines) AS estimated_profit FROM dual"],
 'daily'    => ['Daily sales', "SELECT TO_CHAR(sale_day,'YYYY-MM-DD') AS sale_day, number_of_sales, total_sales FROM v_daily_sales ORDER BY sale_day DESC"],
 'monthly'  => ['Monthly sales', 'SELECT sale_month, number_of_sales, total_sales FROM v_monthly_sales ORDER BY sale_month DESC'],
 'best'     => ['Best-selling medicines', 'SELECT medicine_name, SUM(quantity) AS units_sold, SUM(line_total) AS revenue FROM v_sale_lines GROUP BY medicine_name ORDER BY units_sold DESC, medicine_name FETCH FIRST 10 ROWS ONLY'],
 'profit'   => ['Profit per medicine', 'SELECT medicine_name, SUM(line_total) AS revenue, SUM(profit) AS profit FROM v_sale_lines GROUP BY medicine_name ORDER BY profit DESC'],
 'suppliers'=> ['Supplier purchase totals', 'SELECT s.supplier_name, COUNT(p.purchase_id) AS purchases, NVL(SUM(p.total_amount),0) AS total_purchased FROM supplier s LEFT JOIN purchase p ON p.supplier_id = s.supplier_id GROUP BY s.supplier_name ORDER BY total_purchased DESC'],
 'purchases'=> ['Purchase history', "SELECT TO_CHAR(p.purchase_date,'YYYY-MM-DD') AS purchase_date, p.invoice_no, s.supplier_name, m.medicine_name, pd.quantity, pd.purchase_price, pd.quantity * pd.purchase_price AS line_total
                 FROM purchase p JOIN supplier s ON s.supplier_id = p.supplier_id JOIN purchase_detail pd ON pd.purchase_id = p.purchase_id JOIN medicine m ON m.medicine_id = pd.medicine_id
                 ORDER BY p.purchase_date DESC, p.invoice_no FETCH FIRST 200 ROWS ONLY"],
 'customers'=> ['Customer purchases', "SELECT NVL(c.customer_name,'Walk-in Customer') AS customer, COUNT(s.sale_id) AS sales, SUM(s.total_amount) AS total_spent FROM sale s LEFT JOIN customer c ON c.customer_id = s.customer_id GROUP BY NVL(c.customer_name,'Walk-in Customer') ORDER BY total_spent DESC"],
];
$k = isset($reports[$_GET['r'] ?? '']) ? $_GET['r'] : 'totals';
page_header('Reports');
echo '<div class="tabs">';
foreach ($reports as $key => [$title, $sql]) echo '<a class="' . ($key === $k ? 'on' : '') . '" href="?r=' . $key . '">' . h($title) . '</a>';
echo '</div><h2>' . h($reports[$k][0]) . '</h2>';
table(q($reports[$k][1]));
page_footer();
