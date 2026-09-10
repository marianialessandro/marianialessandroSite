<?php

use App\Http\Middleware\OAuthResource;
use App\Http\Middleware\PersonalAccess;
use App\Http\Middleware\PersonalSession;
use App\Services\SigningKeys;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Route;
use Laravel\Mcp\Facades\Mcp;
use Laravel\Passport\Http\Controllers\AccessTokenController;
use Laravel\Passport\Http\Controllers\ApproveAuthorizationController;
use Laravel\Passport\Http\Controllers\AuthorizationController;
use Laravel\Passport\Http\Controllers\DenyAuthorizationController;

Route::get('/health', fn () => response()->json(['status' => 'ok']));
Route::get('/.well-known/jwks.json', fn () => response()->json(SigningKeys::jwks()));
Route::get('/.well-known/oauth-authorization-server', fn () => response()->json(['issuer' => config('app.url'), 'authorization_endpoint' => config('app.url').'/oauth/authorize', 'token_endpoint' => config('app.url').'/oauth/token', 'jwks_uri' => config('app.url').'/.well-known/jwks.json', 'response_types_supported' => ['code'], 'grant_types_supported' => ['authorization_code', 'refresh_token'], 'code_challenge_methods_supported' => ['S256'], 'token_endpoint_auth_methods_supported' => ['client_secret_post', 'client_secret_basic', 'none'], 'scopes_supported' => config('mcp_nutrition.scopes')]));
foreach (['/.well-known/oauth-protected-resource', '/.well-known/oauth-protected-resource/mcp'] as $path) {
    Route::get($path, fn () => response()->json(['resource' => config('mcp_nutrition.resource'), 'authorization_servers' => [config('app.url')], 'scopes_supported' => config('mcp_nutrition.scopes'), 'bearer_methods_supported' => ['header']]));
}
Route::get('/login', fn () => view('login'))->name('login');
Route::post('/login', function (Request $request) {
    $credentials = $request->validate(['email' => ['required', 'email', 'max:255'], 'password' => ['required', 'string', 'max:255']]);
    if (!Auth::attempt($credentials)) {
        return back()->withErrors(['email' => 'Credenziali non valide.']);
    }
    if (!$request->user()->is_admin || (string) $request->user()->id !== (string) config('mcp_nutrition.allowed_user_id')) {
        Auth::logout();
        $request->session()->invalidate();
        abort(403);
    }
    $request->session()->regenerate();
    return redirect()->intended('/');
})->middleware('throttle:5,1');
Route::get('/', fn () => response('Nutrition MCP'))->middleware(PersonalSession::class);
Route::get('/oauth/authorize', [AuthorizationController::class, 'authorize'])->middleware([OAuthResource::class, PersonalSession::class])->name('passport.authorizations.authorize');
Route::post('/oauth/authorize', [ApproveAuthorizationController::class, 'approve'])->middleware(PersonalSession::class)->name('passport.authorizations.approve');
Route::delete('/oauth/authorize', [DenyAuthorizationController::class, 'deny'])->middleware(PersonalSession::class)->name('passport.authorizations.deny');
Route::post('/oauth/token', [AccessTokenController::class, 'issueToken'])->middleware([OAuthResource::class, 'throttle:20,1'])->name('passport.token');
Route::middleware([PersonalAccess::class, 'throttle:60,1'])->group(function () {
    Mcp::web('/mcp', App\Mcp\NutritionServer::class);
});
