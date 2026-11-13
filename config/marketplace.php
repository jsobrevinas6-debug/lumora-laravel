<?php

return [
    'require_product_approval' => env('MARKETPLACE_REQUIRE_PRODUCT_APPROVAL', true),
    'require_buyer_approval' => env('MARKETPLACE_REQUIRE_BUYER_APPROVAL', true),
    'require_buyer_id' => env('MARKETPLACE_REQUIRE_BUYER_ID', true),
    'id_retention_days' => env('MARKETPLACE_ID_RETENTION_DAYS') !== null
        ? (int) env('MARKETPLACE_ID_RETENTION_DAYS')
        : null,
    'id_retention_approved' => (bool) env('MARKETPLACE_ID_RETENTION_APPROVED', false),
];
