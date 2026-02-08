<?php

use Illuminate\Support\Facades\Route;


Route::get('/health', function () {
    return response()->json([
        'ok' => true,
        'app_url' => config('app.url'),
        'env' => app()->environment(),
    ]);
});

Route::view('/', 'valentine');
Route::view('/surprise', 'surprise');
