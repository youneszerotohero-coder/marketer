<?php

use App\Http\Controllers\Api\Admin\DashboardController;
use App\Http\Controllers\Api\Admin\OrderAdminController;
use App\Http\Controllers\Api\Admin\ProductAdminController;
use App\Http\Controllers\Api\Admin\SettingController;
use App\Http\Controllers\Api\Admin\UserController;
use App\Http\Controllers\Api\Admin\WithdrawalController;
use App\Http\Controllers\Api\AuthController;
use App\Http\Controllers\Api\Confirmatrice\OrderWorkflowController;
use App\Http\Controllers\Api\OrderController;
use App\Http\Controllers\Api\ProductController;
use App\Http\Controllers\Api\WalletController;
use Illuminate\Support\Facades\Route;

Route::prefix('auth')->group(function () {
    Route::post('register', [AuthController::class, 'register']);
    Route::post('login', [AuthController::class, 'login']);
    Route::post('refresh', [AuthController::class, 'refresh']);
});

Route::middleware('auth:api')->group(function () {
    Route::get('me', [AuthController::class, 'me']);
    Route::post('auth/logout', [AuthController::class, 'logout']);

    Route::get('products', [ProductController::class, 'index']);
    Route::get('products/{product}', [ProductController::class, 'show']);

    Route::middleware('role:marketer')->group(function () {
        Route::apiResource('orders', OrderController::class)->only(['index', 'store', 'show']);
        Route::get('wallet', [WalletController::class, 'summary']);
        Route::get('wallet/transactions', [WalletController::class, 'transactions']);
        Route::post('wallet/withdraw', [WalletController::class, 'withdraw']);
    });

    Route::prefix('confirmatrice')->middleware('role:confirmatrice,admin')->group(function () {
        Route::get('orders', [OrderWorkflowController::class, 'index']);
        Route::patch('orders/{order}/status', [OrderWorkflowController::class, 'updateStatus']);
    });

    Route::prefix('admin')->middleware('role:admin')->group(function () {
        Route::get('dashboard', DashboardController::class);
        Route::apiResource('users', UserController::class)->only(['index', 'store', 'update']);

        Route::get('orders', [OrderAdminController::class, 'index']);
        Route::patch('orders/{order}/status', [OrderAdminController::class, 'updateStatus']);
        Route::patch('orders/{order}/assign-confirmatrice', [OrderAdminController::class, 'assignConfirmatrice']);

        Route::apiResource('products', ProductAdminController::class)->only(['index', 'store', 'update']);
        Route::patch('products/{product}/archive', [ProductAdminController::class, 'archive']);
        Route::patch('variants/{variant}', [ProductAdminController::class, 'updateVariant']);

        Route::get('wallet/withdrawals', [WithdrawalController::class, 'index']);
        Route::patch('wallet/withdrawals/{withdrawal}/approve', [WithdrawalController::class, 'approve']);
        Route::patch('wallet/withdrawals/{withdrawal}/reject', [WithdrawalController::class, 'reject']);

        Route::get('settings', [SettingController::class, 'index']);
        Route::patch('settings', [SettingController::class, 'upsert']);
    });
});
