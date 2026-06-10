<?php

namespace App\Http\Controllers\Api\Admin;

use App\Http\Controllers\Controller;
use App\Models\ShippingRate;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class ShippingRateAdminController extends Controller
{
    public function index(): JsonResponse
    {
        $rates = ShippingRate::orderBy('wilaya_code')->get();
        return response()->json(['data' => $rates]);
    }

    public function bulkUpdate(Request $request): JsonResponse
    {
        $data = $request->validate([
            'rates' => ['required', 'array'],
            'rates.*.id' => ['required', 'exists:shipping_rates,id'],
            'rates.*.home_price' => ['required', 'numeric', 'min:0'],
            'rates.*.desk_price' => ['required', 'numeric', 'min:0'],
            'rates.*.is_active' => ['required', 'boolean'],
            'rates.*.home_active' => ['required', 'boolean'],
            'rates.*.desk_active' => ['required', 'boolean'],
        ]);

        foreach ($data['rates'] as $rateData) {
            $rate = ShippingRate::findOrFail($rateData['id']);
            $rate->update([
                'home_price' => $rateData['home_price'],
                'desk_price' => $rateData['desk_price'],
                'is_active' => $rateData['is_active'],
                'home_active' => $rateData['home_active'],
                'desk_active' => $rateData['desk_active'],
            ]);
        }

        return response()->json([
            'message' => 'Shipping rates updated successfully',
            'data' => ShippingRate::orderBy('wilaya_code')->get(),
        ]);
    }
}
