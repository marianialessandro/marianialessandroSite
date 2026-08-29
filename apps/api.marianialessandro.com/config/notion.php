<?php

$dataSources = json_decode((string) env('NOTION_DATA_SOURCES', '{}'), true);

if (! is_array($dataSources)) {
    $dataSources = [];
}

return [
    'base_url' => env('NOTION_BASE_URL', 'https://api.notion.com/v1'),
    'token' => env('NOTION_TOKEN'),
    'version' => env('NOTION_VERSION', '2026-03-11'),
    'timeout' => (int) env('NOTION_TIMEOUT', 10),
    'connect_timeout' => (int) env('NOTION_CONNECT_TIMEOUT', 3),
    'max_retries' => (int) env('NOTION_MAX_RETRIES', 1),
    'rate_limit_per_minute' => (int) env('NOTION_RATE_LIMIT_PER_MINUTE', 120),
    'data_sources' => $dataSources,
];
