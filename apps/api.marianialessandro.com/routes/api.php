<?php

use App\Http\Controllers\PostController;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Route;

Route::get('/posts', [PostController::class, 'index']);
Route::get('/posts/{post}', [PostController::class, 'show']);

Route::middleware('api.token')->group(function () {
    Route::post('/posts', [PostController::class, 'store']);
    Route::put('/posts/{post}', [PostController::class, 'update']);
    Route::delete('/posts/{post}', [PostController::class, 'destroy']);
});

Route::get('/health', function () {
    try {
        DB::select('select 1');
    } catch (Throwable $exception) {
        $payload = [
            'status' => 'error',
            'database' => 'unreachable',
        ];

        if (config('app.debug')) {
            $payload['message'] = $exception->getMessage();
        }

        return response()->json($payload, 500);
    }

    return response()->json([
        'status' => 'ok',
        'database' => 'connected',
    ]);
});
