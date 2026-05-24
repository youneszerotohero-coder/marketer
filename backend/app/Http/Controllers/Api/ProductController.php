<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Product;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class ProductController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $products = Product::query()
            ->with(['category', 'brand', 'variants' => fn($q) => $q->where('status', 'active')])
            ->where('status', 'active')
            ->when($request->query('search'), fn ($q, $search) => $q->where('name', 'like', "%{$search}%"))
            ->when($request->query('category_id'), fn ($q, $id) => $q->whereIn('category_id', explode(',', $id)))
            ->when($request->query('brand_id'), fn ($q, $id) => $q->whereIn('brand_id', explode(',', $id)))
            ->when($request->query('min_price'), function ($q, $min) {
                $q->whereHas('variants', fn($vq) => $vq->where('status', 'active')->where('sale_price', '>=', $min));
            })
            ->when($request->query('max_price'), function ($q, $max) {
                $q->whereHas('variants', fn($vq) => $vq->where('status', 'active')->where('sale_price', '<=', $max));
            })
            ->when($request->query('sort'), function ($q, $sort) {
                if ($sort === 'newest') {
                    $q->latest();
                } elseif ($sort === 'price_asc') {
                    $q->orderBy(\App\Models\ProductVariant::select('sale_price')
                        ->whereColumn('product_id', 'products.id')
                        ->where('status', 'active')
                        ->orderBy('sale_price', 'asc')
                        ->limit(1)
                    , 'asc');
                } elseif ($sort === 'price_desc') {
                    $q->orderBy(\App\Models\ProductVariant::select('sale_price')
                        ->whereColumn('product_id', 'products.id')
                        ->where('status', 'active')
                        ->orderBy('sale_price', 'desc')
                        ->limit(1)
                    , 'desc');
                } else {
                    $q->latest();
                }
            }, function ($q) {
                $q->latest();
            })
            ->paginate((int) $request->query('per_page', 20));

        return response()->json($products);
    }

    public function show(Product $product): JsonResponse
    {
        return response()->json($product->load(['category', 'brand', 'images', 'variants' => fn($q) => $q->where('status', 'active')]));
    }
}
