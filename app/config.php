<?php
// ---- Database settings (change only if your password/service differ) ----
const DB_USER = 'MEDSTORE';
const DB_PASS = 'MedStore#123';
const DB_DSN  = 'localhost:1521/FREEPDB1';

session_start();

function h($v) { return htmlspecialchars((string)$v, ENT_QUOTES, 'UTF-8'); }

function db() {
    static $c = null;
    if ($c === null) {
        $c = @oci_connect(DB_USER, DB_PASS, DB_DSN, 'AL32UTF8');
        if (!$c) { $e = oci_error(); die('Database connection failed: ' . h($e['message'])); }
    }
    return $c;
}

// SELECT -> array of rows (column names are UPPERCASE)
function q($sql, $b = []) {
    $st = oci_parse(db(), $sql);
    foreach ($b as $k => $v) { oci_bind_by_name($st, ':' . $k, $b[$k]); }
    if (!oci_execute($st, OCI_NO_AUTO_COMMIT)) { $e = oci_error($st); throw new Exception($e['message']); }
    oci_fetch_all($st, $rows, 0, -1, OCI_FETCHSTATEMENT_BY_ROW + OCI_ASSOC);
    return $rows;
}

// INSERT / UPDATE / DELETE / procedure call. $commit=false keeps a transaction open.
function ex($sql, $b = [], $commit = true) {
    $st = oci_parse(db(), $sql);
    foreach ($b as $k => $v) { oci_bind_by_name($st, ':' . $k, $b[$k]); }
    if (!oci_execute($st, $commit ? OCI_COMMIT_ON_SUCCESS : OCI_NO_AUTO_COMMIT)) {
        $e = oci_error($st); throw new Exception($e['message']);
    }
    return oci_num_rows($st);
}

// Call a procedure that has ONE out parameter (named $out) and return its value
function call_out($sql, $b, $out) {
    $st = oci_parse(db(), $sql);
    foreach ($b as $k => $v) { oci_bind_by_name($st, ':' . $k, $b[$k]); }
    $val = null;
    oci_bind_by_name($st, ':' . $out, $val, 32);
    if (!oci_execute($st, OCI_NO_AUTO_COMMIT)) { $e = oci_error($st); throw new Exception($e['message']); }
    return $val;
}

// Show only our friendly ORA-20xxx text when available
function clean_err($m) {
    if (preg_match('/ORA-20\d{3}: ([^\r\n]*)/', $m, $x)) return $x[1];
    return $m;
}

function guard($roles = []) {
    if (empty($_SESSION['uid'])) { header('Location: login.php'); exit; }
    if ($roles && !in_array($_SESSION['role'], $roles, true)) { http_response_code(403); die('Access denied for your role.'); }
}

function page_header($title) {
    $all = ['ADMIN', 'PHARMACIST', 'STOREKEEPER'];
    $menu = [
        'dashboard.php' => ['Dashboard', $all],
        'medicines.php' => ['Medicines', $all],
        'suppliers.php' => ['Suppliers', ['ADMIN', 'STOREKEEPER']],
        'customers.php' => ['Customers', ['ADMIN', 'PHARMACIST']],
        'purchase.php'  => ['Purchases', ['ADMIN', 'STOREKEEPER']],
        'sales.php'     => ['Sales (POS)', ['ADMIN', 'PHARMACIST']],
        'inventory.php' => ['Inventory', $all],
        'alerts.php'    => ['Alerts', $all],
        'reports.php'   => ['Reports', ['ADMIN']],
    ];
    echo '<!DOCTYPE html><html><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">';
    echo '<title>' . h($title) . ' - Medical Store</title><link rel="stylesheet" href="style.css"></head><body>';
    echo '<header><b>+ Medical Store</b><nav>';
    foreach ($menu as $file => [$label, $roles]) {
        if (in_array($_SESSION['role'], $roles, true)) echo '<a href="' . $file . '">' . h($label) . '</a>';
    }
    echo '</nav><span class="who">' . h($_SESSION['name']) . ' (' . h($_SESSION['role']) . ') <a href="logout.php">Logout</a></span></header><main>';
    echo '<h1>' . h($title) . '</h1>';
}

function page_footer() { echo '</main></body></html>'; }

function notice($msg, $err = '') {
    if ($msg) echo '<div class="ok">' . h($msg) . '</div>';
    if ($err) echo '<div class="err">' . h($err) . '</div>';
}

function table($rows, $empty = 'No records.') {
    if (!$rows) { echo '<p class="muted">' . h($empty) . '</p>'; return; }
    echo '<div class="scroll"><table><tr>';
    foreach (array_keys($rows[0]) as $c) echo '<th>' . h(str_replace('_', ' ', $c)) . '</th>';
    echo '</tr>';
    foreach ($rows as $r) {
        echo '<tr>';
        foreach ($r as $v) {
            $cls = in_array($v, ['LOW STOCK', 'OUT OF STOCK', 'EXPIRED'], true) ? ' class="bad"'
                 : (is_string($v) && strpos($v, 'EXPIRES') === 0 ? ' class="warn"' : '');
            echo "<td$cls>" . h($v) . '</td>';
        }
        echo '</tr>';
    }
    echo '</table></div>';
}

// Simple add / edit / delete page used for suppliers and customers
function crud_page($table, $pk, $title, $fields) {
    $msg = $err = '';
    if ($_SERVER['REQUEST_METHOD'] === 'POST') {
        try {
            $id = $_POST['id'] ?? '';
            $b = [];
            foreach ($fields as $f => $d) { $v = trim($_POST[$f] ?? ''); $b[$f] = ($v === '') ? null : $v; }
            if (isset($_POST['delete'])) {
                ex("DELETE FROM $table WHERE $pk = :id", ['id' => $id]); $msg = 'Deleted.';
            } elseif ($id !== '') {
                $set = implode(', ', array_map(fn($f) => "$f = :$f", array_keys($fields)));
                $b['id'] = $id;
                ex("UPDATE $table SET $set WHERE $pk = :id", $b); $msg = 'Updated.';
            } else {
                $cols = implode(', ', array_keys($fields));
                $vals = implode(', ', array_map(fn($f) => ":$f", array_keys($fields)));
                ex("INSERT INTO $table ($cols) VALUES ($vals)", $b); $msg = 'Added.';
            }
        } catch (Exception $e) {
            $m = $e->getMessage();
            $err = strpos($m, 'ORA-02292') !== false ? 'Cannot delete: this record is used in purchases or sales.'
                 : (strpos($m, 'ORA-00001') !== false ? 'This value already exists (duplicate).' : clean_err($m));
        }
    }
    $edit = [];
    if (!empty($_GET['edit'])) { $edit = q("SELECT * FROM $table WHERE $pk = :id", ['id' => $_GET['edit']])[0] ?? []; }
    page_header($title);
    notice($msg, $err);
    echo '<form method="post" class="card"><input type="hidden" name="id" value="' . h($edit[strtoupper($pk)] ?? '') . '">';
    foreach ($fields as $f => [$label, $req]) {
        echo '<label>' . h($label) . ($req ? ' *' : '') . '<input name="' . $f . '" ' . ($req ? 'required ' : '')
           . 'value="' . h($edit[strtoupper($f)] ?? '') . '"></label>';
    }
    echo '<button>' . ($edit ? 'Update' : 'Add') . '</button>' . ($edit ? ' <a href="?">Cancel</a>' : '') . '</form>';
    $rows = q("SELECT * FROM $table ORDER BY $pk");
    echo '<div class="scroll"><table><tr>';
    foreach ($fields as $f => [$label, $req]) echo '<th>' . h($label) . '</th>';
    echo '<th></th></tr>';
    foreach ($rows as $r) {
        echo '<tr>';
        foreach ($fields as $f => $d) echo '<td>' . h($r[strtoupper($f)] ?? '') . '</td>';
        $id = $r[strtoupper($pk)];
        echo '<td><a href="?edit=' . h($id) . '">Edit</a> <form method="post" class="inline" onsubmit="return confirm(\'Delete?\')">'
           . '<input type="hidden" name="id" value="' . h($id) . '"><button name="delete" value="1" class="link">Delete</button></form></td></tr>';
    }
    echo '</table></div>';
    page_footer();
}
