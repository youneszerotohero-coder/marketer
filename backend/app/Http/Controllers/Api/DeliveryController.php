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
    public function territories(): JsonResponse
    {
        $rates = \App\Models\ShippingRate::where('is_active', true)
            ->with(['communes' => fn($q) => $q->orderBy('name')])
            ->orderBy('wilaya_code')
            ->get();

        $data = $rates->map(fn($rate) => [
            'code' => $rate->wilaya_code,
            'name' => $rate->wilaya_name,
            'name_ar' => $rate->wilaya_name_ar,
            'home_price' => (float)$rate->home_price,
            'desk_price' => (float)$rate->desk_price,
            'home_active' => (bool)$rate->home_active,
            'desk_active' => (bool)$rate->desk_active,
            'communes' => $rate->communes->map(fn($c) => [
                'id' => $c->id,
                'name' => $c->name,
                'name_ar' => $c->name_ar,
                'post_code' => $c->post_code,
            ])->all()
        ])->all();

        return response()->json(['data' => $data]);
    }

    public function rates(): JsonResponse
    {
        $rates = \App\Models\ShippingRate::orderBy('wilaya_code')->get();
        $data = $rates->map(fn($rate) => [
            'id' => $rate->id,
            'code' => $rate->wilaya_code,
            'wilaya_code' => $rate->wilaya_code,
            'wilaya' => $rate->wilaya_name,
            'wilaya_ar' => $rate->wilaya_name_ar,
            'home' => (float)$rate->home_price,
            'desk' => (float)$rate->desk_price,
            'is_active' => $rate->is_active,
            'home_active' => $rate->home_active,
            'desk_active' => $rate->desk_active,
        ])->all();

        return response()->json(['data' => $data]);
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
