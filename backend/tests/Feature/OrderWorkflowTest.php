<?php

namespace Tests\Feature;

use App\Models\Order;
use App\Models\User;
use App\Models\WalletTransaction;
use App\Models\ShippingRate;
use App\Services\Delivery\DeliveryStatusService;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class OrderWorkflowTest extends TestCase
{
    use RefreshDatabase;

    public function test_return_fee_exemption_rules(): void
    {
        $marketer = User::create([
            'name' => 'Test Marketer',
            'email' => 'marketer@test.com',
            'password' => bcrypt('password'),
            'role' => 'marketer',
            'status' => 'active',
        ]);

        // 1. Test Billed Return (retour_facture)
        $order1 = Order::create([
            'reference' => 'ORD-101',
            'marketer_id' => $marketer->id,
            'client_name' => 'Client A',
            'client_phone' => '0550000001',
            'wilaya' => '16 - Alger',
            'commune' => 'Hydra',
            'subtotal' => 1000,
            'shipping_fee' => 400,
            'total' => 1400,
            'status' => 'pending',
        ]);

        $admin = User::create([
            'name' => 'Admin User',
            'email' => 'admin@test.com',
            'password' => bcrypt('password'),
            'role' => 'admin',
            'status' => 'active',
        ]);

        $token = auth('api')->login($admin);

        $response = $this->withHeaders(['Authorization' => "Bearer {$token}"])
            ->patchJson("/api/admin/orders/{$order1->id}/status", [
                'status' => 'retour_facture',
            ]);

        $response->assertStatus(200);
        $this->assertEquals('retour_facture', $order1->fresh()->status);

        // Assert return fee deducted (400)
        $this->assertDatabaseHas('wallet_transactions', [
            'order_id' => $order1->id,
            'type' => 'return_fee',
            'amount' => 400,
            'status' => 'approved',
        ]);

        // 2. Test Exempt Return (retour_exonere)
        $order2 = Order::create([
            'reference' => 'ORD-102',
            'marketer_id' => $marketer->id,
            'client_name' => 'Client B',
            'client_phone' => '0550000002',
            'wilaya' => '16 - Alger',
            'commune' => 'Hydra',
            'subtotal' => 1000,
            'shipping_fee' => 400,
            'total' => 1400,
            'status' => 'pending',
        ]);

        $response2 = $this->withHeaders(['Authorization' => "Bearer {$token}"])
            ->patchJson("/api/admin/orders/{$order2->id}/status", [
                'status' => 'retour_exonere',
            ]);

        $response2->assertStatus(200);
        $this->assertEquals('retour_exonere', $order2->fresh()->status);

        // Assert NO return fee deducted for order 2
        $this->assertDatabaseMissing('wallet_transactions', [
            'order_id' => $order2->id,
            'type' => 'return_fee',
        ]);
    }

    public function test_tracking_sync_status_propagation(): void
    {
        $marketer = User::create([
            'name' => 'Test Marketer',
            'email' => 'marketer@test.com',
            'password' => bcrypt('password'),
            'role' => 'marketer',
            'status' => 'active',
        ]);

        // Create order with tracking
        $order = Order::create([
            'reference' => 'ORD-201',
            'marketer_id' => $marketer->id,
            'client_name' => 'Client C',
            'client_phone' => '0550000003',
            'wilaya' => '16 - Alger',
            'commune' => 'Hydra',
            'subtotal' => 1000,
            'shipping_fee' => 400,
            'total' => 1400,
            'status' => 'shipped',
            'tracking_number' => 'ZR-TEST-201',
        ]);

        // Mock gateway track method to return retourne with history situation having 'comment' => 'faux commande'
        $gateway = $this->createMock(\App\Services\Delivery\DeliveryGateway::class);
        $gateway->method('track')->willReturn([
            'tracking_number' => 'ZR-TEST-201',
            'status' => 'retourne',
            'location' => 'Alger Hub',
            'raw' => [
                'currentState' => [
                    'id' => '123',
                    'name' => 'retourne',
                ],
                'history' => [
                    [
                        'id' => 'hist-1',
                        'newState' => [
                            'id' => '46e1217e-90bb-43f1-b924-a78b4b74e64f',
                            'name' => 'retourne',
                            'description' => 'Retourné',
                        ],
                        'comment' => '',
                        'situations' => [
                            [
                                'id' => 'sit-1',
                                'comment' => 'faux commande',
                                'slug' => 'commande_anullee',
                            ]
                        ]
                    ]
                ]
            ],
        ]);

        $service = new DeliveryStatusService($gateway);
        $service->sync($order);

        // Assert status updated to 'retour_exonere' due to situation comment in history
        $this->assertEquals('retour_exonere', $order->fresh()->status);
        $this->assertDatabaseMissing('wallet_transactions', [
            'order_id' => $order->id,
            'type' => 'return_fee',
        ]);
    }
}
