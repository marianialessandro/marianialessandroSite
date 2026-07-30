<?php

return [

    /*
    |--------------------------------------------------------------------------
    | Cross-Origin Resource Sharing (CORS) Configuration
    |--------------------------------------------------------------------------
    |
    | Allows the blog frontend (a different origin) to call the JSON API
    | directly from the browser, e.g. for the /admin panel. Credentials are
    | session cookies, so production must list the exact trusted frontend
    | origin in CORS_ALLOWED_ORIGINS.
    |
    */

    'paths' => ['api/*', 'sanctum/csrf-cookie'],

    'allowed_methods' => ['GET', 'POST', 'PUT', 'PATCH', 'DELETE', 'OPTIONS'],

    'allowed_origins' => array_values(array_filter(array_map(
        'trim',
        explode(',', env('CORS_ALLOWED_ORIGINS', 'http://localhost:5175'))
    ))),

    'allowed_origins_patterns' => [],

    'allowed_headers' => [
        'Accept',
        'Content-Type',
        'Origin',
        'X-Requested-With',
        'X-XSRF-TOKEN',
    ],

    'exposed_headers' => [],

    'max_age' => 600,

    'supports_credentials' => true,

];
