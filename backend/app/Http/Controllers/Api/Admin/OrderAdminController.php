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
    // Validations removed to allow arbitrary status transitions by admin/confirmatrice
    public function index(Request $request): JsonResponse
    {
        return response()->json(
            Order::with(['items', 'marketer', 'confirmatrice', 'deliveryShipment'])
                ->when($request->query('status'), fn ($q, $status) => $q->where('status', $status))
                ->when($request->query('confirmatrice_id'), fn ($q, $id) => $q->where('confirmatrice_id', $id))
                ->when($request->query('search'), function ($q, $search) {
                    $q->where(function($sq) use ($search) {
                        $sq->where('reference', 'like', "%{$search}%")
                           ->orWhere('client_name', 'like', "%{$search}%")
                           ->orWhere('client_phone', 'like', "%{$search}%")
                           ->orWhereHas('marketer', fn($mq) => $mq->where('name', 'like', "%{$search}%"));
                    });
                })
                ->latest()
                ->paginate((int) $request->query('per_page', 20))
        );
    }

    public function updateStatus(Request $request, Order $order, WalletService $wallet, DeliveryGateway $delivery): JsonResponse
    {
        $data = $request->validate([
            'status' => ['required', 'in:pending,confirmed,shipped,delivered,failed,cancelled,appel_1,appel_2,appel_3,reporte'],
            'delivery_status' => ['nullable', 'string', 'max:80'],
            'notes' => ['nullable', 'string'],
            'postponed_until' => ['nullable', 'date', 'after_or_equal:today'],
        ]);

        if ($data['status'] === 'reporte' && empty($data['postponed_until'])) {
            return response()->json(['message' => 'A postpone date is required when setting status to Reporté.'], 422);
        }

        // Transition validation removed
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
            'postponed_until' => $data['status'] === 'reporte' ? $data['postponed_until'] : null,
        ], $timestamps));

        if ($order->status === 'shipped' && !$order->tracking_number) {
            $shipment = $delivery->createShipment($order);
            $order->update(['tracking_number' => $shipment['tracking_number'], 'delivery_status' => $shipment['status']]);
            DeliveryShipment::create(['order_id' => $order->id] + $shipment);
        }

        if ($order->status === Order::STATUS_DELIVERED) {
            $wallet->createCommission($order);
        } else {
            $wallet->cancelCommission($order);
        }

        if (in_array($order->status, [Order::STATUS_FAILED])) {
            $wallet->createReturnFee($order);
        } else {
            $wallet->cancelReturnFee($order);
        }

        return response()->json($order->load(['items', 'commissionTransaction', 'deliveryShipment']));
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
