<?php

namespace App\Http\Middleware;

use App\Services\SigningKeys;
use Closure;
use Firebase\JWT\JWT;
use Firebase\JWT\Key;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Throwable;

class PersonalAccess implements \Illuminate\Contracts\Auth\Middleware\AuthenticatesRequests
{
    public function handle(Request $request, Closure $next)
    {
        try {
            $jwt = $request->bearerToken();
            if (!$jwt || strlen($jwt) > 16384) {
                throw new \RuntimeException();
            }
            $claims = (array) JWT::decode($jwt, new Key(SigningKeys::publicKey(), 'RS256'));
            if (($claims['iss'] ?? '') !== config('app.url') || ($claims['token_use'] ?? '') !== 'access' || !in_array(config('mcp_nutrition.resource'), (array) ($claims['aud'] ?? []), true)) {
                throw new \RuntimeException();
            }
            if (!is_int($claims['iat'] ?? null) || !is_int($claims['exp'] ?? null) || $claims['exp'] - $claims['iat'] > 600) {
                throw new \RuntimeException();
            }
            $user = Auth::guard('api')->user();
            if (!$user || !$user->is_admin || (string) $user->id !== (string) config('mcp_nutrition.allowed_user_id') || (string) $user->token()->client_id !== (string) config('mcp_nutrition.client_id')) {
                throw new \RuntimeException();
            }
            $scopes = array_values(array_intersect($user->token()->scopes, config('mcp_nutrition.scopes')));
            if (!$scopes) {
                throw new \RuntimeException();
            }
            $request->setUserResolver(fn () => $user);
            $request->attributes->set('nutrition_scopes', $scopes);
        } catch (Throwable $exception) {
            return response()->json(['error' => 'invalid_token'], 401)->header('WWW-Authenticate', 'Bearer resource_metadata="'.config('app.url').'/.well-known/oauth-protected-resource/mcp"');
        }
        return $next($request);
    }
}
