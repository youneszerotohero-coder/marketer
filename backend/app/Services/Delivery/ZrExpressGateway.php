<?php

namespace App\Services\Delivery;

use App\Models\Order;
use App\Models\Setting;
use Illuminate\Support\Arr;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Str;
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
        $territory = $this->resolveTerritoryIds((string) $order->wilaya, (string) $order->commune);

        if (!$territory) {
            throw new RuntimeException("Could not resolve territory IDs for Wilaya: '{$order->wilaya}', Commune: '{$order->commune}' in ZR Express. Please verify spelling.");
        }

        $payload = [
            'reference' => $order->reference,
            'deliveryType' => $order->delivery_type === 'desk' ? 'pickup-point' : 'home',
            'customer' => [
                'customerId' => Str::uuid()->toString(),
                'name' => $order->client_name ?: 'Non specifie',
                'phone' => [
                    'number1' => $this->formatPhoneNumber((string) $order->client_phone),
                ],
            ],
            'deliveryAddress' => [
                'cityTerritoryId' => $territory['cityTerritoryId'],
                'districtTerritoryId' => $territory['districtTerritoryId'],
                'street' => $order->address ?: 'Non specifiee',
            ],
            'amount' => (float) $order->total,
            'description' => $order->notes ?: 'Commande ' . $order->reference,
            'orderedProducts' => $order->items->map(fn($item) => [
                'productName' => $item->product_name,
                'quantity' => (int) $item->quantity,
                'stockType' => 'none',
                'unitPrice' => (float) ($item->price ?? $item->unit_price ?? 0),
            ])->values()->all(),
            'hubId' => $order->delivery_type === 'desk' 
                ? $this->resolveHubId($territory, (string) $this->setting('zr_express_hub_id')) 
                : $this->setting('zr_express_hub_id'),
        ];

        $data = $this->request('post', '/parcels', $payload);
        $parcel = $this->firstItem($data) ?? $data;
        // Immediately set the parcel to "pret_a_expedier"
        $stateGuid = '8a948c66-1ab7-4433-aeb0-94219125d134';
        try {
            $this->request('patch', "/parcels/{$parcel['id']}/state", [
                'parcelId' => $parcel['id'],
                'newStateId' => $stateGuid,
            ]);
            
            // Fetch the updated parcel details to retrieve the generated tracking number
            $updatedData = $this->request('get', "/parcels/{$parcel['id']}");
            $parcel = $this->firstItem($updatedData) ?? $updatedData;
            $parcel['status'] = 'pret_a_expedier';
        } catch (\Throwable $e) {
            // Log but do not fail creation; admin can retry later
            Log::warning('Failed to set parcel state to pret_a_expedier', ['error' => $e->getMessage(), 'parcel_id' => $parcel['id'] ?? null]);
        }
        return [
            'provider' => 'zr_express',
            'external_id' => (string) ($parcel['id'] ?? $parcel['parcelId'] ?? $parcel['trackingNumber'] ?? ''),
            'tracking_number' => (string) ($parcel['trackingNumber'] ?? $parcel['tracking_number'] ?? $parcel['tracking'] ?? ''),
            'status' => (string) ($parcel['status'] ?? $parcel['state'] ?? 'created'),
            'payload' => $parcel,
            'last_synced_at' => now(),
        ];
    }

    public function track(string $trackingNumber): array
    {
        $data = $this->request('get', "/parcels/{$trackingNumber}");
        $parcel = $this->firstItem($data) ?? $data;

        $statusVal = $parcel['state'] ?? $parcel['status'] ?? $parcel['currentState'] ?? 'unknown';
        if (is_array($statusVal)) {
            $statusVal = $statusVal['name'] ?? $statusVal['slug'] ?? $statusVal['status'] ?? 'unknown';
        }
        $statusStr = (string) $statusVal;

        $history = [];
        $parcelId = $parcel['id'] ?? $parcel['parcelId'] ?? null;
        if ($parcelId && in_array($statusStr, ['en_retour', 'retourne', 'reinjecte_stock', 'commande_annulee'])) {
            try {
                $history = $this->request('get', "/parcels/{$parcelId}/state-history");
            } catch (\Throwable $e) {
                Log::warning('Failed to fetch state history for parcel', [
                    'parcel_id' => $parcelId,
                    'error' => $e->getMessage()
                ]);
            }
        }

        $parcel['history'] = $history;

        return [
            'tracking_number' => $trackingNumber,
            'status' => $statusStr,
            'location' => (string) ($parcel['currentLocation'] ?? $parcel['location'] ?? $parcel['hub']['name'] ?? $parcel['territory']['name'] ?? ''),
            'synced_at' => now()->toISOString(),
            'raw' => $parcel,
        ];
    }

    public function cancelShipment(string $externalId): void
    {
        $this->request('delete', "/parcels/{$externalId}");
    }

    public function territories(): array
    {
        try {
            $data = $this->request('post', '/territories/search', ['pageSize' => 200]);
            $items = $this->items($data);

            if ($items !== []) {
                return array_map(fn($item) => [
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
        if (!str_ends_with($baseUrl, '/api') && (str_contains($baseUrl, 'zrexpress') || str_contains($baseUrl, 'procolis'))) {
            $baseUrl .= '/api';
        }
        $version = trim($this->setting('zr_express_api_version', '1'), '/');
        $url = "{$baseUrl}/v{$version}" . '/' . ltrim($path, '/');

        Log::info('ZR Express API Request', [
            'method' => $method,
            'url' => $url,
            'headers' => [
                'X-Tenant-ID' => $this->setting('zr_express_tenant_id'),
                'X-Tenant' => $this->setting('zr_express_tenant_id'),
                'X-Secret-Key' => $this->setting('zr_express_secret_key'),
                'X-Api-Key' => $this->setting('zr_express_secret_key'),
            ],
            'payload' => $payload,
        ]);

        $response = Http::acceptJson()
                    ->withToken($this->setting('zr_express_secret_key'))
                    ->withHeaders([
                        'X-Tenant-ID' => $this->setting('zr_express_tenant_id'),
                        'X-Tenant' => $this->setting('zr_express_tenant_id'),
                        'X-Secret-Key' => $this->setting('zr_express_secret_key'),
                        'X-Api-Key' => $this->setting('zr_express_secret_key'),
                    ])
                    ->timeout(12)
            ->{$method}($url, $payload);

        if (!$response->successful()) {
            $errorBody = $response->body();
            Log::error('ZR Express API Error', [
                'status' => $response->status(),
                'body' => $errorBody,
            ]);
            throw new \Exception('ZR Express request failed with status '.$response->status().': '.$errorBody);
        }

        return $response->json() ?? [];
    }

    private function setting(string $key, ?string $default = null): ?string
    {
        $value = Setting::where('key', $key)->first()?->value;
        if (is_scalar($value)) {
            return (string) $value;
        }
        // Fallback to environment variable (e.g., ZR_EXPRESS_HUB_ID) if not stored in DB
        $envKey = strtoupper(str_replace(['.', '-'], '_', $key));
        $envValue = env($envKey);
        if (is_string($envValue) && $envValue !== '') {
            return $envValue;
        }
        return $default;
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

    private function resolveTerritoryIds(string $inputWilaya, string $inputCommune): ?array
    {
        $territories = Cache::remember('zr_express_territories_list', 86400, function () {
            return $this->fetchAllTerritoriesFromApi();
        });

        $normInputWilaya = $this->normalizeName($inputWilaya);
        $normInputCommune = $this->normalizeName($inputCommune);
        $wilayaDigits = preg_replace('/[^\d]/', '', $inputWilaya);

        $wilayas = [];
        $communes = [];
        foreach ($territories as $t) {
            $level = $t['level'] ?? '';
            if ($level === 'wilaya') {
                $wilayas[] = $t;
            } elseif ($level === 'commune') {
                $communes[] = $t;
            }
        }

        // Find matching communes
        $matchingCommunes = [];
        foreach ($communes as $c) {
            if ($this->normalizeName($c['name'] ?? '') === $normInputCommune) {
                $matchingCommunes[] = $c;
            }
        }

        // Find matching wilayas
        $matchedWilaya = null;
        foreach ($wilayas as $w) {
            $normWName = $this->normalizeName($w['name'] ?? '');
            $wCode = (string) ($w['code'] ?? '');

            $nameMatches = ($normWName !== '' && (strpos($normInputWilaya, $normWName) !== false || strpos($normWName, $normInputWilaya) !== false));
            $codeMatches = ($wilayaDigits !== '' && $wCode !== '' && (int) $wilayaDigits === (int) $wCode);

            if ($nameMatches || $codeMatches) {
                $matchedWilaya = $w;
                break;
            }
        }

        if ($matchingCommunes !== []) {
            if ($matchedWilaya) {
                foreach ($matchingCommunes as $c) {
                    if ($c['parentId'] === $matchedWilaya['id']) {
                        return [
                            'cityTerritoryId' => $matchedWilaya['id'],
                            'districtTerritoryId' => $c['id'],
                        ];
                    }
                }
            }
            $firstCommune = $matchingCommunes[0];
            return [
                'cityTerritoryId' => $firstCommune['parentId'],
                'districtTerritoryId' => $firstCommune['id'],
            ];
        }

        if ($matchedWilaya) {
            $normWName = $this->normalizeName($matchedWilaya['name'] ?? '');
            foreach ($communes as $c) {
                if ($c['parentId'] === $matchedWilaya['id'] && $this->normalizeName($c['name'] ?? '') === $normWName) {
                    return [
                        'cityTerritoryId' => $matchedWilaya['id'],
                        'districtTerritoryId' => $c['id'],
                    ];
                }
            }
            foreach ($communes as $c) {
                if ($c['parentId'] === $matchedWilaya['id']) {
                    return [
                        'cityTerritoryId' => $matchedWilaya['id'],
                        'districtTerritoryId' => $c['id'],
                    ];
                }
            }
        }

        return null;
    }

    private function fetchAllTerritoriesFromApi(): array
    {
        $allTerritories = [];
        $page = 1;
        while ($page <= 5) {
            $res = $this->request('post', '/territories/search', [
                'pageNumber' => $page,
                'pageSize' => 1000
            ]);
            $items = $this->items($res);
            if (empty($items)) {
                break;
            }
            $allTerritories = array_merge($allTerritories, $items);
            if (count($items) < 1000) {
                break;
            }
            $page++;
        }
        return $allTerritories;
    }

    private function normalizeName(string $name): string
    {
        $name = mb_strtolower($name, 'UTF-8');
        $name = preg_replace('/^(el|al)\s+/', '', $name);
        $name = preg_replace('/^(el|al)-/', '', $name);
        return preg_replace('/[^\p{L}\p{N}]/u', '', $name);
    }

    private function formatPhoneNumber(string $phone): string
    {
        $phone = preg_replace('/[^\d+]/', '', $phone);
        
        if (str_starts_with($phone, '+213')) {
            return $phone;
        }
        
        if (str_starts_with($phone, '00213')) {
            return '+' . substr($phone, 2);
        }
        
        if (str_starts_with($phone, '213')) {
            return '+' . $phone;
        }
        
        if (str_starts_with($phone, '0')) {
            return '+213' . substr($phone, 1);
        }
        
        return '+213' . $phone;
    }

    private function resolveHubId(array $territory, string $defaultHubId): string
    {
        $hubs = Cache::remember('zr_express_hubs_list', 86400, function () {
            return $this->fetchAllHubsFromApi();
        });

        if (empty($hubs)) {
            return $defaultHubId;
        }

        $cityId = $territory['cityTerritoryId'] ?? null;
        $districtId = $territory['districtTerritoryId'] ?? null;

        if (!$cityId) {
            return $defaultHubId;
        }

        // 1. Try to find a hub matching the specific commune (districtTerritoryId)
        if ($districtId) {
            foreach ($hubs as $hub) {
                if (($hub['isPickupPoint'] ?? false) && ($hub['address']['districtTerritoryId'] ?? '') === $districtId) {
                    return $hub['id'];
                }
            }
        }

        // 2. Fallback: Find a hub matching the wilaya (cityTerritoryId)
        foreach ($hubs as $hub) {
            if (($hub['isPickupPoint'] ?? false) && ($hub['address']['cityTerritoryId'] ?? '') === $cityId) {
                return $hub['id'];
            }
        }

        return $defaultHubId;
    }

    private function fetchAllHubsFromApi(): array
    {
        try {
            $res = $this->request('post', '/hubs/search', ['pageSize' => 500]);
            return $this->items($res);
        } catch (\Throwable) {
            return [];
        }
    }
}

