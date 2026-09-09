<?php

namespace App\Providers;

use App\Services\ResourceAccessToken;
use Illuminate\Support\ServiceProvider;
use Laravel\Passport\Passport;

class AppServiceProvider extends ServiceProvider
{
    public function register(): void
    {
        Passport::ignoreRoutes();
    }

    public function boot(): void
    {
        Passport::useAccessTokenEntity(ResourceAccessToken::class);
        Passport::tokensExpireIn(now()->addMinutes(10));
        Passport::refreshTokensExpireIn(now()->addDays(7));
        Passport::tokensCan(['nutrition:read' => 'Lettura nutrizionale', 'nutrition:write' => 'Scrittura nutrizionale', 'nutrition:delete' => 'Cancellazione nutrizionale', 'nutrition:maintenance' => 'Manutenzione nutrizionale']);
        Passport::authorizationView('authorize');
    }
}
