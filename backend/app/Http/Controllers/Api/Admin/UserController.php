<?php

namespace App\Http\Controllers\Api\Admin;

use App\Http\Controllers\Controller;
use App\Models\OrderItem;
use App\Models\User;
use App\Services\Wallet\WalletService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class UserController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        return response()->json(
            User::query()
                ->when($request->query('role'), fn ($q, $role) => $q->where('role', $role))
                ->when($request->query('status'), fn ($q, $status) => $q->where('status', $status))
                ->latest()
                ->paginate((int) $request->query('per_page', 20))
        );
    }

    public function store(Request $request): JsonResponse
    {
        $data = $request->validate([
            'name' => ['required', 'string', 'max:255'],
            'email' => ['required', 'email', 'unique:users,email'],
            'phone' => ['nullable', 'string', 'max:40'],
            'role' => ['required', 'in:admin,marketer,confirmatrice'],
            'tier' => ['nullable', 'string', 'max:80'],
            'password' => ['required', 'string', 'min:8'],
        ]);

        return response()->json(User::create($data), 201);
    }

    public function update(Request $request, User $user): JsonResponse
    {
        $data = $request->validate([
            'name' => ['sometimes', 'string', 'max:255'],
            'email' => ['sometimes', 'email', 'unique:users,email,'.$user->id],
            'phone' => ['sometimes', 'nullable', 'string', 'max:40'],
            'role' => ['sometimes', 'in:admin,marketer,confirmatrice'],
            'tier' => ['sometimes', 'string', 'max:80'],
            'status' => ['sometimes', 'in:active,suspended'],
            'password' => ['sometimes', 'string', 'min:8'],
            'profile' => ['sometimes', 'array'],
        ]);

        if (($data['status'] ?? null) === 'suspended') {
            $data['suspended_at'] = now();
        } elseif (($data['status'] ?? null) === 'active') {
            $data['suspended_at'] = null;
        }

        $user->update($data);

        return response()->json($user);
    }

    public function stats(Request $request, User $user, WalletService $wallet): JsonResponse
    {
        if ($user->role !== 'marketer') {
            abort(404, 'User is not a marketer');
        }

        $totalOrders = $user->marketerOrders()->count();
        $deliveredOrders = $user->marketerOrders()->where('status', 'delivered')->count();

        $topProducts = OrderItem::query()
            ->join('orders', 'order_items.order_id', '=', 'orders.id')
            ->where('orders.marketer_id', $user->id)
            ->select('product_name', DB::raw('SUM(order_items.quantity) as sales'))
            ->groupBy('product_name')
            ->orderByDesc('sales')
            ->limit(5)
            ->get();

        $balance = $wallet->balanceFor($user);
        $recentEarnings = $user->walletTransactions()
            ->whereIn('type', ['commission', 'return_fee'])
            ->where('status', 'approved')
            ->with('order:id,reference')
            ->latest()
            ->limit(5)
            ->get();

        return response()->json([
            'performance' => [
                'total_orders' => $totalOrders,
                'delivered_orders' => $deliveredOrders,
                'conversion_rate' => $totalOrders > 0 ? round(($deliveredOrders / $totalOrders) * 100, 2) : 0,
                'top_products' => $topProducts,
            ],
            'commissions' => [
                'unpaid_balance' => $balance['available'],
                'recent_earnings' => $recentEarnings->map(fn ($t) => [
                    'id' => $t->id,
                    'type' => $t->type,
                    'order_reference' => $t->order->reference ?? 'Unknown',
                    'amount' => $t->type === 'return_fee' ? -((float) $t->amount) : (float) $t->amount,
                    'date' => clone $t->created_at, // Map to string later in frontend
                ]),
            ],
        ]);
    }
}
