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

Route::get('/.well-known/jwks.json', fn () => response()->json(SigningKeys::jwks()));
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
