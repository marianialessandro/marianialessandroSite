<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;

class OAuthResource
{
    public function handle(Request $request, Closure $next)
    {
        abort_unless($request->input('resource') === config('mcp_nutrition.resource'), 400, 'Invalid resource.');
        $client = $request->input('client_id') ?: $request->getUser();
        abort_unless($client === config('mcp_nutrition.client_id'), 400, 'Invalid client.');
        if ($request->isMethod('get')) {
            abort_unless($request->input('code_challenge_method') === 'S256' && preg_match('/\A[A-Za-z0-9_-]{43}\z/', (string) $request->input('code_challenge')), 400, 'PKCE S256 required.');
            $requested = preg_split('/\s+/', trim((string) $request->input('scope')), -1, PREG_SPLIT_NO_EMPTY);
            abort_unless($requested && !array_diff($requested, config('mcp_nutrition.scopes')), 400, 'Invalid scope.');
        } else {
            abort_unless(in_array($request->input('grant_type'), ['authorization_code', 'refresh_token'], true), 400, 'Invalid grant.');
        }
        return $next($request);
    }
}
