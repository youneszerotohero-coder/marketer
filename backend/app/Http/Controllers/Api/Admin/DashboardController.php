<?php

namespace App\Http\Controllers\Api\Admin;

use App\Http\Controllers\Controller;
use App\Models\Order;
use App\Models\Product;
use App\Models\User;
use App\Models\WalletTransaction;
use Illuminate\Http\JsonResponse;

class DashboardController extends Controller
{
    public function __invoke(): JsonResponse
    {
        return response()->json([
            'orders' => [
                'total' => Order::count(),
                'pending' => Order::where('status', 'pending')->count(),
                'delivered' => Order::where('status', 'delivered')->count(),
                'failed' => Order::where('status', 'failed')->count(),
            ],
            'sales' => [
                'revenue' => (float) Order::where('status', 'delivered')->sum('total'),
                'commissions' => (float) WalletTransaction::where('type', 'commission')->where('status', 'approved')->sum('amount'),
            ],
            'users' => [
                'marketers' => User::where('role', 'marketer')->count(),
                'confirmatrices' => User::where('role', 'confirmatrice')->count(),
            ],
            'products' => Product::count(),
            'top_marketers' => User::where('role', 'marketer')
                ->withCount(['marketerOrders as delivered_orders_count' => fn ($q) => $q->where('status', 'delivered')])
                ->orderByDesc('delivered_orders_count')
                ->limit(5)
                ->get(),
        ]);
    }
}
