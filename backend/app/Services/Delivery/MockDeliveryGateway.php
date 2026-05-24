<?php

namespace App\Services\Delivery;

use App\Models\Order;

class MockDeliveryGateway implements DeliveryGateway
{
    public function calculateCost(string $wilaya, string $commune, string $deliveryType = 'home'): float
    {
        // Mock cost logic
        $base = ($wilaya === 'Alger') ? 400.0 : 800.0;
        return $deliveryType === 'desk' ? $base - 200.0 : $base;
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
