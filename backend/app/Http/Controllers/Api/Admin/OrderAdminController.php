<?php

namespace App\Http\Controllers\Api\Admin;

use App\Http\Controllers\Controller;
use App\Models\DeliveryShipment;
use App\Models\Order;
use App\Models\User;
use App\Services\Delivery\DeliveryGateway;
use App\Services\Wallet\WalletService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class OrderAdminController extends Controller
{
    private const TRANSITIONS = [
        'pending' => ['confirmed', 'cancelled'],
        'confirmed' => ['shipped', 'cancelled'],
        'shipped' => ['delivered', 'failed', 'cancelled'],
        'delivered' => [],
        'failed' => [],
        'cancelled' => [],
    ];

    public function index(Request $request): JsonResponse
    {
        return response()->json(
            Order::with(['items', 'marketer', 'confirmatrice'])
                ->when($request->query('status'), fn ($q, $status) => $q->where('status', $status))
                ->when($request->query('confirmatrice_id'), fn ($q, $id) => $q->where('confirmatrice_id', $id))
                ->latest()
                ->paginate((int) $request->query('per_page', 20))
        );
    }

    public function updateStatus(Request $request, Order $order, WalletService $wallet, DeliveryGateway $delivery): JsonResponse
    {
        $data = $request->validate([
            'status' => ['required', 'in:pending,confirmed,shipped,delivered,failed,cancelled'],
            'delivery_status' => ['nullable', 'string', 'max:80'],
            'notes' => ['nullable', 'string'],
        ]);

        if (!in_array($data['status'], self::TRANSITIONS[$order->status] ?? [], true) && $data['status'] !== $order->status) {
            return response()->json(['message' => 'Invalid status transition'], 422);
        }

        $timestamps = match ($data['status']) {
            'confirmed' => ['confirmed_at' => now()],
            'shipped' => ['shipped_at' => now()],
            'delivered' => ['delivered_at' => now()],
            'failed' => ['failed_at' => now()],
            default => [],
        };

        $order->update(array_merge([
            'status' => $data['status'],
            'delivery_status' => $data['delivery_status'] ?? $order->delivery_status,
            'notes' => $data['notes'] ?? $order->notes,
        ], $timestamps));

        if ($order->status === 'shipped' && !$order->tracking_number) {
            $shipment = $delivery->createShipment($order);
            $order->update(['tracking_number' => $shipment['tracking_number'], 'delivery_status' => $shipment['status']]);
            DeliveryShipment::create(['order_id' => $order->id] + $shipment);
        }

        if ($order->status === Order::STATUS_DELIVERED) {
            $wallet->createCommission($order);
        }

        return response()->json($order->load(['items', 'commissionTransaction']));
    }

    public function assignConfirmatrice(Request $request, Order $order): JsonResponse
    {
        $data = $request->validate([
            'confirmatrice_id' => ['required', 'exists:users,id'],
        ]);

        $confirmatrice = User::where('role', 'confirmatrice')->findOrFail($data['confirmatrice_id']);
        $order->update(['confirmatrice_id' => $confirmatrice->id]);

        return response()->json($order->load('confirmatrice'));
    }
}
