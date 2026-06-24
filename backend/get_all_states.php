<?php
require __DIR__.'/vendor/autoload.php';
$app = require_once __DIR__.'/bootstrap/app.php';
$kernel = $app->make(Illuminate\Contracts\Console\Kernel::class);
$kernel->bootstrap();

use App\Services\Delivery\ZrExpressGateway;

$gateway = app(ZrExpressGateway::class);
$reflector = new ReflectionClass(ZrExpressGateway::class);
$method = $reflector->getMethod('request');
$method->setAccessible(true);

$uniqueStates = [];

echo "Fetching parcels to collect states...\n";
for ($page = 1; $page <= 5; $page++) {
    try {
        $res = $method->invoke($gateway, 'post', '/parcels/search', [
            'pageNumber' => $page,
            'pageSize' => 200
        ]);
        
        $items = $res['data'] ?? $res['items'] ?? $res['results'] ?? $res ?? [];
        if (empty($items)) {
            break;
        }
        
        foreach ($items as $item) {
            if (isset($item['state']) && is_array($item['state'])) {
                $s = $item['state'];
                $id = $s['id'] ?? '';
                if ($id && !isset($uniqueStates[$id])) {
                    $uniqueStates[$id] = [
                        'id' => $id,
                        'name' => $s['name'] ?? 'N/A',
                        'description' => $s['description'] ?? 'N/A',
                        'color' => $s['color'] ?? 'N/A'
                    ];
                }
            }
            
            // Also collect from history if present in the search item (if it includes history/state logs)
            if (isset($item['stateHistory']) && is_array($item['stateHistory'])) {
                foreach ($item['stateHistory'] as $history) {
                    foreach (['previousState', 'newState'] as $key) {
                        if (isset($history[$key]) && is_array($history[$key])) {
                            $s = $history[$key];
                            $id = $s['id'] ?? '';
                            if ($id && !isset($uniqueStates[$id])) {
                                $uniqueStates[$id] = [
                                    'id' => $id,
                                    'name' => $s['name'] ?? 'N/A',
                                    'description' => $s['description'] ?? 'N/A',
                                    'color' => $s['color'] ?? 'N/A'
                                ];
                            }
                        }
                    }
                }
            }
        }
    } catch (\Exception $e) {
        echo "Error on page {$page}: " . $e->getMessage() . "\n";
        break;
    }
}

echo "Found " . count($uniqueStates) . " unique states.\n";
echo json_encode(array_values($uniqueStates), JSON_PRETTY_PRINT | JSON_UNESCAPED_UNICODE) . "\n";
