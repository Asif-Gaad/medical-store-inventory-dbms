<?php
// Open this first: http://localhost/medstore/test_connection.php
$conn = @oci_connect('MEDSTORE', 'MedStore#123', 'localhost:1521/FREEPDB1', 'AL32UTF8');
if (!$conn) { $e = oci_error(); die('Connection failed: ' . htmlspecialchars($e['message'])); }
$st = oci_parse($conn, 'SELECT COUNT(*) AS TOTAL FROM medicine');
oci_execute($st);
$row = oci_fetch_assoc($st);
echo 'Connected! Medicines in database: ' . $row['TOTAL'];
