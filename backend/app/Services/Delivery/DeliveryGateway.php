<?php

namespace App\Services\Delivery;

use App\Models\Order;

interface DeliveryGateway
{
    public function calculateCost(string $wilaya, string $commune, string $deliveryType = 'home'): float;

    public function createShipment(Order $order): array;

    public function track(string $trackingNumber): array;
}
