<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;

class PersonalSession
{
    public function handle(Request $request, Closure $next)
    {
        if (!$request->user()) {
            return redirect()->guest(route('login'));
        }
        abort_unless($request->user()->is_admin && (string) $request->user()->id === (string) config('mcp_nutrition.allowed_user_id'), 403);
        return $next($request);
    }
}
