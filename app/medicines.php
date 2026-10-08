<?php
require 'config.php'; guard();
$canEdit = in_array($_SESSION['role'], ['ADMIN', 'STOREKEEPER'], true);
$msg = $err = '';
if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    try {
        guard(['ADMIN', 'STOREKEEPER']);
        if (isset($_POST['toggle'])) {
            ex('UPDATE medicine SET is_active = 1 - is_active WHERE medicine_id = :id', ['id' => $_POST['toggle']]);
            $msg = 'Status changed.';
        } else {
            $b = ['n' => trim($_POST['medicine_name']), 'g' => trim($_POST['generic_name']) ?: null, 's' => trim($_POST['strength']),
                  'm' => trim($_POST['manufacturer']), 'c' => $_POST['category_id'], 'u' => trim($_POST['unit']),
                  'p' => $_POST['selling_price'], 'r' => $_POST['reorder_level']];
            if (($_POST['id'] ?? '') !== '') {
                $b['id'] = $_POST['id'];
                ex('UPDATE medicine SET medicine_name=:n, generic_name=:g, strength=:s, manufacturer=:m, category_id=:c,
                    unit=:u, selling_price=:p, reorder_level=:r WHERE medicine_id=:id', $b); $msg = 'Medicine updated.';
            } else {
                ex('INSERT INTO medicine (medicine_name, generic_name, strength, manufacturer, category_id, unit, selling_price, reorder_level)
                    VALUES (:n,:g,:s,:m,:c,:u,:p,:r)', $b); $msg = 'Medicine added.';
            }
        }
    } catch (Exception $e) {
        $err = strpos($e->getMessage(), 'ORA-00001') !== false ? 'This medicine (name + strength + manufacturer) already exists.' : clean_err($e->getMessage());
    }
}
$edit = !empty($_GET['edit']) ? (q('SELECT * FROM medicine WHERE medicine_id = :id', ['id' => $_GET['edit']])[0] ?? []) : [];
$cats = q('SELECT category_id, category_name FROM category ORDER BY category_name');
page_header('Medicines');
notice($msg, $err);
if ($canEdit) {
    $v = fn($k) => h($edit[$k] ?? '');
    echo '<form method="post" class="card"><input type="hidden" name="id" value="' . $v('MEDICINE_ID') . '">';
    echo '<label>Name *<input name="medicine_name" required value="' . $v('MEDICINE_NAME') . '"></label>';
    echo '<label>Generic name<input name="generic_name" value="' . $v('GENERIC_NAME') . '"></label>';
    echo '<label>Strength *<input name="strength" required value="' . $v('STRENGTH') . '"></label>';
    echo '<label>Manufacturer *<input name="manufacturer" required value="' . $v('MANUFACTURER') . '"></label>';
    echo '<label>Category *<select name="category_id">';
    foreach ($cats as $c) echo '<option value="' . $c['CATEGORY_ID'] . '"' . (($edit['CATEGORY_ID'] ?? '') == $c['CATEGORY_ID'] ? ' selected' : '') . '>' . h($c['CATEGORY_NAME']) . '</option>';
    echo '</select></label><label>Unit *<input name="unit" required value="' . ($v('UNIT') ?: 'Packet') . '"></label>';
    echo '<label>Selling price *<input name="selling_price" type="number" step="0.01" min="0" required value="' . $v('SELLING_PRICE') . '"></label>';
    echo '<label>Reorder level *<input name="reorder_level" type="number" min="0" required value="' . ($v('REORDER_LEVEL') ?: 10) . '"></label>';
    echo '<button>' . ($edit ? 'Update' : 'Add medicine') . '</button>' . ($edit ? ' <a href="?">Cancel</a>' : '') . '</form>';
}
$s = '%' . trim($_GET['s'] ?? '') . '%';
echo '<form class="card noprint"><label>Search<input name="s" value="' . h($_GET['s'] ?? '') . '"></label><button>Search</button></form>';
$rows = q('SELECT m.medicine_id, m.medicine_name, m.strength, m.manufacturer, c.category_name, m.selling_price, m.reorder_level,
                  fn_available_stock(m.medicine_id) AS available, m.is_active
           FROM medicine m JOIN category c ON c.category_id = m.category_id
           WHERE UPPER(m.medicine_name) LIKE UPPER(:s1) OR UPPER(m.generic_name) LIKE UPPER(:s2)
           ORDER BY m.medicine_name FETCH FIRST 200 ROWS ONLY', ['s1' => $s, 's2' => $s]);
echo '<div class="scroll"><table><tr><th>Name</th><th>Strength</th><th>Manufacturer</th><th>Category</th><th>Price</th><th>Reorder</th><th>Available</th><th>Active</th><th></th></tr>';
foreach ($rows as $r) {
    echo '<tr><td>' . h($r['MEDICINE_NAME']) . '</td><td>' . h($r['STRENGTH']) . '</td><td>' . h($r['MANUFACTURER']) . '</td><td>' . h($r['CATEGORY_NAME'])
       . '</td><td>' . h($r['SELLING_PRICE']) . '</td><td>' . h($r['REORDER_LEVEL']) . '</td><td>' . h($r['AVAILABLE']) . '</td><td>' . ($r['IS_ACTIVE'] ? 'Yes' : 'No') . '</td><td>';
    if ($canEdit) echo '<a href="?edit=' . h($r['MEDICINE_ID']) . '">Edit</a> <form method="post" class="inline"><button class="link" name="toggle" value="' . h($r['MEDICINE_ID']) . '">'
                     . ($r['IS_ACTIVE'] ? 'Deactivate' : 'Activate') . '</button></form>';
    echo '</td></tr>';
}
echo '</table></div>';
page_footer();
