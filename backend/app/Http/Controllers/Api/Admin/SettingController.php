<?php

namespace App\Http\Controllers\Api\Admin;

use App\Http\Controllers\Controller;
use App\Models\Setting;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;

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

    public function uploadPdf(Request $request): JsonResponse
    {
        $request->validate([
            'pdf' => ['required', 'file', 'mimes:pdf', 'max:20480'], // max 20 MB
        ]);

        $path = $request->file('pdf')->store('pdfs', 'public');
        $url  = url(Storage::url($path));  // e.g. http://localhost:8000/storage/pdfs/xxx.pdf

        // Persist the URL in settings so the mobile app can read it
        Setting::updateOrCreate(['key' => 'pdf_document_url'], ['value' => $url]);

        return response()->json(['url' => $url]);
    }

    public function publicSettings(): JsonResponse
    {
        $keys = [
            'social.facebook',
            'social.telegram',
            'social.whatsapp',
            'social.instagram',
            'social.tiktok',
            'social.viber',
            'social.phone',
            'pdf_document_url',
        ];

        $settings = Setting::whereIn('key', $keys)->get()->mapWithKeys(fn ($setting) => [
            $setting->key => $setting->value,
        ])->all();

        foreach ($keys as $key) {
            if (!isset($settings[$key])) {
                $settings[$key] = null;
            }
        }

        return response()->json($settings);
    }

    private function settingsMap(): array
    {
        return Setting::orderBy('key')->get()->mapWithKeys(fn ($setting) => [
            $setting->key => $setting->value,
        ])->all();
    }
}
