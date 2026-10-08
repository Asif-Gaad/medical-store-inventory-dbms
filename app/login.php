<?php
require 'config.php';
$err = '';
if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    try {
        // password is compared as a SHA-256 hash, exactly how 04_sample_data.sql stored it
        $r = q("SELECT user_id, full_name, role FROM users
                WHERE username = :u AND is_active = 1
                  AND password_hash = RAWTOHEX(STANDARD_HASH(:p, 'SHA256'))",
               ['u' => trim($_POST['username'] ?? ''), 'p' => $_POST['password'] ?? '']);
        if ($r) {
            session_regenerate_id(true);
            $_SESSION['uid'] = $r[0]['USER_ID']; $_SESSION['name'] = $r[0]['FULL_NAME']; $_SESSION['role'] = $r[0]['ROLE'];
            header('Location: dashboard.php'); exit;
        }
        $err = 'Wrong username or password.';
    } catch (Exception $e) { $err = $e->getMessage(); }
}
?><!DOCTYPE html><html><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>Login</title><link rel="stylesheet" href="style.css"></head><body>
<form method="post" class="card login"><h1>+ Medical Store Login</h1>
<?php if ($err) echo '<div class="err">' . h($err) . '</div>'; ?>
<label>Username<input name="username" required autofocus></label>
<label>Password<input name="password" type="password" required></label>
<button>Login</button>
<p class="muted">Demo: admin / admin123, hina.p / hina123, imran.k / imran123</p></form></body></html>
