<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Order;
use App\Services\Delivery\DeliveryGateway;
use App\Services\Delivery\DeliveryStatusService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class DeliveryController extends Controller
{
    public function territories(DeliveryGateway $delivery): JsonResponse
    {
        return response()->json(['data' => $delivery->territories()]);
    }

    public function rates(DeliveryGateway $delivery): JsonResponse
    {
        return response()->json(['data' => $delivery->rates()]);
    }

    public function syncOrder(Request $request, Order $order, DeliveryStatusService $statusService): JsonResponse
    {
        $user = $request->user();
        $isAdmin = in_array($user->role, ['admin', 'confirmatrice'], true);

        abort_unless($isAdmin || $order->marketer_id === $user->id, 403);

        return response()->json([
            'order' => $statusService->sync($order),
        ]);
    }
}
