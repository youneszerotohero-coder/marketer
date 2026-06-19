<?php

namespace App\Http\Controllers\Api\Admin;

use App\Http\Controllers\Controller;
use App\Models\Category;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;

class CategoryAdminController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        return response()->json(
            Category::withCount('products')
                ->when($request->query('search'), fn ($q, $search) => $q->where('name', 'like', "%{$search}%"))
                ->when($request->query('status'), fn ($q, $status) => $q->where('status', $status))
                ->orderBy('name')
                ->paginate((int) $request->query('per_page', 50))
        );
    }

    public function store(Request $request): JsonResponse
    {
        $data = $request->validate([
            'name' => ['required', 'string', 'max:255', 'unique:categories,name'],
            'parent_id' => ['nullable', 'exists:categories,id'],
            'image' => ['nullable', 'image', 'max:5120'],
            'status' => ['sometimes', 'in:active,inactive'],
        ]);

        if ($request->hasFile('image')) {
            $data['image_path'] = $request->file('image')->store('categories', 'public');
        }
        unset($data['image']);

        $category = Category::create(array_merge(['status' => 'active'], $data));

        return response()->json($category, 201);
    }

    public function update(Request $request, Category $category): JsonResponse
    {
        $data = $request->validate([
            'name' => ['sometimes', 'string', 'max:255', 'unique:categories,name,'.$category->id],
            'parent_id' => ['sometimes', 'nullable', 'exists:categories,id'],
            'image' => ['nullable', 'image', 'max:5120'],
            'status' => ['sometimes', 'in:active,inactive'],
            'delete_image' => ['nullable', 'boolean'],
        ]);

        if ($request->boolean('delete_image')) {
            if ($category->image_path) {
                Storage::disk('public')->delete($category->image_path);
            }
            $data['image_path'] = null;
        }

        if ($request->hasFile('image')) {
            if ($category->image_path) {
                Storage::disk('public')->delete($category->image_path);
            }
            $data['image_path'] = $request->file('image')->store('categories', 'public');
        }
        unset($data['image'], $data['delete_image']);

        $category->update($data);

        return response()->json($category);
    }
}
