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

        // 1. If we have history, check comments and situations in the history transitions
        if (!empty($raw['history']) && is_array($raw['history'])) {
            foreach ($raw['history'] as $transition) {
                $commentsToCheck = [];
                
                if (!empty($transition['comment'])) {
                    $commentsToCheck[] = $transition['comment'];
                }
                
                if (!empty($transition['situations']) && is_array($transition['situations'])) {
                    foreach ($transition['situations'] as $sit) {
                        if (!empty($sit['comment'])) {
                            $commentsToCheck[] = $sit['comment'];
                        }
                        if (!empty($sit['slug'])) {
                            $commentsToCheck[] = $sit['slug'];
                        }
                        if (!empty($sit['name'])) {
                            $commentsToCheck[] = $sit['name'];
                        }
                    }
                }

                foreach ($commentsToCheck as $text) {
                    if ($this->matchesExemptKeywords($text)) {
                        return true;
                    }
                }
            }
        }

        // 2. Fallback: check the rest of the raw payload (excluding description/notes/orderedProducts/history to avoid false matches)
        $fallbackData = $raw;
        unset($fallbackData['description'], $fallbackData['notes'], $fallbackData['orderedProducts'], $fallbackData['history']);
        
        $json = json_encode($fallbackData);
        return $this->matchesExemptKeywords($json);
    }

    private function matchesExemptKeywords(string $text): bool
    {
        $text = mb_strtolower($text, 'UTF-8');

        // Keywords for: faux commande (fake order)
        $hasFakeOrder = (
            str_contains($text, 'faux_commande') ||
            str_contains($text, 'fausse_commande') ||
            str_contains($text, 'faux commande') ||
            str_contains($text, 'fausse commande')
        );

        // Keywords for: produit endommagé / damaged / endomager
        $hasDamaged = (
            str_contains($text, 'produit_endommage') ||
            str_contains($text, 'produit_endommagee') ||
            str_contains($text, 'produit endommagé') ||
            str_contains($text, 'produit endommage') ||
            str_contains($text, 'endommage') ||
            str_contains($text, 'damaged') ||
            str_contains($text, 'endomager') ||
            str_contains($text, 'produit_endomager') ||
            str_contains($text, 'produit endomager')
        );

        return $hasFakeOrder || $hasDamaged;
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
