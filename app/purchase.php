<?php
require 'config.php'; guard(['ADMIN', 'STOREKEEPER']);
$msg = $err = '';
if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    try {
        $items = [];
        foreach ($_POST['med'] ?? [] as $i => $m) {
            if ($m === '') continue;
            $items[] = [$m, trim($_POST['batch'][$i]), $_POST['qty'][$i], $_POST['price'][$i], $_POST['exp'][$i]];
        }
        if (!$items) throw new Exception('ORA-20000: Add at least one medicine line.');
        // whole purchase = one transaction: all lines are saved, or none
        $pid = call_out('BEGIN sp_create_purchase(:s, :u, :i, :pid); END;',
                        ['s' => $_POST['supplier_id'], 'u' => $_SESSION['uid'], 'i' => trim($_POST['invoice_no']) ?: null], 'pid');
        foreach ($items as $it) {
            ex("BEGIN sp_add_purchase_item(:p, :m, :b, :q, :pr, TO_DATE(:e, 'YYYY-MM-DD')); END;",
               ['p' => $pid, 'm' => $it[0], 'b' => $it[1], 'q' => $it[2], 'pr' => $it[3], 'e' => $it[4]], false);
        }
        oci_commit(db());
        $msg = 'Purchase saved (id ' . $pid . '). Stock has been increased.';
    } catch (Exception $e) {
        oci_rollback(db());
        $m = $e->getMessage();
        $err = 'Purchase NOT saved: ' . (strpos($m, 'ORA-00001') !== false ? 'this invoice number already exists for this supplier.' : clean_err($m));
    }
}
$sup = q('SELECT supplier_id, supplier_name FROM supplier ORDER BY supplier_name');
$med = q('SELECT medicine_id, medicine_name, strength FROM medicine WHERE is_active = 1 ORDER BY medicine_name');
page_header('Purchases');
notice($msg, $err);
?>
<form method="post" class="card" style="display:block">
  <div style="display:flex;gap:10px;flex-wrap:wrap;margin-bottom:10px">
    <label>Supplier *<select name="supplier_id" required>
      <?php foreach ($sup as $s) echo '<option value="' . $s['SUPPLIER_ID'] . '">' . h($s['SUPPLIER_NAME']) . '</option>'; ?></select></label>
    <label>Invoice no.<input name="invoice_no"></label>
  </div>
  <div id="rows"></div>
  <button type="button" onclick="addRow()">+ Add medicine line</button> <button>Save purchase</button>
</form>
<template id="row"><div style="display:flex;gap:8px;flex-wrap:wrap;margin-bottom:8px">
  <label>Medicine<select name="med[]"><option value="">-- choose --</option>
    <?php foreach ($med as $m) echo '<option value="' . $m['MEDICINE_ID'] . '">' . h($m['MEDICINE_NAME'] . ' ' . $m['STRENGTH']) . '</option>'; ?></select></label>
  <label>Batch no.<input name="batch[]"></label>
  <label>Quantity<input name="qty[]" type="number" min="1"></label>
  <label>Cost price<input name="price[]" type="number" step="0.01" min="0"></label>
  <label>Expiry date<input name="exp[]" type="date"></label></div></template>
<script>function addRow(){document.getElementById('rows').appendChild(document.getElementById('row').content.cloneNode(true));}addRow();</script>
<?php
echo '<h2>Recent purchases</h2>';
table(q("SELECT p.purchase_id, TO_CHAR(p.purchase_date,'YYYY-MM-DD') AS purchase_date, s.supplier_name, p.invoice_no, p.total_amount
         FROM purchase p JOIN supplier s ON s.supplier_id = p.supplier_id
         ORDER BY p.purchase_date DESC, p.purchase_id DESC FETCH FIRST 20 ROWS ONLY"));
page_footer();
