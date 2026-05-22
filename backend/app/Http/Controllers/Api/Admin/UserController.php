<?php

namespace App\Http\Controllers\Api\Admin;

use App\Http\Controllers\Controller;
use App\Models\User;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class UserController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        return response()->json(
            User::query()
                ->when($request->query('role'), fn ($q, $role) => $q->where('role', $role))
                ->when($request->query('status'), fn ($q, $status) => $q->where('status', $status))
                ->latest()
                ->paginate((int) $request->query('per_page', 20))
        );
    }

    public function store(Request $request): JsonResponse
    {
        $data = $request->validate([
            'name' => ['required', 'string', 'max:255'],
            'email' => ['required', 'email', 'unique:users,email'],
            'phone' => ['nullable', 'string', 'max:40'],
            'role' => ['required', 'in:admin,marketer,confirmatrice'],
            'tier' => ['nullable', 'string', 'max:80'],
            'password' => ['required', 'string', 'min:8'],
        ]);

        return response()->json(User::create($data), 201);
    }

    public function update(Request $request, User $user): JsonResponse
    {
        $data = $request->validate([
            'name' => ['sometimes', 'string', 'max:255'],
            'phone' => ['sometimes', 'nullable', 'string', 'max:40'],
            'role' => ['sometimes', 'in:admin,marketer,confirmatrice'],
            'tier' => ['sometimes', 'string', 'max:80'],
            'status' => ['sometimes', 'in:active,suspended'],
            'password' => ['sometimes', 'string', 'min:8'],
            'profile' => ['sometimes', 'array'],
        ]);

        if (($data['status'] ?? null) === 'suspended') {
            $data['suspended_at'] = now();
        } elseif (($data['status'] ?? null) === 'active') {
            $data['suspended_at'] = null;
        }

        $user->update($data);

        return response()->json($user);
    }
}
