<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Order;
use App\Models\ProductVariant;
use App\Services\Delivery\DeliveryGateway;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;

class OrderController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $orders = $request->user()->marketerOrders()
            ->with(['items', 'returnFeeTransaction'])
            ->when($request->query('status'), fn ($q, $status) => $q->where('status', $status))
            ->when($request->query('search'), function ($q, $search) {
                $q->where(function($sq) use ($search) {
                    $sq->where('reference', 'like', "%{$search}%")
                       ->orWhere('client_name', 'like', "%{$search}%")
                       ->orWhere('client_phone', 'like', "%{$search}%");
                });
            })
            ->latest()
            ->paginate((int) $request->query('per_page', 20));

        return response()->json($orders);
    }

    public function store(Request $request, DeliveryGateway $delivery): JsonResponse
    {
        $data = $request->validate([
            'client_name' => ['required', 'string', 'max:255'],
            'client_phone' => ['required', 'string', 'max:20'],
            'wilaya' => ['required', 'string', 'max:80'],
            'commune' => ['required', 'string', 'max:120'],
            'address' => ['nullable', 'string'],
            'delivery_type' => ['required', 'in:home,desk'],
            'items' => ['required', 'array', 'min:1'],
            'items.*.product_variant_id' => ['required', 'exists:product_variants,id'],
            'items.*.quantity' => ['required', 'integer', 'min:1'],
            'notes' => ['nullable', 'string'],
        ]);

        $order = DB::transaction(function () use ($request, $data, $delivery) {
            $subtotal = 0;
            $commission = 0;
            $preparedItems = [];

            foreach ($data['items'] as $item) {
                $variant = ProductVariant::with('product')->lockForUpdate()->findOrFail($item['product_variant_id']);

                if ($variant->stock < $item['quantity'] || $variant->status !== 'active') {
                    abort(422, "Insufficient stock for SKU {$variant->sku}.");
                }

                $lineTotal = (float) $variant->sale_price * $item['quantity'];
                $lineCommission = $variant->commissionFor($item['quantity']);
                $subtotal += $lineTotal;
                $commission += $lineCommission;
                $variant->decrement('stock', $item['quantity']);

                $preparedItems[] = [
                    'product_variant_id' => $variant->id,
                    'product_name' => $variant->product->name,
                    'sku' => $variant->sku,
                    'quantity' => $item['quantity'],
                    'unit_price' => $variant->sale_price,
                    'unit_commission' => round($lineCommission / $item['quantity'], 2),
                    'line_total' => $lineTotal,
                ];
            }

            $shippingFee = $delivery->calculateCost($data['wilaya'], $data['commune'], $data['delivery_type']);
            $duplicate = Order::where('client_phone', $data['client_phone'])
                ->whereIn('status', [Order::STATUS_PENDING, Order::STATUS_CONFIRMED, Order::STATUS_SHIPPED])
                ->exists();

            $order = Order::create([
                'reference' => 'ORD-'.now()->format('Ymd').'-'.Str::upper(Str::random(6)),
                'marketer_id' => $request->user()->id,
                'client_name' => $data['client_name'],
                'client_phone' => $data['client_phone'],
                'wilaya' => $data['wilaya'],
                'commune' => $data['commune'],
                'address' => $data['address'] ?? null,
                'delivery_type' => $data['delivery_type'],
                'subtotal' => $subtotal,
                'shipping_fee' => $shippingFee,
                'total' => $subtotal + $shippingFee,
                'marketer_commission' => $commission,
                'status' => Order::STATUS_PENDING,
                'is_duplicate' => $duplicate,
                'notes' => $data['notes'] ?? null,
            ]);

            $order->items()->createMany($preparedItems);

            return $order;
        });

        return response()->json(['message' => 'Order created successfully', 'order' => $order], 201);
    }

    public function show(Request $request, Order $order): JsonResponse
    {
        abort_unless($order->marketer_id === $request->user()->id, 403);

        return response()->json($order->load('items'));
    }

    public function cancel(Request $request, Order $order): JsonResponse
    {
        if ($order->marketer_id !== $request->user()->id) {
            abort(403, 'Unauthorized action.');
        }

        if ($order->status !== Order::STATUS_PENDING) {
            return response()->json(['message' => 'Only pending orders can be cancelled.'], 422);
        }

        $order->update(['status' => Order::STATUS_CANCELLED]);

        return response()->json(['message' => 'Order cancelled successfully', 'order' => $order]);
    }
}
