<?php

use App\Http\Controllers\Api\Admin\CategoryAdminController;
use App\Http\Controllers\Api\Admin\DashboardController;
use App\Http\Controllers\Api\Admin\OrderAdminController;
use App\Http\Controllers\Api\Admin\ProductAdminController;
use App\Http\Controllers\Api\Admin\SettingController;
use App\Http\Controllers\Api\Admin\UserController;
use App\Http\Controllers\Api\Admin\WithdrawalController;
use App\Http\Controllers\Api\AuthController;
use App\Http\Controllers\Api\BrandController;
use App\Http\Controllers\Api\CategoryController;
use App\Http\Controllers\Api\Confirmatrice\OrderWorkflowController;
use App\Http\Controllers\Api\DeliveryController;
use App\Http\Controllers\Api\MarketerStatsController;
use App\Http\Controllers\Api\OrderController;
use App\Http\Controllers\Api\ProductController;
use App\Http\Controllers\Api\WalletController;
use Illuminate\Support\Facades\Route;

// ─── Auth (public) ───────────────────────────────────────────────────────────
Route::prefix('auth')->group(function () {
    Route::post('register', [AuthController::class, 'register']);
    Route::post('login', [AuthController::class, 'login']);
    Route::post('refresh', [AuthController::class, 'refresh']);
});

// Image Proxy to avoid CORS issues on Flutter Web (CanvasKit)
Route::get('image', function (\Illuminate\Http\Request $request) {
    $path = $request->query('path');
    if (!$path) abort(400, 'Path is required');
    $fullPath = storage_path('app/public/' . $path);
    if (!file_exists($fullPath)) abort(404, 'Image not found');
    return response()->file($fullPath);
});

// ─── Public resources (require auth but open to all roles) ───────────────────
Route::middleware('auth:api')->group(function () {
    Route::get('me', [AuthController::class, 'me']);
    Route::put('me', [AuthController::class, 'updateProfile']);
    Route::post('auth/logout', [AuthController::class, 'logout']);

    // Public product & category catalog
    Route::get('products', [ProductController::class, 'index']);
    Route::get('products/{product}', [ProductController::class, 'show']);
    Route::get('categories', [CategoryController::class, 'index']);
    Route::get('delivery/territories', [DeliveryController::class, 'territories']);
    Route::get('delivery/rates', [DeliveryController::class, 'rates']);
    Route::get('app/settings', [\App\Http\Controllers\Api\Admin\SettingController::class, 'publicSettings']);
    Route::post('orders/{order}/delivery-status', [DeliveryController::class, 'syncOrder']);
    Route::post('/orders/{order}/cancel', [OrderController::class, 'cancel']);
    Route::get('brands', [BrandController::class, 'index']);

    // ─── Marketer routes ─────────────────────────────────────────────────────
    Route::middleware('role:marketer')->group(function () {
        Route::apiResource('orders', OrderController::class)->only(['index', 'store', 'show', 'update']);
        Route::get('wallet', [WalletController::class, 'summary']);
        Route::get('wallet/transactions', [WalletController::class, 'transactions']);
        Route::post('wallet/withdraw', [WalletController::class, 'withdraw']);
        Route::get('marketer/stats', MarketerStatsController::class);
    });

    // ─── Confirmatrice routes ─────────────────────────────────────────────────
    Route::prefix('confirmatrice')->middleware('role:confirmatrice,admin')->group(function () {
        Route::get('orders', [OrderWorkflowController::class, 'index']);
        Route::patch('orders/{order}/status', [OrderWorkflowController::class, 'updateStatus']);
        Route::patch('orders/{order}', [OrderWorkflowController::class, 'update']);
    });

    Route::get('admin/dashboard', DashboardController::class)->middleware('role:admin,confirmatrice');

    // ─── Admin routes ─────────────────────────────────────────────────────────
    Route::prefix('admin')->middleware('role:admin')->group(function () {
        // Users (marketers, confirmatrices, admins)
        Route::apiResource('users', UserController::class)->only(['index', 'store', 'update']);
        Route::get('users/{user}/stats', [UserController::class, 'stats']);

        // Orders
        Route::get('orders', [OrderAdminController::class, 'index']);
        Route::patch('orders/{order}/status', [OrderAdminController::class, 'updateStatus']);
        Route::patch('orders/{order}', [OrderAdminController::class, 'update']);
        Route::patch('orders/{order}/assign-confirmatrice', [OrderAdminController::class, 'assignConfirmatrice']);

        // Products
        Route::apiResource('products', ProductAdminController::class)->only(['index', 'store', 'update']);
        Route::patch('products/{product}/archive', [ProductAdminController::class, 'archive']);
        Route::patch('variants/{variant}', [ProductAdminController::class, 'updateVariant']);

        // Categories
        Route::get('categories', [CategoryAdminController::class, 'index']);
        Route::post('categories', [CategoryAdminController::class, 'store']);
        Route::patch('categories/{category}', [CategoryAdminController::class, 'update']);

        // Wallet / Withdrawals
        Route::get('wallet/withdrawals', [WithdrawalController::class, 'index']);
        Route::patch('wallet/withdrawals/{withdrawal}/approve', [WithdrawalController::class, 'approve']);
        Route::patch('wallet/withdrawals/{withdrawal}/reject', [WithdrawalController::class, 'reject']);

        // Settings (delivery API keys, etc.)
        Route::get('settings', [SettingController::class, 'index']);
        Route::patch('settings', [SettingController::class, 'upsert']);
        Route::post('settings/upload-pdf', [SettingController::class, 'uploadPdf']);

        // Shipping Rates management
        Route::get('shipping-rates', [\App\Http\Controllers\Api\Admin\ShippingRateAdminController::class, 'index']);
        Route::patch('shipping-rates', [\App\Http\Controllers\Api\Admin\ShippingRateAdminController::class, 'bulkUpdate']);
    });
});
