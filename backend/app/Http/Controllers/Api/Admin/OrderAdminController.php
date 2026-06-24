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
            Order::with(['items.variant.product', 'marketer', 'confirmatrice', 'deliveryShipment'])
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
            'status' => ['required', 'in:pending,confirmed,shipped,delivered,retour_facture,retour_exonere,cancelled,appel_1,appel_2,appel_3,reporte'],
            'delivery_status' => ['nullable', 'string', 'max:80'],
            'notes' => ['nullable', 'string'],
            'postponed_until' => ['nullable', 'date', 'after_or_equal:today'],
            'shipping_method' => ['nullable', 'string'],
        ]);

        if ($data['status'] === 'reporte' && empty($data['postponed_until'])) {
            return response()->json(['message' => 'A postpone date is required when setting status to Reporté.'], 422);
        }

        // Transition validation removed
        $timestamps = match ($data['status']) {
            'confirmed' => ['confirmed_at' => now()],
            'shipped' => ['shipped_at' => now()],
            'delivered' => ['delivered_at' => now()],
            Order::STATUS_RETURN_CHARGED, Order::STATUS_RETURN_EXEMPT => ['failed_at' => now()],
            default => [],
        };

        $order->update(array_merge([
            'status' => $data['status'],
            'delivery_status' => $data['delivery_status'] ?? $order->delivery_status,
            'notes' => $data['notes'] ?? $order->notes,
            'postponed_until' => $data['status'] === 'reporte' ? $data['postponed_until'] : null,
        ], $timestamps));

        if ($order->status === 'shipped' && !$order->tracking_number) {
            $shippingMethod = $data['shipping_method'] ?? null;
            if ($shippingMethod !== 'self_shipping') {
                $shipment = $delivery->createShipment($order);
                $order->update(['tracking_number' => $shipment['tracking_number'], 'delivery_status' => $shipment['status']]);
                DeliveryShipment::create(['order_id' => $order->id] + $shipment);
            }
        }

        if ($order->status === Order::STATUS_DELIVERED) {
            $wallet->createCommission($order);
        } else {
            $wallet->cancelCommission($order);
        }

        if ($order->status === Order::STATUS_RETURN_CHARGED) {
            $wallet->createReturnFee($order);
        } else {
            $wallet->cancelReturnFee($order);
        }

        return response()->json($order->load(['items.variant.product', 'commissionTransaction', 'deliveryShipment']));
    }

    public function update(Request $request, Order $order, DeliveryGateway $delivery): JsonResponse
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

        $hasTracking = !empty($order->tracking_number);
        $externalId = null;

        if ($hasTracking) {
            try {
                $tracking = $delivery->track($order->tracking_number);
                $zrStatus = $tracking['status'] ?? 'unknown';
            } catch (\Exception $e) {
                $zrStatus = $order->delivery_status;
            }

            $deliveryStates = [
                'confirme_au_bureau',
                'dispatch',
                'vers_wilaya',
                'en_livraison',
                'sortie_en_livraison',
                'livre',
                'encaisse',
                'recouvert',
                'en_retour',
                'retourne',
                'reinjecte_stock'
            ];

            if (in_array($zrStatus, $deliveryStates)) {
                return response()->json(['message' => 'La commande est déjà en cours de livraison et ne peut plus être modifiée.'], 422);
            }

            $externalId = $order->deliveryShipment->external_id ?? $order->tracking_number;
        }

        $updateData = [];
        if (isset($data['client_name'])) $updateData['client_name'] = $data['client_name'];
        if (isset($data['client_phone'])) $updateData['client_phone'] = $data['client_phone'];
        if (isset($data['address'])) $updateData['address'] = $data['address'];
        if (isset($data['notes'])) $updateData['notes'] = $data['notes'];

        $deliveryType = $data['delivery_type'] ?? $order->delivery_type;
        $updateData['delivery_type'] = $deliveryType;

        if (!empty($data['wilaya']) || !empty($data['commune'])) {
            $wilayaInput = $data['wilaya'] ?? $order->wilaya;
            $communeInput = $data['commune'] ?? $order->commune;

            $code = null;
            $name = $wilayaInput;
            if (str_contains($wilayaInput, ' - ')) {
                $parts = explode(' - ', $wilayaInput, 2);
                $code = trim($parts[0]);
                $name = trim($parts[1]);
            }

            $rateQuery = \App\Models\ShippingRate::query();
            if ($code) {
                $rateQuery->where('wilaya_code', $code);
            } else {
                $rateQuery->where('wilaya_name', $name)->orWhere('wilaya_name_ar', $name);
            }
            $shippingRate = $rateQuery->first();

            if (!$shippingRate) {
                return response()->json(['message' => "La wilaya sélectionnée n'est pas valide."], 422);
            }

            // Check commune exists
            $communeExists = $shippingRate->communes()
                ->where(function ($q) use ($communeInput) {
                    $q->where('name', $communeInput)
                      ->orWhere('name_ar', $communeInput);
                })->exists();

            if (!$communeExists) {
                return response()->json(['message' => "La commune sélectionnée n'appartient pas à la wilaya choisie."], 422);
            }

            $updateData['wilaya'] = $wilayaInput;
            $updateData['commune'] = $communeInput;

            $shippingFee = $deliveryType === 'home' ? (float) $shippingRate->home_price : (float) $shippingRate->desk_price;
            $updateData['shipping_fee'] = $shippingFee;
            $updateData['total'] = $order->subtotal + $shippingFee;
        } else if (isset($data['delivery_type'])) {
            // Recalculate shipping fee based on existing wilaya
            $wilayaInput = $order->wilaya;
            $code = null;
            $name = $wilayaInput;
            if (str_contains($wilayaInput, ' - ')) {
                $parts = explode(' - ', $wilayaInput, 2);
                $code = trim($parts[0]);
                $name = trim($parts[1]);
            }
            $rateQuery = \App\Models\ShippingRate::query();
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

        // Cancel shipment if old one exists
        if ($hasTracking && $externalId) {
            try {
                $delivery->cancelShipment($externalId);
            } catch (\Exception $e) {
                // Ignore if not found or failed
            }
            $order->deliveryShipment()->delete();
        }

        $order->update($updateData);

        // Recreate shipment with updated details
        if ($hasTracking) {
            $shipment = $delivery->createShipment($order);
            $order->update([
                'tracking_number' => $shipment['tracking_number'],
                'delivery_status' => $shipment['status']
            ]);
            DeliveryShipment::create(['order_id' => $order->id] + $shipment);
        }

        return response()->json($order->load(['items.variant.product', 'commissionTransaction', 'deliveryShipment']));
    }

    public function destroy(Order $order, DeliveryGateway $delivery): JsonResponse
    {
        if (!empty($order->tracking_number)) {
            try {
                $tracking = $delivery->track($order->tracking_number);
                $zrStatus = $tracking['status'] ?? 'unknown';
            } catch (\Exception $e) {
                $zrStatus = $order->delivery_status;
            }

            $deliveryStates = [
                'confirme_au_bureau',
                'dispatch',
                'vers_wilaya',
                'en_livraison',
                'sortie_en_livraison',
                'livre',
                'encaisse',
                'recouvert',
                'en_retour',
                'retourne',
                'reinjecte_stock'
            ];

            if (in_array($zrStatus, $deliveryStates)) {
                return response()->json(['message' => 'La commande est déjà en cours de livraison et ne peut pas être supprimée.'], 422);
            }

            $externalId = $order->deliveryShipment->external_id ?? $order->tracking_number;
            try {
                $delivery->cancelShipment($externalId);
            } catch (\Exception $e) {
                // Ignore
            }
            $order->deliveryShipment()->delete();
        }

        // Clean up database records
        $order->items()->delete();
        \App\Models\WalletTransaction::where('order_id', $order->id)->delete();
        $order->delete();

        return response()->json(['message' => 'Commande supprimée avec succès.']);
    }

    public function bulkShip(Request $request, DeliveryGateway $delivery): JsonResponse
    {
        $data = $request->validate([
            'ids' => ['required', 'array'],
            'ids.*' => ['exists:orders,id'],
        ]);

        $successCount = 0;
        $errors = [];

        $orders = Order::whereIn('id', $data['ids'])->get();

        foreach ($orders as $order) {
            if ($order->tracking_number) {
                $errors[$order->id] = "La commande a déjà un numéro de suivi.";
                continue;
            }

            try {
                $shipment = $delivery->createShipment($order);

                $order->update([
                    'status' => Order::STATUS_SHIPPED,
                    'shipped_at' => now(),
                    'tracking_number' => $shipment['tracking_number'],
                    'delivery_status' => $shipment['status'],
                    'delivery_last_synced_at' => now(),
                ]);

                DeliveryShipment::create(['order_id' => $order->id] + $shipment);
                $successCount++;
            } catch (\Exception $e) {
                $errors[$order->id] = $e->getMessage();
            }
        }

        return response()->json([
            'success_count' => $successCount,
            'errors' => $errors,
        ]);
    }

    public function bulkDelete(Request $request, DeliveryGateway $delivery): JsonResponse
    {
        $data = $request->validate([
            'ids' => ['required', 'array'],
            'ids.*' => ['exists:orders,id'],
        ]);

        $successCount = 0;
        $errors = [];

        $orders = Order::whereIn('id', $data['ids'])->get();

        $deliveryStates = [
            'confirme_au_bureau',
            'dispatch',
            'vers_wilaya',
            'en_livraison',
            'sortie_en_livraison',
            'livre',
            'encaisse',
            'recouvert',
            'en_retour',
            'retourne',
            'reinjecte_stock'
        ];

        foreach ($orders as $order) {
            if (!empty($order->tracking_number)) {
                try {
                    $tracking = $delivery->track($order->tracking_number);
                    $zrStatus = $tracking['status'] ?? 'unknown';
                } catch (\Exception $e) {
                    $zrStatus = $order->delivery_status;
                }

                if (in_array($zrStatus, $deliveryStates)) {
                    $errors[$order->id] = "La commande est déjà en cours de livraison (Statut ZR: {$zrStatus}) et ne peut pas être supprimée.";
                    continue;
                }

                $externalId = $order->deliveryShipment->external_id ?? $order->tracking_number;
                try {
                    $delivery->cancelShipment($externalId);
                } catch (\Exception $e) {
                    // Ignore
                }
                $order->deliveryShipment()->delete();
            }

            // Clean up DB records
            $order->items()->delete();
            \App\Models\WalletTransaction::where('order_id', $order->id)->delete();
            $order->delete();
            $successCount++;
        }

        return response()->json([
            'success_count' => $successCount,
            'errors' => $errors,
        ]);
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
