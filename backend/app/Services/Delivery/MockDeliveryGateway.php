<?php

namespace App\Services\Delivery;

use App\Models\Order;

class MockDeliveryGateway implements DeliveryGateway
{
    public function calculateCost(string $wilaya, string $commune): float
    {
        return match (true) {
            str_contains(strtolower($wilaya), 'algiers') => 500,
            str_contains(strtolower($wilaya), 'oran') => 700,
            default => 600,
        };
    }

    public function createShipment(Order $order): array
    {
        return [
            'provider' => 'mock',
            'external_id' => 'MOCK-'.$order->reference,
            'tracking_number' => 'TRK-'.$order->reference,
            'status' => 'created',
        ];
    }

    public function track(string $trackingNumber): array
    {
        return [
            'tracking_number' => $trackingNumber,
            'status' => 'in_transit',
            'failed' => false,
        ];
    }
}
