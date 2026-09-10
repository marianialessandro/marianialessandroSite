<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Illuminate\Support\Str;

class Boundary
{
    public function handle(Request $request, Closure $next)
    {
        $url = parse_url(config('mcp_nutrition.resource'));
        abort_unless(($url['scheme'] ?? '') === 'https' && $request->getHost() === ($url['host'] ?? ''), 421);
        $origin = $request->header('Origin');
        abort_if($origin && $origin !== config('app.url') && !in_array($origin, config('mcp_nutrition.origins'), true), 403);
        abort_if(strlen($request->getContent()) > config('mcp_nutrition.max_input'), 413);
        if (!$request->is('health', '.well-known/*')) {
            abort_unless(config('mcp_nutrition.enabled') && config('mcp_nutrition.allowed_user_id') && config('mcp_nutrition.client_id'), 503);
        }
        $request->attributes->set('request_id', (string) Str::uuid());
        $response = $next($request);
        if (!$response instanceof \Symfony\Component\HttpFoundation\StreamedResponse && strlen($response->getContent()) > config('mcp_nutrition.max_output')) {
            return response()->json(['error' => 'response_too_large'], 413);
        }
        $response->headers->set('Cache-Control', 'no-store');
        $response->headers->set('X-Request-ID', $request->attributes->get('request_id'));
        return $response;
    }
}
