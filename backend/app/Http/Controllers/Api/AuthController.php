<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\RefreshToken;
use App\Models\User;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Str;
use PHPOpenSourceSaver\JWTAuth\Facades\JWTAuth;

class AuthController extends Controller
{
    public function register(Request $request): JsonResponse
    {
        $data = $request->validate([
            'name' => ['required', 'string', 'max:255'],
            'email' => ['required', 'email', 'max:255', 'unique:users,email'],
            'phone' => ['nullable', 'string', 'max:40'],
            'password' => ['required', 'string', 'min:8'],
        ]);

        $user = User::create([
            'name' => $data['name'],
            'email' => $data['email'],
            'phone' => $data['phone'] ?? null,
            'role' => 'marketer',
            'password' => $data['password'],
        ]);

        return response()->json($this->issueTokens($user), 201);
    }

    public function login(Request $request): JsonResponse
    {
        $credentials = $request->validate([
            'email' => ['required', 'email'],
            'password' => ['required', 'string'],
        ]);

        $user = User::where('email', $credentials['email'])->first();

        if (!$user || !Hash::check($credentials['password'], $user->password) || $user->status !== 'active') {
            return response()->json(['message' => 'Invalid credentials'], 401);
        }

        return response()->json($this->issueTokens($user));
    }

    public function refresh(Request $request): JsonResponse
    {
        $data = $request->validate([
            'refresh_token' => ['required', 'string'],
        ]);

        $token = RefreshToken::where('token_hash', hash('sha256', $data['refresh_token']))
            ->whereNull('revoked_at')
            ->where('expires_at', '>', now())
            ->first();

        if (!$token) {
            return response()->json(['message' => 'Invalid refresh token'], 401);
        }

        $token->update(['revoked_at' => now()]);

        return response()->json($this->issueTokens($token->user));
    }

    public function me(Request $request): JsonResponse
    {
        return response()->json($request->user());
    }

    public function updateProfile(Request $request): JsonResponse
    {
        $user = $request->user();

        $data = $request->validate([
            'name' => ['required', 'string', 'max:255'],
            'phone' => ['nullable', 'string', 'max:40'],
            'bank_number' => ['nullable', 'string', 'max:255'],
            'wilaya' => ['nullable', 'string', 'max:80'],
            'password' => ['nullable', 'string', 'min:8'],
        ]);

        $user->name = $data['name'];
        $user->phone = $data['phone'] ?? null;
        
        $profile = $user->profile ?? [];
        $profile['bank_number'] = $data['bank_number'] ?? null;
        $profile['wilaya'] = $data['wilaya'] ?? null;
        $user->profile = $profile;

        if (!empty($data['password'])) {
            $user->password = $data['password'];
        }

        $user->save();

        return response()->json($user);
    }

    public function logout(Request $request): JsonResponse
    {
        JWTAuth::invalidate(JWTAuth::getToken());
        RefreshToken::where('user_id', $request->user()->id)->update(['revoked_at' => now()]);

        return response()->json(['message' => 'Logged out']);
    }

    private function issueTokens(User $user): array
    {
        $accessToken = JWTAuth::fromUser($user);
        $refreshToken = Str::random(80);

        RefreshToken::create([
            'user_id' => $user->id,
            'token_hash' => hash('sha256', $refreshToken),
            'expires_at' => now()->addDays(30),
        ]);

        return [
            'token_type' => 'Bearer',
            'access_token' => $accessToken,
            'refresh_token' => $refreshToken,
            'expires_in' => auth('api')->factory()->getTTL() * 60,
            'user' => $user,
        ];
    }
}
