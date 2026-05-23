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
            ->with(['category', 'brand', 'variants.values.attribute'])
            ->where('status', 'active')
            ->when($request->query('search'), fn ($q, $search) => $q->where('name', 'ilike', "%{$search}%"))
            ->when($request->query('category_id'), fn ($q, $id) => $q->where('category_id', $id))
            ->when($request->query('brand_id'), fn ($q, $id) => $q->where('brand_id', $id))
            ->latest()
            ->paginate((int) $request->query('per_page', 20));

        return response()->json($products);
    }

    public function show(Product $product): JsonResponse
    {
        return response()->json($product->load(['category', 'brand', 'images', 'variants.values.attribute']));
    }
}
