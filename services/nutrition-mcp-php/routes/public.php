<?php

use Illuminate\Http\JsonResponse;
use Illuminate\Support\Facades\Route;

Route::get('/health', fn () => new JsonResponse(['status' => 'ok']));
Route::get('/.well-known/oauth-authorization-server', fn () => new JsonResponse(['issuer' => config('app.url'), 'authorization_endpoint' => config('app.url').'/oauth/authorize', 'token_endpoint' => config('app.url').'/oauth/token', 'jwks_uri' => config('app.url').'/.well-known/jwks.json', 'response_types_supported' => ['code'], 'grant_types_supported' => ['authorization_code', 'refresh_token'], 'code_challenge_methods_supported' => ['S256'], 'token_endpoint_auth_methods_supported' => ['client_secret_post', 'client_secret_basic', 'none'], 'scopes_supported' => config('mcp_nutrition.scopes')]));
foreach (['/.well-known/oauth-protected-resource', '/.well-known/oauth-protected-resource/mcp'] as $path) {
    Route::get($path, fn () => new JsonResponse(['resource' => config('mcp_nutrition.resource'), 'authorization_servers' => [config('app.url')], 'scopes_supported' => config('mcp_nutrition.scopes'), 'bearer_methods_supported' => ['header']]));
}
