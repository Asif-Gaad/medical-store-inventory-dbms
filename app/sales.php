<?php
require 'config.php'; guard(['ADMIN', 'PHARMACIST']);
$err = '';
if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    try {
        $items = [];
        foreach ($_POST['med'] ?? [] as $i => $m) {
            if ($m === '') continue;
            $items[] = [$m, $_POST['qty'][$i], ($_POST['disc'][$i] ?? '') === '' ? 0 : $_POST['disc'][$i]];
        }
        if (!$items) throw new Exception('ORA-20000: Add at least one medicine.');
        // whole sale = one transaction. Stock is reduced (FEFO) by the database.
        $sid = call_out('BEGIN sp_create_sale(:c, :u, :sid); END;',
                        ['c' => ($_POST['customer_id'] ?? '') === '' ? null : $_POST['customer_id'], 'u' => $_SESSION['uid']], 'sid');
        foreach ($items as $it) {
            ex('BEGIN sp_add_sale_item(:s, :m, :q, :d); END;', ['s' => $sid, 'm' => $it[0], 'q' => $it[1], 'd' => $it[2]], false);
        }
        oci_commit(db());
        header('Location: receipt.php?id=' . urlencode($sid)); exit;
    } catch (Exception $e) {
        oci_rollback(db());
        $err = 'Sale NOT saved: ' . clean_err($e->getMessage());
    }
}
$cust = q('SELECT customer_id, customer_name FROM customer ORDER BY customer_name');
$med  = q('SELECT medicine_id, medicine_name, strength, selling_price, available_stock FROM v_medicine_stock
           WHERE available_stock > 0 ORDER BY medicine_name');
page_header('Sales (POS)');
notice('', $err);
?>
<form method="post" class="card" style="display:block">
  <label style="margin-bottom:10px;max-width:300px">Customer (leave empty for walk-in)
    <select name="customer_id"><option value="">Walk-in customer</option>
      <?php foreach ($cust as $c) echo '<option value="' . $c['CUSTOMER_ID'] . '">' . h($c['CUSTOMER_NAME']) . '</option>'; ?></select></label>
  <div id="rows"></div>
  <button type="button" onclick="addRow()">+ Add medicine</button> <button>Complete sale</button>
  <p class="muted">Each medicine can be added once. The system sells the batch that expires first.</p>
</form>
<template id="row"><div style="display:flex;gap:8px;flex-wrap:wrap;margin-bottom:8px">
  <label>Medicine<select name="med[]"><option value="">-- choose --</option>
    <?php foreach ($med as $m) echo '<option value="' . $m['MEDICINE_ID'] . '">' . h($m['MEDICINE_NAME'] . ' ' . $m['STRENGTH'] . ' - Rs.' . $m['SELLING_PRICE'] . ' (stock ' . $m['AVAILABLE_STOCK'] . ')') . '</option>'; ?></select></label>
  <label>Quantity<input name="qty[]" type="number" min="1" value="1"></label>
  <label>Discount (Rs.)<input name="disc[]" type="number" step="0.01" min="0" value="0"></label></div></template>
<script>function addRow(){document.getElementById('rows').appendChild(document.getElementById('row').content.cloneNode(true));}addRow();</script>
<?php
echo '<h2>Recent sales</h2>';
$rows = q("SELECT s.sale_id, TO_CHAR(s.sale_date,'YYYY-MM-DD HH24:MI') AS sale_date, NVL(c.customer_name,'Walk-in Customer') AS customer, s.total_amount
           FROM sale s LEFT JOIN customer c ON c.customer_id = s.customer_id
           ORDER BY s.sale_date DESC, s.sale_id DESC FETCH FIRST 15 ROWS ONLY");
echo '<div class="scroll"><table><tr><th>Sale</th><th>Date</th><th>Customer</th><th>Total</th><th></th></tr>';
foreach ($rows as $r) echo '<tr><td>' . h($r['SALE_ID']) . '</td><td>' . h($r['SALE_DATE']) . '</td><td>' . h($r['CUSTOMER']) . '</td><td>' . h($r['TOTAL_AMOUNT'])
                         . '</td><td><a href="receipt.php?id=' . h($r['SALE_ID']) . '">Receipt</a></td></tr>';
echo '</table></div>';
page_footer();
