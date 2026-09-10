<?php

return [
    'enabled' => env('MCP_ENABLED', false),
    'resource' => env('MCP_RESOURCE', 'https://mcp.marianialessandro.com/mcp'),
    'allowed_user_id' => env('MCP_ALLOWED_USER_ID'),
    'client_id' => env('MCP_CLIENT_ID'),
    'scopes' => preg_split('/\s+/', trim(env('MCP_SCOPES', 'nutrition:read')), -1, PREG_SPLIT_NO_EMPTY),
    'operations' => preg_split('/\s+/', trim(env('MCP_OPERATIONS', '')), -1, PREG_SPLIT_NO_EMPTY),
    'diagnostic_only' => env('MCP_DIAGNOSTIC_ONLY', true),
    'api_url' => env('NUTRITION_API_URL', 'https://api.marianialessandro.com/api/nutrition'),
    'api_audience' => env('NUTRITION_API_AUDIENCE', 'https://api.marianialessandro.com/nutrition'),
    'service_subject' => env('MCP_SERVICE_SUBJECT', 'nutrition-mcp-php'),
    'max_input' => 262144,
    'max_output' => 1048576,
    'origins' => preg_split('/\s+/', trim(env('MCP_ORIGINS', '')), -1, PREG_SPLIT_NO_EMPTY),
];
