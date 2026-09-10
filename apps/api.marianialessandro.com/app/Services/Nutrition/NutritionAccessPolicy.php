<?php

namespace App\Services\Nutrition;

use Illuminate\Http\Request;

class NutritionAccessPolicy
{
    public const SCOPES = ['nutrition:read', 'nutrition:write', 'nutrition:delete', 'nutrition:maintenance'];

    public function allows(Request $request, string $ability): bool
    {
        if (!$request->user()?->is_admin) {
            return false;
        }
        if ($request->attributes->has('nutrition_service')) {
            return in_array($ability, $request->attributes->get('nutrition_scopes', []), true);
        }
        return $request->user()->tokenCan($ability);
    }
}
