<?php

use App\Http\Controllers\Api\AuthController;
use App\Http\Controllers\Api\OrderController;
use App\Http\Controllers\Api\ProductController;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;

/*
|--------------------------------------------------------------------------
| Lumora Mobile App API  (prefix: /api)
|--------------------------------------------------------------------------
| Used by the Flutter app. Authenticated routes expect the header:
|   Authorization: Bearer <token>
*/

Route::get('/health', function () {
    return response()->json([
        'status' => 'ok',
        'time' => now()->toIso8601String(),
    ]);
});

// Public product catalog
Route::get('/products', [ProductController::class, 'index']);
Route::get('/products/{id}', [ProductController::class, 'show'])->whereNumber('id');

// Authentication & Email OTP
Route::prefix('auth')->group(function () {
    Route::post('/login', [AuthController::class, 'login'])->middleware('throttle:10,1');
    Route::post('/register', [AuthController::class, 'register'])->middleware('throttle:10,1');
    Route::post('/otp/send', [AuthController::class, 'sendOtp'])->middleware('throttle:5,1');
    Route::post('/otp/verify', [AuthController::class, 'verifyOtp'])->middleware('throttle:10,1');

    Route::middleware('auth:sanctum')->group(function () {
        Route::get('/me', [AuthController::class, 'me']);
        Route::post('/logout', [AuthController::class, 'logout']);
    });
});

// Authenticated buyer endpoints
Route::middleware('auth:sanctum')->group(function () {
    Route::get('/user', fn (Request $request) => $request->user());

    Route::post('/orders', [OrderController::class, 'store']);
    Route::get('/buyer/orders', [OrderController::class, 'index']);
    Route::post('/buyer/orders/{orderId}/cancel', [OrderController::class, 'cancel']);
    Route::post('/buyer/orders/{orderId}/return', [OrderController::class, 'requestReturn']);
    Route::post('/buyer/orders/{orderId}/dispute', [OrderController::class, 'escalateDispute']);
    Route::post('/buyer/products/{product}/reviews', [OrderController::class, 'storeReview']);
});
