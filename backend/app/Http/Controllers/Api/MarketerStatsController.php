<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Order;
use App\Services\Wallet\WalletService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class MarketerStatsController extends Controller
{
    public function __invoke(Request $request, WalletService $wallet): JsonResponse
    {
        $user = $request->user();

        $orders = $user->marketerOrders();

        $totalSales = (clone $orders)->count();
        $pendingOrders = (clone $orders)->where('status', Order::STATUS_PENDING)->count();
        $confirmedOrders = (clone $orders)->where('status', Order::STATUS_CONFIRMED)->count();
        $deliveredOrders = (clone $orders)->where('status', Order::STATUS_DELIVERED)->count();
        $failedOrders = (clone $orders)->where('status', Order::STATUS_FAILED)->count();
        $cancelledOrders = (clone $orders)->where('status', Order::STATUS_CANCELLED)->count();

        $wallet = $wallet->balanceFor($user);

        return response()->json([
            'total_sales' => $totalSales,
            'pending_orders' => $pendingOrders,
            'confirmed_orders' => $confirmedOrders,
            'delivered_orders' => $deliveredOrders,
            'failed_orders' => $failedOrders,
            'cancelled_orders' => $cancelledOrders,
            'delivery_rate' => $totalSales > 0 ? round(($deliveredOrders / $totalSales) * 100, 1) : 0,
            'wallet' => $wallet,
        ]);
    }
}
