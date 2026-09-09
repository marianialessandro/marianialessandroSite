<?php

namespace App\Http\Middleware;

use App\Models\NutritionService;
use App\Services\Nutrition\NutritionAccessPolicy;
use App\Services\Nutrition\ServiceJwtVerifier;
use Closure;
use Illuminate\Auth\Middleware\Authenticate;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Str;
use Symfony\Component\HttpFoundation\Response;
use Throwable;

class AuthenticateNutrition implements \Illuminate\Contracts\Auth\Middleware\AuthenticatesRequests
{
    public function handle(Request $request, Closure $next): Response
    {
        $token = $request->bearerToken();
        if (!$token || !str_contains($token, '.')) {
            return app(Authenticate::class)->handle($request, $next, 'sanctum');
        }
        try {
            $claims = app(ServiceJwtVerifier::class)->verify($token);
        } catch (Throwable $exception) {
            abort(401, 'Invalid service credentials.');
        }
        $service = NutritionService::with('admin')->where('issuer', $claims['issuer'])->where('subject', $claims['subject'])->where('active', true)->first();
        abort_unless($service && $service->issuer === $claims['issuer'] && $service->subject === $claims['subject'] && $service->admin?->is_admin, 403);
        $scopes = array_values(array_intersect($claims['scopes'], $service->scopes, NutritionAccessPolicy::SCOPES));
        abort_unless($scopes && !array_diff($claims['scopes'], $service->scopes), 403);
        $request->attributes->set('nutrition_service', $service->id);
        $request->attributes->set('nutrition_scopes', $scopes);
        $request->setUserResolver(fn () => $service->admin);
        $incomingId = $request->header('X-Request-ID', '');
        $requestId = Str::isUuid($incomingId) ? $incomingId : (string) Str::uuid();
        $actor = $request->header('X-Nutrition-Actor', '');
        $actor = preg_match('/\A[a-f0-9]{32}\z/', $actor) ? $actor : null;
        $started = microtime(true);
        $status = 500;
        try {
            $response = $next($request);
            $status = $response->getStatusCode();
            return $response->header('X-Request-ID', $requestId);
        } catch (Throwable $exception) {
            $status = $exception instanceof \Symfony\Component\HttpKernel\Exception\HttpExceptionInterface ? $exception->getStatusCode() : 500;
            throw $exception;
        } finally {
            Log::info('nutrition.service', ['request_id' => $requestId, 'service' => $service->id, 'actor' => $actor, 'operation' => preg_match('/\A\d+\.\d+\z/', (string) $request->route('operation')) ? $request->route('operation') : null, 'status' => $status, 'duration_ms' => round((microtime(true) - $started) * 1000)]);
        }
    }
}
