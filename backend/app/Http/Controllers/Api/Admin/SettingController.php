<?php

namespace App\Http\Controllers\Api\Admin;

use App\Http\Controllers\Controller;
use App\Models\Setting;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class SettingController extends Controller
{
    public function index(): JsonResponse
    {
        return response()->json($this->settingsMap());
    }

    public function upsert(Request $request): JsonResponse
    {
        $data = $request->validate([
            'settings' => ['required', 'array'],
            'settings.*.key' => ['required', 'string', 'max:255'],
            'settings.*.value' => ['nullable'],
        ]);

        foreach ($data['settings'] as $setting) {
            Setting::updateOrCreate(['key' => $setting['key']], ['value' => $setting['value'] ?? null]);
        }

        return response()->json($this->settingsMap());
    }

    private function settingsMap(): array
    {
        return Setting::orderBy('key')->get()->mapWithKeys(fn ($setting) => [
            $setting->key => $setting->value,
        ])->all();
    }
}
