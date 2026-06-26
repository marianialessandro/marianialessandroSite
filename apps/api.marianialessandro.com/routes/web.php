<?php

use Illuminate\Support\Facades\Route;

Route::get('/', function () {
    return response()->json([
        'service' => 'api.marianialessandro.com',
        'status' => 'ok',
        'health' => '/api/health',
    ]);
});
