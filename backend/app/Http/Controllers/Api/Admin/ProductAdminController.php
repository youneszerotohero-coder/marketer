<?php

namespace App\Http\Controllers\Api\Admin;

use App\Http\Controllers\Controller;
use App\Models\Product;
use App\Models\ProductVariant;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class ProductAdminController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        return response()->json(Product::with(['category', 'brand', 'variants'])->latest()->paginate((int) $request->query('per_page', 20)));
    }

    public function store(Request $request): JsonResponse
    {
        $data = $request->validate([
            'category_id' => ['nullable', 'exists:categories,id'],
            'brand_id' => ['nullable', 'exists:brands,id'],
            'name' => ['required', 'string', 'max:255'],
            'description' => ['nullable', 'string'],
            'main_image_path' => ['nullable', 'string'],
            'variants' => ['required', 'array', 'min:1'],
            'variants.*.sku' => ['required', 'string', 'distinct', 'unique:product_variants,sku'],
            'variants.*.purchase_price' => ['required', 'numeric', 'min:0'],
            'variants.*.sale_price' => ['required', 'numeric', 'min:0'],
            'variants.*.commission_value' => ['required', 'numeric', 'min:0'],
            'variants.*.commission_type' => ['required', 'in:fixed,percent'],
            'variants.*.stock' => ['required', 'integer', 'min:0'],
        ]);

        $product = DB::transaction(function () use ($data) {
            $variants = $data['variants'];
            unset($data['variants']);
            $product = Product::create($data);
            $product->variants()->createMany($variants);

            return $product;
        });

        return response()->json($product->load('variants'), 201);
    }

    public function update(Request $request, Product $product): JsonResponse
    {
        $data = $request->validate([
            'category_id' => ['sometimes', 'nullable', 'exists:categories,id'],
            'brand_id' => ['sometimes', 'nullable', 'exists:brands,id'],
            'name' => ['sometimes', 'string', 'max:255'],
            'description' => ['sometimes', 'nullable', 'string'],
            'main_image_path' => ['sometimes', 'nullable', 'string'],
            'status' => ['sometimes', 'in:active,archived'],
        ]);

        $product->update($data);

        return response()->json($product->load('variants'));
    }

    public function archive(Product $product): JsonResponse
    {
        $product->update(['status' => 'archived']);

        return response()->json($product);
    }

    public function updateVariant(Request $request, ProductVariant $variant): JsonResponse
    {
        $data = $request->validate([
            'purchase_price' => ['sometimes', 'numeric', 'min:0'],
            'sale_price' => ['sometimes', 'numeric', 'min:0'],
            'commission_value' => ['sometimes', 'numeric', 'min:0'],
            'commission_type' => ['sometimes', 'in:fixed,percent'],
            'stock' => ['sometimes', 'integer', 'min:0'],
            'status' => ['sometimes', 'in:active,archived'],
        ]);

        $variant->update($data);

        return response()->json($variant);
    }
}
