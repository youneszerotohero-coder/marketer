<?php

namespace App\Services\Delivery;

use App\Models\DeliveryShipment;
use App\Models\Order;

class DeliveryStatusService
{
    public function __construct(private readonly DeliveryGateway $delivery) {}

    public function sync(Order $order): Order
    {
        if (! $order->tracking_number) {
            return $order->loadMissing('deliveryShipment');
        }

        $tracking = $this->delivery->track($order->tracking_number);

        $order->update([
            'delivery_status' => $tracking['status'] ?? $order->delivery_status,
            'delivery_current_location' => $tracking['location'] ?: $order->delivery_current_location,
            'delivery_last_synced_at' => now(),
        ]);

        DeliveryShipment::updateOrCreate(
            ['order_id' => $order->id, 'tracking_number' => $order->tracking_number],
            [
                'provider' => 'zr_express',
                'external_id' => $order->tracking_number,
                'status' => $tracking['status'] ?? 'unknown',
                'payload' => $tracking,
                'last_synced_at' => now(),
            ]
        );

        return $order->refresh()->load(['items', 'marketer', 'confirmatrice', 'deliveryShipment']);
    }
}
