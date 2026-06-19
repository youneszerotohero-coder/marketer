<?php

namespace App\Services\Delivery;

use App\Models\Order;
use App\Models\Setting;
use Illuminate\Support\Arr;
use Illuminate\Support\Facades\Http;
use RuntimeException;

class ZrExpressGateway implements DeliveryGateway
{
    private const FALLBACK_TERRITORIES = [
        ['code' => '01', 'name' => 'Adrar', 'communes' => []],
        ['code' => '02', 'name' => 'Chlef', 'communes' => []],
        ['code' => '03', 'name' => 'Laghouat', 'communes' => []],
        ['code' => '04', 'name' => 'Oum El Bouaghi', 'communes' => []],
        ['code' => '05', 'name' => 'Batna', 'communes' => []],
        ['code' => '06', 'name' => 'Bejaia', 'communes' => []],
        ['code' => '07', 'name' => 'Biskra', 'communes' => []],
        ['code' => '08', 'name' => 'Bechar', 'communes' => []],
        ['code' => '09', 'name' => 'Blida', 'communes' => []],
        ['code' => '10', 'name' => 'Bouira', 'communes' => []],
        ['code' => '11', 'name' => 'Tamanrasset', 'communes' => []],
        ['code' => '12', 'name' => 'Tebessa', 'communes' => []],
        ['code' => '13', 'name' => 'Tlemcen', 'communes' => []],
        ['code' => '14', 'name' => 'Tiaret', 'communes' => []],
        ['code' => '15', 'name' => 'Tizi Ouzou', 'communes' => []],
        ['code' => '16', 'name' => 'Alger', 'communes' => ['Hydra', 'El Biar', 'Bab Ezzouar']],
        ['code' => '31', 'name' => 'Oran', 'communes' => ['Oran', 'Es Senia', 'Bir El Djir']],
    ];

    private const FALLBACK_RATES = [
        ['code' => '01', 'wilaya' => 'Adrar', 'home' => 1200, 'desk' => 800],
        ['code' => '02', 'wilaya' => 'Chlef', 'home' => 600, 'desk' => 400],
        ['code' => '06', 'wilaya' => 'Bejaia', 'home' => 700, 'desk' => 450],
        ['code' => '09', 'wilaya' => 'Blida', 'home' => 450, 'desk' => 250],
        ['code' => '15', 'wilaya' => 'Tizi Ouzou', 'home' => 650, 'desk' => 400],
        ['code' => '16', 'wilaya' => 'Alger', 'home' => 400, 'desk' => 200],
        ['code' => '23', 'wilaya' => 'Annaba', 'home' => 800, 'desk' => 550],
        ['code' => '25', 'wilaya' => 'Constantine', 'home' => 750, 'desk' => 500],
        ['code' => '31', 'wilaya' => 'Oran', 'home' => 600, 'desk' => 400],
        ['code' => '35', 'wilaya' => 'Boumerdes', 'home' => 450, 'desk' => 250],
        ['code' => '39', 'wilaya' => 'El Oued', 'home' => 1100, 'desk' => 750],
        ['code' => '47', 'wilaya' => 'Ghardaia', 'home' => 1000, 'desk' => 700],
    ];

    public function calculateCost(string $wilaya, string $commune, string $deliveryType = 'home'): float
    {
        try {
            $rates = $this->rates();
            $match = collect($rates)->first(function ($rate) use ($wilaya) {
                $name = (string) ($rate['wilaya'] ?? $rate['name'] ?? $rate['territory'] ?? '');
                $code = (string) ($rate['code'] ?? $rate['wilaya_code'] ?? '');

                return str_contains($wilaya, $name) || ($code !== '' && str_starts_with($wilaya, $code));
            });

            if ($match) {
                return (float) ($match[$deliveryType] ?? $match['price'] ?? $match['amount'] ?? 0);
            }
        } catch (\Throwable) {
            //
        }

        $base = str_contains($wilaya, 'Alger') ? 400.0 : 800.0;

        return $deliveryType === 'desk' ? max(0, $base - 200.0) : $base;
    }

    public function createShipment(Order $order): array
    {
        $payload = [
            'reference' => $order->reference,
            'clientName' => $order->client_name,
            'clientPhone' => $order->client_phone,
            'wilaya' => $order->wilaya,
            'commune' => $order->commune,
            'address' => $order->address,
            'deliveryType' => $order->delivery_type,
            'amount' => (float) $order->total,
            'products' => $order->items->map(fn ($item) => [
                'name' => $item->product_name,
                'sku' => $item->sku,
                'quantity' => $item->quantity,
            ])->values()->all(),
        ];

        $data = $this->request('post', '/parcels', $payload);
        $parcel = $this->firstItem($data) ?? $data;

        return [
            'provider' => 'zr_express',
            'external_id' => (string) ($parcel['id'] ?? $parcel['parcelId'] ?? $parcel['trackingNumber'] ?? ''),
            'tracking_number' => (string) ($parcel['trackingNumber'] ?? $parcel['tracking_number'] ?? $parcel['tracking'] ?? ''),
            'status' => (string) ($parcel['state'] ?? $parcel['status'] ?? 'created'),
            'payload' => $parcel,
            'last_synced_at' => now(),
        ];
    }

    public function track(string $trackingNumber): array
    {
        $data = $this->request('get', "/parcels/{$trackingNumber}");
        $parcel = $this->firstItem($data) ?? $data;

        return [
            'tracking_number' => $trackingNumber,
            'status' => (string) ($parcel['state'] ?? $parcel['status'] ?? $parcel['currentState'] ?? 'unknown'),
            'location' => (string) ($parcel['currentLocation'] ?? $parcel['location'] ?? $parcel['hub']['name'] ?? $parcel['territory']['name'] ?? ''),
            'synced_at' => now()->toISOString(),
            'raw' => $parcel,
        ];
    }

    public function territories(): array
    {
        try {
            $data = $this->request('post', '/territories/search', ['pageSize' => 200]);
            $items = $this->items($data);

            if ($items !== []) {
                return array_map(fn ($item) => [
                    'code' => (string) ($item['code'] ?? $item['wilayaCode'] ?? $item['id'] ?? ''),
                    'name' => (string) ($item['name'] ?? $item['wilaya'] ?? $item['label'] ?? ''),
                    'communes' => array_values(Arr::wrap($item['communes'] ?? $item['municipalities'] ?? [])),
                ], $items);
            }
        } catch (\Throwable) {
            //
        }

        return self::FALLBACK_TERRITORIES;
    }

    public function rates(): array
    {
        try {
            $data = $this->request('get', '/delivery-pricing/rates');
            $items = $this->items($data);

            return $items !== [] ? $items : self::FALLBACK_RATES;
        } catch (\Throwable) {
            return self::FALLBACK_RATES;
        }
    }

    private function request(string $method, string $path, array $payload = []): array
    {
        $baseUrl = rtrim($this->setting('zr_express_base_url', 'https://app.zrexpress.fr/api'), '/');
        $version = trim($this->setting('zr_express_api_version', '1'), '/');
        $url = "{$baseUrl}/v{$version}".'/'.ltrim($path, '/');

        $response = Http::acceptJson()
            ->withHeaders([
                'X-Tenant-ID' => $this->setting('zr_express_tenant_id'),
                'X-Secret-Key' => $this->setting('zr_express_secret_key'),
                'Authorization' => 'Bearer '.$this->setting('zr_express_secret_key'),
            ])
            ->timeout(12)
            ->{$method}($url, $payload);

        if (! $response->successful()) {
            throw new RuntimeException('ZR Express request failed with status '.$response->status());
        }

        return $response->json() ?? [];
    }

    private function setting(string $key, ?string $default = null): ?string
    {
        $value = Setting::where('key', $key)->first()?->value;

        return is_scalar($value) ? (string) $value : $default;
    }

    private function items(array $data): array
    {
        return $data['data'] ?? $data['items'] ?? $data['content'] ?? $data['results'] ?? (array_is_list($data) ? $data : []);
    }

    private function firstItem(array $data): ?array
    {
        $items = $this->items($data);

        return isset($items[0]) && is_array($items[0]) ? $items[0] : null;
    }
}
