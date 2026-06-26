<?php

use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Route;

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
