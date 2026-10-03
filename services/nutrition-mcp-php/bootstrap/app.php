<?php

use Illuminate\Foundation\Application;
use Illuminate\Foundation\Configuration\Exceptions;
use Illuminate\Foundation\Configuration\Middleware;
use Illuminate\Support\Facades\Route;

return Application::configure(basePath: dirname(__DIR__))->withRouting(web: __DIR__.'/../routes/web.php', commands: __DIR__.'/../routes/console.php', then: function (): void {
    Route::middleware('api')->group(base_path('routes/public.php'));
})->withMiddleware(function (Middleware $middleware): void {
    $middleware->prepend(\App\Http\Middleware\Boundary::class);
    $middleware->validateCsrfTokens(except: ['mcp', 'oauth/token']);
    $middleware->redirectGuestsTo(fn () => route('login'));
})->withExceptions(function (Exceptions $exceptions): void {
    $exceptions->shouldRenderJsonWhen(fn ($request) => !$request->is('login', 'oauth/authorize'));
})->create();
