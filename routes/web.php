<?php

use App\Http\Controllers\ChatController;
use App\Http\Controllers\ProfileController;
use App\Http\Controllers\Admin\DashboardController;
use App\Http\Controllers\Seller\SellerDashboardController;
use App\Http\Controllers\Seller\ProductController;
use App\Http\Controllers\Seller\PayoutController;
use App\Http\Controllers\Seller\ProfileController as SellerProfileController;
use App\Http\Controllers\Buyer\ShopController;
use Illuminate\Support\Facades\Route;

Route::get('/', [ShopController::class, 'index'])->name('home');

// Admin routes
Route::middleware(['auth', 'role:admin'])->prefix('admin')->name('admin.')->group(function () {
    Route::get('/dashboard', [DashboardController::class, 'index'])->name('dashboard');
    Route::get('/application/{id}/{action}', [DashboardController::class, 'handleApplication'])->name('application');
    Route::get('/users', [DashboardController::class, 'users'])->name('users');
    Route::get('/applications', [DashboardController::class, 'applications'])->name('applications');
    Route::get('/users/{id}/{action}', [DashboardController::class, 'handleUserStatus'])->name('users.action');

    // Compliance routes
    Route::get('/compliance', [DashboardController::class, 'compliance'])->name('compliance');
    Route::get('/compliance/product/{id}/flag', [DashboardController::class, 'flagProduct'])->name('compliance.flag');
    Route::get('/compliance/product/{id}/clear', [DashboardController::class, 'clearProduct'])->name('compliance.clear');
    Route::post('/compliance/seller/{id}/warn', [DashboardController::class, 'warnSeller'])->name('compliance.warn');

    // Complaints & Disputes routes
    Route::get('/complaints', [DashboardController::class, 'complaints'])->name('complaints');
    Route::post('/complaints/{id}/resolve', [DashboardController::class, 'resolveComplaint'])->name('complaints.resolve');
    Route::post('/complaints/{id}/dismiss', [DashboardController::class, 'dismissComplaint'])->name('complaints.dismiss');

    // Commission
    Route::get('/commission', [DashboardController::class, 'commission'])->name('commission');

    // Reports (PDF downloads, triggered from the Commission page)
    Route::get('/reports/sales-summary', [DashboardController::class, 'salesSummaryPdf'])->name('reports.salesSummary');
    Route::get('/reports/commission', [DashboardController::class, 'commissionReportPdf'])->name('reports.commission');
    // Announcements, Platforms Policies 
    Route::get('/settings', [DashboardController::class, 'settings'])->name('settings.index');
    Route::post('/settings/announcements', [DashboardController::class, 'storeAnnouncement'])->name('settings.announcements.store');
    Route::patch('/settings/announcements/{id}/toggle', [DashboardController::class, 'toggleAnnouncement'])->name('settings.announcements.toggle');
    Route::patch('/settings/policies/{id}', [DashboardController::class, 'updatePolicy'])->name('settings.policies.update');

    // Admin inbox for messages from buyers/sellers
    Route::get('/chat', [ChatController::class, 'adminInbox'])->name('chat.index');
    Route::get('/chat/{id}', [ChatController::class, 'adminShow'])->name('chat.show');
});

// Seller routes
Route::middleware(['auth', 'role:seller'])->prefix('seller')->name('seller.')->group(function () {
    Route::get('/dashboard', [SellerDashboardController::class, 'index'])->name('dashboard');

    Route::get('/products', [ProductController::class, 'index'])->name('products.index');
    Route::post('/products', [ProductController::class, 'store'])->name('products.store');
    Route::patch('/products/{id}/stock', [ProductController::class, 'updateStock'])->name('products.updateStock');
    Route::delete('/products/{id}', [ProductController::class, 'destroy'])->name('products.destroy');

    Route::get('/payouts', [PayoutController::class, 'index'])->name('payouts.index');
    Route::post('/payouts/method', [PayoutController::class, 'saveMethod'])->name('payouts.saveMethod');
    Route::post('/payouts/request', [PayoutController::class, 'requestPayout'])->name('payouts.request');

    Route::get('/profile', [SellerProfileController::class, 'index'])->name('profile.index');
    Route::patch('/profile', [SellerProfileController::class, 'update'])->name('profile.update');
    Route::patch('/profile/password', [SellerProfileController::class, 'updatePassword'])->name('profile.updatePassword');
});

// Buyer/Guest routes
Route::get('/shop', [ShopController::class, 'index'])->name('shop.index');


Route::middleware('auth')->group(function () {
    Route::get('/profile', [ProfileController::class, 'edit'])->name('profile.edit');
    Route::patch('/profile', [ProfileController::class, 'update'])->name('profile.update');
    Route::delete('/profile', [ProfileController::class, 'destroy'])->name('profile.destroy');
    Route::middleware('auth')->group(function () {
    Route::get('/chat/my-conversation', [ChatController::class, 'myConversation'])->name('chat.mine');
    Route::post('/chat/send', [ChatController::class, 'send'])->name('chat.send');
});

    Route::view('/seller/application-pending', 'seller.pending')->name('seller.pending');
});

// Email verification (used during registration, before a user account exists)
Route::post('/register/send-code', [\App\Http\Controllers\Auth\EmailVerificationController::class, 'sendCode'])->name('register.sendCode');
Route::post('/register/verify-code', [\App\Http\Controllers\Auth\EmailVerificationController::class, 'verifyCode'])->name('register.verifyCode');
 
// Address lookups (proxied server-side to avoid browser CORS issues with psgc.cloud)
Route::get('/address/provinces', [\App\Http\Controllers\AddressController::class, 'provinces'])->name('address.provinces');
Route::get('/address/provinces/{code}/municipalities', [\App\Http\Controllers\AddressController::class, 'municipalities'])->name('address.municipalities');
Route::get('/address/municipalities/{code}/barangays', [\App\Http\Controllers\AddressController::class, 'barangays'])->name('address.barangays');

require __DIR__.'/auth.php';