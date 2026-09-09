<?php

return ['driver' => env('SESSION_DRIVER', 'database'), 'lifetime' => 60, 'expire_on_close' => true, 'encrypt' => true, 'files' => storage_path('framework/sessions'), 'connection' => null, 'table' => 'sessions', 'store' => null, 'lottery' => [2, 100], 'cookie' => env('SESSION_COOKIE', 'nutrition_mcp_session'), 'path' => '/', 'domain' => env('SESSION_DOMAIN', 'mcp.marianialessandro.com'), 'secure' => true, 'http_only' => true, 'same_site' => 'lax'];
