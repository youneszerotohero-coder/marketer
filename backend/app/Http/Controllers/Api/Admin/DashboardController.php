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
    public function __invoke(\Illuminate\Http\Request $request): JsonResponse
    {
        $user = $request->user();
        
        $startDate = $request->query('start_date');
        $endDate = $request->query('end_date');

        $orderQuery = Order::query()
            ->when($startDate, fn($q) => $q->whereDate('created_at', '>=', $startDate))
            ->when($endDate, fn($q) => $q->whereDate('created_at', '<=', $endDate));

        $walletQuery = WalletTransaction::query()
            ->when($startDate, fn($q) => $q->whereDate('created_at', '>=', $startDate))
            ->when($endDate, fn($q) => $q->whereDate('created_at', '<=', $endDate));

        $userQuery = User::query()
            ->when($startDate, fn($q) => $q->whereDate('created_at', '>=', $startDate))
            ->when($endDate, fn($q) => $q->whereDate('created_at', '<=', $endDate));

        $productQuery = Product::query()
            ->when($startDate, fn($q) => $q->whereDate('created_at', '>=', $startDate))
            ->when($endDate, fn($q) => $q->whereDate('created_at', '<=', $endDate));

        $ordersStats = [
            'total' => (clone $orderQuery)->count(),
            'pending' => (clone $orderQuery)->where('status', 'pending')->count(),
            'confirmed' => (clone $orderQuery)->where('status', 'confirmed')->count(),
            'shipped' => (clone $orderQuery)->where('status', 'shipped')->count(),
            'delivered' => (clone $orderQuery)->where('status', 'delivered')->count(),
            'retour_facture' => (clone $orderQuery)->where('status', 'retour_facture')->count(),
            'retour_exonere' => (clone $orderQuery)->where('status', 'retour_exonere')->count(),
            'cancelled' => (clone $orderQuery)->where('status', 'cancelled')->count(),
        ];

        // Generate Chart Data
        $chartStartDate = $startDate ?: now()->subDays(30)->format('Y-m-d');
        $chartEndDate = $endDate ?: now()->format('Y-m-d');
        
        $chartOrders = Order::query()
            ->whereDate('created_at', '>=', $chartStartDate)
            ->whereDate('created_at', '<=', $chartEndDate)
            ->select('status', 'created_at')
            ->get();
            
        $chartData = $chartOrders->groupBy(function($order) {
            return $order->created_at->format('Y-m-d');
        })->map(function($dayOrders, $date) {
            return [
                'name' => \Carbon\Carbon::parse($date)->format('M d'),
                'total' => $dayOrders->count(),
                'delivered' => $dayOrders->where('status', 'delivered')->count(),
                'retours' => $dayOrders->whereIn('status', ['retour_facture', 'retour_exonere', 'cancelled'])->count(),
            ];
        })->values()->sortBy('name')->values();

        if ($user->role === 'confirmatrice') {
            return response()->json([
                'orders' => $ordersStats,
                'chart_data' => $chartData,
            ]);
        }

        $revenue = (float) (clone $orderQuery)->where('status', 'delivered')->sum('subtotal');
        $commissions = (float) (clone $walletQuery)
            ->whereHas('order', fn($q) => $q->where('status', 'delivered'))
            ->where('type', 'commission')->where('status', 'approved')->sum('amount');
        $ordersCost = (float) \App\Models\OrderItem::whereIn('order_id', (clone $orderQuery)->where('status', 'delivered')->pluck('id'))
            ->join('product_variants', 'order_items.product_variant_id', '=', 'product_variants.id')
            ->sum(\DB::raw('order_items.quantity * product_variants.purchase_price'));
        $netProfit = $revenue - $ordersCost - $commissions;

        return response()->json([
            'orders' => $ordersStats,
            'chart_data' => $chartData,
            'sales' => [
                'revenue' => $revenue,
                'commissions' => $commissions,
                'orders_cost' => $ordersCost,
                'net_profit' => $netProfit,
            ],
            'users' => [
                'marketers' => User::where('role', 'marketer')->count(),
                'confirmatrices' => User::where('role', 'confirmatrice')->count(),
            ],
            'products' => Product::where('status', 'active')->count(),
            'pending_payouts' => (clone $walletQuery)->where('type', 'withdrawal')->where('status', 'pending')->count(),
            'top_marketers' => User::where('role', 'marketer')
                ->withCount(['marketerOrders as delivered_orders_count' => fn ($q) => $q->where('status', 'delivered')
                    ->when($startDate, fn($sq) => $sq->whereDate('created_at', '>=', $startDate))
                    ->when($endDate, fn($sq) => $sq->whereDate('created_at', '<=', $endDate))
                ])
                ->withSum(['walletTransactions as total_commission' => fn ($q) => $q->where('type', 'commission')->where('status', 'approved')
                    ->when($startDate, fn($sq) => $sq->whereDate('created_at', '>=', $startDate))
                    ->when($endDate, fn($sq) => $sq->whereDate('created_at', '<=', $endDate))
                ], 'amount')
                ->withSum(['walletTransactions as total_return_fees' => fn ($q) => $q->where('type', 'return_fee')->where('status', 'approved')
                    ->when($startDate, fn($sq) => $sq->whereDate('created_at', '>=', $startDate))
                    ->when($endDate, fn($sq) => $sq->whereDate('created_at', '<=', $endDate))
                ], 'amount')
                ->get(['id', 'name', 'email', 'tier'])
                ->map(function ($user) {
                    $user->net_balance = (float)$user->total_commission - (float)$user->total_return_fees;
                    return $user;
                })
                ->sortByDesc('net_balance')
                ->take(5)
                ->values(),
        ]);
    }

}
