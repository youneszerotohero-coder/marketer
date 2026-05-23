<?php

namespace App\Http\Controllers\Api\Confirmatrice;

use App\Http\Controllers\Api\Admin\OrderAdminController;
use App\Http\Controllers\Controller;
use App\Models\Order;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class OrderWorkflowController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        return response()->json(
            Order::with(['items', 'marketer'])
                ->where(function ($query) use ($request) {
                    $query->whereNull('confirmatrice_id')
                        ->orWhere('confirmatrice_id', $request->user()->id);
                })
                ->whereIn('status', ['pending', 'confirmed'])
                ->latest()
                ->paginate((int) $request->query('per_page', 20))
        );
    }

    public function updateStatus(
        Request $request,
        Order $order,
        OrderAdminController $orders
    ): JsonResponse {
        abort_if($order->confirmatrice_id && $order->confirmatrice_id !== $request->user()->id, 403);

        return $orders->updateStatus(
            $request,
            $order,
            app(\App\Services\Wallet\WalletService::class),
            app(\App\Services\Delivery\DeliveryGateway::class)
        );
    }
}
