<?php
require 'config.php'; guard(['ADMIN', 'PHARMACIST']);
crud_page('customer', 'customer_id', 'Customers', [
    'customer_name' => ['Name', 1], 'phone' => ['Phone', 0], 'address' => ['Address', 0]]);
