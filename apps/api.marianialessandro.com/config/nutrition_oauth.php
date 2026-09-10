<?php

return [
    'enabled' => env('NUTRITION_OAUTH_ENABLED', false),
    'issuer' => env('NUTRITION_OAUTH_ISSUER'),
    'audience' => env('NUTRITION_OAUTH_AUDIENCE'),
    'jwks_url' => env('NUTRITION_OAUTH_JWKS_URL'),
    'service_claim' => env('NUTRITION_OAUTH_SERVICE_CLAIM', 'sub'),
    'access_claim' => env('NUTRITION_OAUTH_ACCESS_CLAIM', 'gty'),
    'access_value' => env('NUTRITION_OAUTH_ACCESS_VALUE', 'client-credentials'),
];
