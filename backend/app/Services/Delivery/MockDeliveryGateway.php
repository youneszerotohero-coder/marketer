<?php

namespace App\Services\Delivery;

use App\Models\Order;

class MockDeliveryGateway implements DeliveryGateway
{
    private const TERRITORIES = [
        ['code' => '16', 'name' => 'Alger', 'communes' => ['Hydra', 'El Biar', 'Bab Ezzouar']],
        ['code' => '09', 'name' => 'Blida', 'communes' => ['Blida', 'Boufarik', 'Beni Mered']],
        ['code' => '31', 'name' => 'Oran', 'communes' => ['Oran', 'Es Senia', 'Bir El Djir']],
    ];

    public function calculateCost(string $wilaya, string $commune, string $deliveryType = 'home'): float
    {
        $base = str_contains($wilaya, 'Alger') ? 400.0 : 800.0;
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
            'location' => 'ZR Express Hub',
            'synced_at' => now()->toISOString(),
            'failed' => false,
        ];
    }

    public function territories(): array
    {
        return self::TERRITORIES;
    }

    public function rates(): array
    {
        return [
            ['wilaya' => 'Alger', 'home' => 400, 'desk' => 200],
            ['wilaya' => 'Blida', 'home' => 800, 'desk' => 600],
            ['wilaya' => 'Oran', 'home' => 800, 'desk' => 600],
        ];
    }
}
