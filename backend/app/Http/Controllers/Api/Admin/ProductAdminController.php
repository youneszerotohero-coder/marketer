<?php

namespace App\Http\Controllers\Api\Admin;

use App\Http\Controllers\Controller;
use App\Models\Product;
use App\Models\ProductVariant;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Storage;

class ProductAdminController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $products = Product::with(['category', 'brand', 'variants', 'images'])
            ->when($request->query('search'), fn ($q, $search) => $q->where('name', 'like', "%{$search}%"))
            ->when($request->query('category_id'), fn ($q, $id) => $q->where('category_id', $id))
            ->latest()
            ->paginate((int) $request->query('per_page', 20));

        return response()->json($products);
    }

    public function store(Request $request): JsonResponse
    {
        $data = $request->validate([
            'category_id' => ['nullable', 'exists:categories,id'],
            'brand_id' => ['nullable', 'exists:brands,id'],
            'name' => ['required', 'string', 'max:255'],
            'description' => ['nullable', 'string'],
            'in_stock' => ['sometimes', 'boolean'],
            'images' => ['nullable', 'array'],
            'images.*' => ['image', 'max:5120'],
            'main_image_index' => ['nullable', 'integer'],
            'variants' => ['required', 'array', 'min:1'],
            'variants.*.sku' => ['required', 'string', 'distinct', 'unique:product_variants,sku'],
            'variants.*.purchase_price' => ['required', 'numeric', 'min:0'],
            'variants.*.sale_price' => ['required', 'numeric', 'min:0'],
            'variants.*.commission_value' => ['required', 'numeric', 'min:0'],
            'variants.*.commission_type' => ['required', 'in:fixed,percent'],
        ]);

        $product = DB::transaction(function () use ($data, $request) {
            $variants = $data['variants'];
            unset($data['variants'], $data['images']);
            $product = Product::create($data);
            $product->variants()->createMany($variants);

            if ($request->hasFile('images')) {
                $newPaths = [];
                foreach ($request->file('images') as $index => $file) {
                    $path = $file->store('products', 'public');
                    $product->images()->create([
                        'path' => $path,
                        'sort_order' => $index
                    ]);
                    $newPaths[$index] = $path;
                }

                if ($request->has('main_image_index') && isset($newPaths[$request->input('main_image_index')])) {
                    $product->update(['main_image_path' => $newPaths[$request->input('main_image_index')]]);
                } elseif (count($newPaths) > 0) {
                    $product->update(['main_image_path' => $newPaths[0]]);
                }
            }

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
            'status' => ['sometimes', 'in:active,archived'],
            'in_stock' => ['sometimes', 'boolean'],
            'images' => ['nullable', 'array'],
            'images.*' => ['image', 'max:5120'],
            'deleted_images' => ['nullable', 'array'],
            'main_image_id' => ['nullable', 'integer'],
            'main_image_index' => ['nullable', 'integer'],
            'variants' => ['sometimes', 'array', 'min:1'],
            'variants.*.sku' => ['required', 'string', 'distinct'],
            'variants.*.purchase_price' => ['required', 'numeric', 'min:0'],
            'variants.*.sale_price' => ['required', 'numeric', 'min:0'],
            'variants.*.commission_value' => ['required', 'numeric', 'min:0'],
            'variants.*.commission_type' => ['required', 'in:fixed,percent'],
        ]);

        unset($data['images'], $data['deleted_images'], $data['main_image_id'], $data['main_image_index']);
        $product->update($data);

        if ($request->has('deleted_images')) {
            $imagesToDelete = $product->images()->whereIn('id', $request->input('deleted_images'))->get();
            foreach ($imagesToDelete as $img) {
                Storage::disk('public')->delete($img->path);
                $img->delete();
            }
        }

        $newPaths = [];
        if ($request->hasFile('images')) {
            foreach ($request->file('images') as $index => $file) {
                $path = $file->store('products', 'public');
                $product->images()->create([
                    'path' => $path,
                    'sort_order' => $product->images()->max('sort_order') + 1 + $index
                ]);
                $newPaths[$index] = $path;
            }
        }

        if ($request->has('main_image_id')) {
            $mainImg = $product->images()->find($request->input('main_image_id'));
            if ($mainImg) {
                $product->update(['main_image_path' => $mainImg->path]);
            }
        } elseif ($request->has('main_image_index') && isset($newPaths[$request->input('main_image_index')])) {
            $product->update(['main_image_path' => $newPaths[$request->input('main_image_index')]]);
        } elseif (!$product->main_image_path && count($newPaths) > 0) {
            $product->update(['main_image_path' => $newPaths[0]]);
        }

        // Sync variants
        if ($request->has('variants')) {
            $incomingVariants = collect($request->input('variants'));
            $incomingSkus = $incomingVariants->pluck('sku')->filter()->toArray();

            // Archive missing variants
            $product->variants()->whereNotIn('sku', $incomingSkus)->update(['status' => 'archived']);

            foreach ($incomingVariants as $variantData) {
                if (empty($variantData['sku'])) continue;
                $product->variants()->updateOrCreate(
                    ['sku' => $variantData['sku']],
                    [
                        'purchase_price' => $variantData['purchase_price'],
                        'sale_price' => $variantData['sale_price'],
                        'commission_value' => $variantData['commission_value'],
                        'commission_type' => $variantData['commission_type'],
                        'status' => 'active', // Reactivate if it was archived
                    ]
                );
            }
        }

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
            'status' => ['sometimes', 'in:active,archived'],
        ]);

        $variant->update($data);

        return response()->json($variant);
    }
}
