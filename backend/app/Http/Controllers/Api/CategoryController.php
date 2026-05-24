<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Category;
use Illuminate\Http\JsonResponse;

class CategoryController extends Controller
{
    public function index(): JsonResponse
    {
        return response()->json(
            Category::where('status', 'active')
                ->whereNull('parent_id')
                ->with('children')
                ->orderBy('name')
                ->get()
        );
    }
}
