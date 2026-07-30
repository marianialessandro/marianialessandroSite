<?php

use App\Http\Controllers\AuthController;
use App\Http\Controllers\PostController;
use App\Http\Controllers\UploadController;
use App\Http\Controllers\UserController;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Route;

Route::post('/auth/login', [AuthController::class, 'login'])->middleware('throttle:admin-login');

Route::get('/posts', [PostController::class, 'index']);
Route::get('/posts/{post}', [PostController::class, 'show']);

Route::get('/uploads/{path}', [UploadController::class, 'show'])->where('path', '.*');

Route::middleware(['auth:web', 'admin'])->group(function () {
    Route::post('/auth/logout', [AuthController::class, 'logout']);
    Route::get('/auth/me', [AuthController::class, 'me']);

    Route::get('/admin/posts', [PostController::class, 'adminIndex']);
    Route::get('/admin/posts/{post}', [PostController::class, 'adminShow']);
    Route::post('/uploads', [UploadController::class, 'store']);
    Route::post('/posts', [PostController::class, 'store']);
    Route::put('/posts/{post}', [PostController::class, 'update']);
    Route::delete('/posts/{post}', [PostController::class, 'destroy']);

    Route::get('/users', [UserController::class, 'index']);
    Route::post('/users', [UserController::class, 'store']);
    Route::put('/users/{user}', [UserController::class, 'update']);
    Route::delete('/users/{user}', [UserController::class, 'destroy']);
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
