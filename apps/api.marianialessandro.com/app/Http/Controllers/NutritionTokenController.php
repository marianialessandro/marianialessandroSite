<?php

namespace App\Http\Controllers;

use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Validation\Rule;

class NutritionTokenController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        return response()->json(['data' => $request->user()->tokens()->get(['id', 'name', 'abilities', 'last_used_at', 'expires_at', 'created_at'])]);
    }

    public function store(Request $request): JsonResponse
    {
        $data = $request->validate(['name' => ['required', 'string', 'max:100'], 'abilities' => ['required', 'array', 'min:1'], 'abilities.*' => ['required', Rule::in(['nutrition:read', 'nutrition:write', 'nutrition:delete', 'nutrition:maintenance'])], 'expires_in_minutes' => ['required', 'integer', 'min:1', 'max:480']]);
        $token = $request->user()->createToken($data['name'], $data['abilities'], now()->addMinutes($data['expires_in_minutes']));
        return response()->json(['id' => $token->accessToken->id, 'token' => $token->plainTextToken, 'expires_at' => $token->accessToken->expires_at], 201)->header('Cache-Control', 'no-store');
    }

    public function destroy(Request $request, string $token): JsonResponse
    {
        $request->user()->tokens()->findOrFail($token)->delete();
        return response()->json(['revoked' => true]);
    }
}
