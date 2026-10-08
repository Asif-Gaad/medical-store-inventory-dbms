<?php
require 'config.php'; guard();

// helper: rows -> ['labels'=>[...], 'values'=>[...]]
function chart_data($rows, $v = 'V') {
    $o = ['labels' => [], 'values' => []];
    foreach ($rows as $r) { $o['labels'][] = $r['LBL'] ?? ''; $o['values'][] = (float)($r[$v] ?? 0); }
    return $o;
}

$d = q('SELECT * FROM v_dashboard')[0];

$sales30 = chart_data(q("SELECT TO_CHAR(d.day, 'DD Mon', 'NLS_DATE_LANGUAGE=ENGLISH') AS LBL, NVL(s.total_sales, 0) AS V
    FROM (SELECT TRUNC(SYSDATE) - LEVEL + 1 AS day FROM dual CONNECT BY LEVEL <= 30) d
    LEFT JOIN v_daily_sales s ON s.sale_day = d.day ORDER BY d.day"));

$months = q("SELECT TO_CHAR(m.mon, 'Mon YYYY', 'NLS_DATE_LANGUAGE=ENGLISH') AS LBL,
        NVL((SELECT SUM(total_amount) FROM sale WHERE sale_date >= m.mon AND sale_date < ADD_MONTHS(m.mon, 1)), 0) AS S,
        NVL((SELECT SUM(total_amount) FROM purchase WHERE purchase_date >= m.mon AND purchase_date < ADD_MONTHS(m.mon, 1)), 0) AS P
    FROM (SELECT ADD_MONTHS(TRUNC(SYSDATE, 'MM'), -LEVEL + 1) AS mon FROM dual CONNECT BY LEVEL <= 6) m ORDER BY m.mon");
$monthSales = chart_data($months, 'S'); $monthBuys = chart_data($months, 'P');

$top = chart_data(q("SELECT medicine_name AS LBL, SUM(quantity) AS V FROM v_sale_lines
    GROUP BY medicine_name ORDER BY V DESC, medicine_name FETCH FIRST 5 ROWS ONLY"));
$stock  = chart_data(q("SELECT stock_status AS LBL, COUNT(*) AS V FROM v_medicine_stock GROUP BY stock_status"));
$expiry = chart_data(q("SELECT expiry_status AS LBL, COUNT(*) AS V FROM v_batch_stock WHERE quantity_remaining > 0 GROUP BY expiry_status"));

$payload = ['sales' => $sales30, 'ms' => $monthSales, 'mp' => $monthBuys, 'top' => $top, 'stock' => $stock, 'expiry' => $expiry];

page_header('Dashboard');
$cards = [['💊', 'Total Medicines', $d['TOTAL_MEDICINES'], 'green'], ['📉', 'Low Stock', $d['LOW_STOCK'], 'orange'],
          ['⏳', 'Near Expiry (60 days)', $d['NEAR_EXPIRY'], 'orange'], ['⛔', 'Expired (in stock)', $d['EXPIRED'], 'red'],
          ['💰', "Today's Sales", 'Rs. ' . number_format($d['TODAYS_SALES']), 'blue'],
          ['🛒', "Today's Purchases", 'Rs. ' . number_format($d['TODAYS_PURCHASES']), 'blue']];
echo '<div class="grid">';
foreach ($cards as [$ic, $t, $v, $c]) echo '<div class="stat ' . $c . '"><span class="ic">' . $ic . '</span>' . h($t) . '<b>' . h($v) . '</b></div>';
echo '</div>';
?>
<div class="charts">
  <div class="chart-card wide"><h3>Sales: last 30 days (Rs.)</h3><div class="chart-box"><canvas id="c1"></canvas></div></div>
  <div class="chart-card"><h3>Stock status (medicines)</h3><div class="chart-box"><canvas id="c2"></canvas></div></div>
  <div class="chart-card"><h3>Batch expiry status</h3><div class="chart-box"><canvas id="c3"></canvas></div></div>
  <div class="chart-card"><h3>Top 5 best sellers (units)</h3><div class="chart-box"><canvas id="c4"></canvas></div></div>
  <div class="chart-card"><h3>Sales vs purchases (6 months, Rs.)</h3><div class="chart-box"><canvas id="c5"></canvas></div></div>
</div>
<script src="https://cdn.jsdelivr.net/npm/chart.js@4.4.1/dist/chart.umd.min.js"></script>
<script>
const C = <?= json_encode($payload) ?>;
if (typeof Chart === 'undefined') {
  document.querySelector('.charts').innerHTML = '<p class="muted">Charts need an internet connection (Chart.js could not be loaded).</p>';
} else {
  const col = {'OK':'#0b6e4f','VALID':'#0b6e4f','LOW STOCK':'#f59e0b','OUT OF STOCK':'#dc2626','EXPIRED':'#dc2626',
               'EXPIRES IN 30 DAYS':'#f97316','EXPIRES IN 60 DAYS':'#facc15'};
  const base = {responsive: true, maintainAspectRatio: false};
  const money = v => 'Rs. ' + Number(v).toLocaleString();
  new Chart(c1, {type: 'line', data: {labels: C.sales.labels, datasets: [{label: 'Sales', data: C.sales.values,
    borderColor: '#0b6e4f', backgroundColor: 'rgba(11,110,79,.15)', fill: true, tension: .3, pointRadius: 2}]},
    options: {...base, plugins: {legend: {display: false}}, scales: {y: {beginAtZero: true, ticks: {callback: money}}, x: {ticks: {maxTicksLimit: 10}}}}});
  const donut = (el, d) => new Chart(el, {type: 'doughnut', data: {labels: d.labels, datasets: [{data: d.values,
    backgroundColor: d.labels.map(l => col[l] || '#64748b')}]}, options: {...base, cutout: '60%', plugins: {legend: {position: 'bottom'}}}});
  donut(c2, C.stock); donut(c3, C.expiry);
  new Chart(c4, {type: 'bar', data: {labels: C.top.labels, datasets: [{label: 'Units sold', data: C.top.values, backgroundColor: '#0b6e4f', borderRadius: 6}]},
    options: {...base, indexAxis: 'y', plugins: {legend: {display: false}}, scales: {x: {beginAtZero: true}}}});
  new Chart(c5, {type: 'bar', data: {labels: C.ms.labels, datasets: [
      {label: 'Sales', data: C.ms.values, backgroundColor: '#0b6e4f', borderRadius: 4},
      {label: 'Purchases', data: C.mp.values, backgroundColor: '#f59e0b', borderRadius: 4}]},
    options: {...base, plugins: {legend: {position: 'bottom'}}, scales: {y: {beginAtZero: true, ticks: {callback: money}}}}});
}
</script>
<?php
echo '<h2>Low stock medicines</h2>';
table(q("SELECT medicine_name, available_stock, reorder_level, stock_status FROM v_medicine_stock
         WHERE stock_status <> 'OK' ORDER BY medicine_name"), 'Nothing is low on stock.');
echo '<h2>Batches that need attention (expired or expiring within 60 days)</h2>';
table(q("SELECT medicine_name, batch_no, quantity_remaining, expiry_date, days_left, expiry_status FROM v_batch_stock
         WHERE quantity_remaining > 0 AND expiry_status <> 'VALID' ORDER BY expiry_date"), 'No expiry problems.');
page_footer();
