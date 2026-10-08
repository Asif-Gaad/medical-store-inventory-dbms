<?php
require 'config.php'; guard(['ADMIN', 'STOREKEEPER']);
crud_page('supplier', 'supplier_id', 'Suppliers', [
    'supplier_name' => ['Name', 1], 'contact_person' => ['Contact person', 0], 'phone' => ['Phone', 1],
    'email' => ['Email', 0], 'address' => ['Address', 0]]);
