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

// 1. Get the list of all parcels we can find
try {
    echo "Querying recent parcels...\n";
    $parcels = $method->invoke($gateway, 'get', '/parcels');
    echo "Parcels response:\n";
    echo json_encode($parcels, JSON_PRETTY_PRINT | JSON_UNESCAPED_UNICODE) . "\n";
    
    $items = $parcels['data'] ?? $parcels['items'] ?? $parcels ?? [];
    if (!empty($items)) {
        $firstParcel = $items[0];
        $id = $firstParcel['id'] ?? $firstParcel['parcelId'] ?? null;
        if ($id) {
            echo "First parcel ID: {$id}\n";
            echo "Trying GET /parcels/{$id}/state-history...\n";
            $history = $method->invoke($gateway, 'get', "/parcels/{$id}/state-history");
            echo json_encode($history, JSON_PRETTY_PRINT | JSON_UNESCAPED_UNICODE) . "\n";
            
            echo "Trying GET /parcels/{$id}/allowed-states...\n";
            $allowed = $method->invoke($gateway, 'get', "/parcels/{$id}/allowed-states");
            echo json_encode($allowed, JSON_PRETTY_PRINT | JSON_UNESCAPED_UNICODE) . "\n";
        }
    }
} catch (\Exception $e) {
    echo "Error: " . $e->getMessage() . "\n";
}

// 2. Try workflow endpoints
$workflowEndpoints = [
    '/workflows/states',
    '/workflow/states',
    '/workflow/states/search',
    '/states/workflows',
];
foreach ($workflowEndpoints as $path) {
    try {
        echo "Trying GET {$path}...\n";
        $res = $method->invoke($gateway, 'get', $path);
        echo "SUCCESS!\n";
        echo json_encode($res, JSON_PRETTY_PRINT | JSON_UNESCAPED_UNICODE) . "\n";
    } catch (\Exception $e) {
        echo "FAILED: " . $e->getMessage() . "\n";
    }
}
