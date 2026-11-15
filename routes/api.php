<?php

use App\Http\Controllers\Api\AuthController;
use App\Http\Controllers\Api\ChatController;
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

// Lumora Logistics Waybill Barcode Bridge (used by Lumora Scanner & Sorting Center)
Route::get('/logistics/waybill/{barcode}', [OrderController::class, 'waybillLookup']);
Route::post('/logistics/waybill/{barcode}/status', [OrderController::class, 'waybillStatusUpdate']);

// Public product catalog
Route::get('/products', [ProductController::class, 'index']);
Route::get('/products/{id}', [ProductController::class, 'show'])->whereNumber('id');

// Authentication & Email OTP
Route::prefix('auth')->group(function () {
    Route::post('/login', [AuthController::class, 'login'])->middleware('throttle:10,1');
    Route::post('/register', [AuthController::class, 'register'])->middleware('throttle:10,1');
    Route::post('/otp/send', [AuthController::class, 'sendOtp'])->middleware('throttle:5,1');
    Route::post('/otp/verify', [AuthController::class, 'verifyOtp'])->middleware('throttle:10,1');
    Route::post('/password/reset', [AuthController::class, 'resetPassword'])->middleware('throttle:10,1');

    Route::middleware(['auth:sanctum'])->group(function () {
        Route::get('/me', [AuthController::class, 'me']);
        Route::post('/logout', [AuthController::class, 'logout']);
        Route::put('/profile', [AuthController::class, 'updateProfile']);
        Route::post('/avatar', [AuthController::class, 'updateAvatar']);
        Route::delete('/avatar', [AuthController::class, 'removeAvatar']);
        Route::put('/profile/password', [AuthController::class, 'updatePassword']);
        Route::delete('/profile', [AuthController::class, 'deleteProfile']);
        Route::get('/sessions', [AuthController::class, 'sessions']);
        Route::delete('/sessions/{id}', [AuthController::class, 'revokeSession']);
    });
});

// Authenticated user endpoint
Route::middleware(['auth:sanctum'])->group(function () {
    Route::get('/user', fn (Request $request) => $request->user());

    // Mobile buyer <-> seller chat & support AI concierge chat
    Route::get('/buyer/chats', [ChatController::class, 'index']);
    Route::post('/buyer/chats/start', [ChatController::class, 'start']);
    Route::get('/buyer/chats/{conversation}', [ChatController::class, 'show'])->whereNumber('conversation');
    Route::post('/buyer/chats/{conversation}/messages', [ChatController::class, 'store'])->whereNumber('conversation');
    Route::post('/buyer/chats/{conversation}/read', [ChatController::class, 'markRead'])->whereNumber('conversation');

    Route::get('/support/chat', [ChatController::class, 'supportShow']);
    Route::post('/support/chat/send', [ChatController::class, 'supportSend']);
});

// Buyer order & review endpoints (supports Bearer Sanctum token + mobile buyer identity headers)
Route::post('/orders', [OrderController::class, 'store']);
Route::get('/buyer/orders', [OrderController::class, 'index']);
Route::get('/buyer/orders/{orderId}', [OrderController::class, 'show']);
Route::get('/buyer/orders/{orderId}/track', [OrderController::class, 'track']);
Route::post('/buyer/orders/{orderId}/cancel', [OrderController::class, 'cancel']);
Route::post('/buyer/orders/{orderId}/return', [OrderController::class, 'requestReturn']);
Route::post('/buyer/orders/{orderId}/dispute', [OrderController::class, 'escalateDispute']);
Route::post('/buyer/orders/{orderId}/receive', [OrderController::class, 'receive']);
Route::post('/buyer/orders/{orderId}/payment-proof', [OrderController::class, 'replacePaymentProof']);
Route::post('/buyer/products/{product}/reviews', [OrderController::class, 'storeReview']);
