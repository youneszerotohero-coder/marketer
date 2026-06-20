<?php

namespace App\Http\Controllers\Api\Admin;

use App\Http\Controllers\Controller;
use App\Models\DeliveryShipment;
use App\Models\Order;
use App\Models\ShippingRate;
use App\Models\User;
use App\Services\Delivery\DeliveryGateway;
use App\Services\Wallet\WalletService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;

class OrderAdminController extends Controller
{
    // Validations removed to allow arbitrary status transitions by admin/confirmatrice
    public function index(Request $request): JsonResponse
    {
        return response()->json(
            Order::with(['items.variant.product', 'marketer', 'confirmatrice', 'deliveryShipment'])
                ->when($request->query('status'), fn ($q, $status) => $q->where('status', $status))
                ->when($request->query('confirmatrice_id'), fn ($q, $id) => $q->where('confirmatrice_id', $id))
                ->when($request->query('search'), function ($q, $search) {
                    $q->where(function ($sq) use ($search) {
                        $sq->where('reference', 'like', "%{$search}%")
                            ->orWhere('client_name', 'like', "%{$search}%")
                            ->orWhere('client_phone', 'like', "%{$search}%")
                            ->orWhereHas('marketer', fn ($mq) => $mq->where('name', 'like', "%{$search}%"));
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
            'return_reason' => ['nullable', 'in:customer_refused,broken_product,wrong_address,other'],
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
            'return_reason' => $data['status'] === 'failed' ? ($data['return_reason'] ?? null) : null,
        ], $timestamps));

        if ($order->status === 'shipped' && ! $order->tracking_number) {
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

        return response()->json($order->load(['items.variant.product', 'commissionTransaction', 'deliveryShipment']));
    }

    public function update(Request $request, Order $order): JsonResponse
    {
        $data = $request->validate([
            'client_name' => ['nullable', 'string', 'max:255'],
            'client_phone' => ['nullable', 'string', 'max:20'],
            'wilaya' => ['nullable', 'string', 'max:80'],
            'commune' => ['nullable', 'string', 'max:120'],
            'address' => ['nullable', 'string'],
            'delivery_type' => ['nullable', 'in:home,desk'],
            'notes' => ['nullable', 'string'],
        ]);

        $updateData = [];
        if (isset($data['client_name'])) {
            $updateData['client_name'] = $data['client_name'];
        }
        if (isset($data['client_phone'])) {
            $updateData['client_phone'] = $data['client_phone'];
        }
        if (isset($data['address'])) {
            $updateData['address'] = $data['address'];
        }
        if (isset($data['notes'])) {
            $updateData['notes'] = $data['notes'];
        }

        $deliveryType = $data['delivery_type'] ?? $order->delivery_type;
        $updateData['delivery_type'] = $deliveryType;

        if (! empty($data['wilaya']) || ! empty($data['commune'])) {
            $wilayaInput = $data['wilaya'] ?? $order->wilaya;
            $communeInput = $data['commune'] ?? $order->commune;

            $code = null;
            $name = $wilayaInput;
            if (str_contains($wilayaInput, ' - ')) {
                $parts = explode(' - ', $wilayaInput, 2);
                $code = trim($parts[0]);
                $name = trim($parts[1]);
            }

            $rateQuery = ShippingRate::query();
            if ($code) {
                $rateQuery->where('wilaya_code', $code);
            } else {
                $rateQuery->where('wilaya_name', $name)->orWhere('wilaya_name_ar', $name);
            }
            $shippingRate = $rateQuery->first();

            if (! $shippingRate) {
                return response()->json(['message' => "La wilaya sélectionnée n'est pas valide."], 422);
            }

            // Let's check commune exists
            $communeExists = $shippingRate->communes()
                ->where(function ($q) use ($communeInput) {
                    $q->where('name', $communeInput)
                        ->orWhere('name_ar', $communeInput);
                })->exists();

            if (! $communeExists) {
                return response()->json(['message' => "La commune sélectionnée n'appartient pas à la wilaya choisie."], 422);
            }

            $updateData['wilaya'] = $wilayaInput;
            $updateData['commune'] = $communeInput;

            $shippingFee = $deliveryType === 'home' ? (float) $shippingRate->home_price : (float) $shippingRate->desk_price;
            $updateData['shipping_fee'] = $shippingFee;
            $updateData['total'] = $order->subtotal + $shippingFee;
        } elseif (isset($data['delivery_type'])) {
            // Recalculate shipping fee based on existing wilaya
            $wilayaInput = $order->wilaya;
            $code = null;
            $name = $wilayaInput;
            if (str_contains($wilayaInput, ' - ')) {
                $parts = explode(' - ', $wilayaInput, 2);
                $code = trim($parts[0]);
                $name = trim($parts[1]);
            }
            $rateQuery = ShippingRate::query();
            if ($code) {
                $rateQuery->where('wilaya_code', $code);
            } else {
                $rateQuery->where('wilaya_name', $name)->orWhere('wilaya_name_ar', $name);
            }
            $shippingRate = $rateQuery->first();
            if ($shippingRate) {
                $shippingFee = $deliveryType === 'home' ? (float) $shippingRate->home_price : (float) $shippingRate->desk_price;
                $updateData['shipping_fee'] = $shippingFee;
                $updateData['total'] = $order->subtotal + $shippingFee;
            }
        }

        $order->update($updateData);

        return response()->json($order->load(['items.variant.product', 'commissionTransaction', 'deliveryShipment']));
    }

    public function duplicate(Order $order): JsonResponse
    {
        $order->load('items');

        $newOrder = DB::transaction(function () use ($order) {
            do {
                $reference = 'ORD-'.now()->format('Ymd').'-'.Str::upper(Str::random(6));
            } while (Order::where('reference', $reference)->exists());

            $duplicate = Order::create([
                'reference' => $reference,
                'client_name' => $order->client_name,
                'client_phone' => $order->client_phone,
                'wilaya' => $order->wilaya,
                'commune' => $order->commune,
                'address' => $order->address,
                'delivery_type' => $order->delivery_type,
                'subtotal' => $order->subtotal,
                'shipping_fee' => $order->shipping_fee,
                'total' => $order->total,
                'marketer_commission' => $order->marketer_commission,
                'marketer_id' => $order->marketer_id,
                'notes' => $order->notes,
                'status' => Order::STATUS_PENDING,
            ]);

            $duplicate->items()->createMany($order->items->map(fn ($item) => [
                'product_variant_id' => $item->product_variant_id,
                'product_name' => $item->product_name,
                'sku' => $item->sku,
                'quantity' => $item->quantity,
                'unit_price' => $item->unit_price,
                'unit_commission' => $item->unit_commission,
                'line_total' => $item->line_total,
            ])->all());

            return $duplicate;
        });

        return response()->json($newOrder->load(['items.variant.product']), 201);
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
