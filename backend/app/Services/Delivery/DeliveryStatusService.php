<?php

namespace App\Services\Delivery;

use App\Models\DeliveryShipment;
use App\Models\Order;

class DeliveryStatusService
{
    public function __construct(private readonly DeliveryGateway $delivery)
    {
    }

    public function sync(Order $order): Order
    {
        if (!$order->tracking_number) {
            return $order->loadMissing('deliveryShipment');
        }

        $tracking = $this->delivery->track($order->tracking_number);

        $deliveryStatus = $tracking['status'] ?? $order->delivery_status;
        $status = $order->status; // Keep current by default

        // Map delivery status to main status
        if (in_array($deliveryStatus, ['livre', 'encaisse', 'recouvert'])) {
            $status = Order::STATUS_DELIVERED;
        } elseif (in_array($deliveryStatus, ['en_retour', 'retourne', 'reinjecte_stock', 'commande_annulee'])) {
            if ($this->isExemptReturn($tracking['raw'] ?? null)) {
                $status = Order::STATUS_RETURN_EXEMPT;
            } else {
                $status = Order::STATUS_RETURN_CHARGED;
            }
        } elseif ($deliveryStatus === 'sortie_en_livraison' && $this->hasPostponedSituation($tracking['raw'] ?? null)) {
            $status = Order::STATUS_REPORTE;
        } elseif (in_array($deliveryStatus, ['pret_a_expedier', 'confirme_au_bureau', 'dispatch', 'vers_wilaya', 'en_livraison', 'sortie_en_livraison'])) {
            $status = Order::STATUS_SHIPPED;
        }

        $updateData = [
            'delivery_status' => $deliveryStatus,
            'delivery_current_location' => $tracking['location'] ?: $order->delivery_current_location,
            'delivery_last_synced_at' => now(),
        ];

        if ($status !== $order->status) {
            $updateData['status'] = $status;
            if ($status === Order::STATUS_CONFIRMED && !$order->confirmed_at) {
                $updateData['confirmed_at'] = now();
            } elseif ($status === Order::STATUS_SHIPPED && !$order->shipped_at) {
                $updateData['shipped_at'] = now();
            } elseif ($status === Order::STATUS_DELIVERED && !$order->delivered_at) {
                $updateData['delivered_at'] = now();
            } elseif (in_array($status, [Order::STATUS_RETURN_CHARGED, Order::STATUS_RETURN_EXEMPT]) && !$order->failed_at) {
                $updateData['failed_at'] = now();
            }
        }

        $order->update($updateData);

        DeliveryShipment::updateOrCreate(
            ['order_id' => $order->id, 'tracking_number' => $order->tracking_number],
            [
                'provider' => 'zr_express',
                'external_id' => $order->tracking_number,
                'status' => $deliveryStatus ?? 'unknown',
                'payload' => $tracking,
                'last_synced_at' => now(),
            ]
        );

        // Commission & Return Fee updating
        $wallet = app(\App\Services\Wallet\WalletService::class);
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

        return $order->refresh()->load(['items', 'marketer', 'confirmatrice', 'deliveryShipment']);
    }

    private function isExemptReturn(?array $raw): bool
    {
        if (!$raw) {
            return false;
        }

        $json = json_encode($raw);

        // Keywords for: Ne répond pas 3 / appel sans réponse
        $hasNoAnswer = false;
        if (
            str_contains($json, 'appel_sans_reponse') ||
            str_contains($json, 'sans_reponse') ||
            str_contains($json, 'ne_repond_pas_3') ||
            str_contains($json, 'ne_repond_pas3') ||
            str_contains($json, 'sans reponse') ||
            str_contains($json, 'ne répond pas 3') ||
            str_contains($json, 'ne repond pas 3')
        ) {
            $hasNoAnswer = true;
        }

        // Keywords for: produit endommagé / damaged
        $hasDamaged = false;
        if (
            str_contains($json, 'produit_endommage') ||
            str_contains($json, 'produit_endommagee') ||
            str_contains($json, 'produit endommagé') ||
            str_contains($json, 'produit endommage') ||
            str_contains($json, 'endommage') ||
            str_contains($json, 'damaged')
        ) {
            $hasDamaged = true;
        }

        return $hasNoAnswer || $hasDamaged;
    }

    private function hasPostponedSituation(?array $raw): bool
    {
        if (!$raw) {
            return false;
        }
        $json = json_encode($raw);
        return str_contains(mb_strtolower($json), 'reporte') || str_contains(mb_strtolower($json), 'reporté') || str_contains(mb_strtolower($json), 'postponed');
    }
}
