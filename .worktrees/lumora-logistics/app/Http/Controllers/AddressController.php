<?php

namespace App\Http\Controllers;

use Illuminate\Http\JsonResponse;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\Http;

class AddressController extends Controller
{
    private string $base = 'https://psgc.cloud/api/v2';

    public function provinces(): JsonResponse
    {
        return response()->json([
            'data' => $this->cachedList('psgc_provinces', "{$this->base}/provinces"),
        ]);
    }

    public function municipalities(string $provinceCode): JsonResponse
    {
        return response()->json([
            'data' => $this->cachedList(
                "psgc_municipalities_{$provinceCode}",
                "{$this->base}/provinces/{$provinceCode}/cities-municipalities"
            ),
        ]);
    }

    public function barangays(string $municipalityCode): JsonResponse
    {
        return response()->json([
            'data' => $this->cachedList(
                "psgc_barangays_{$municipalityCode}",
                "{$this->base}/cities-municipalities/{$municipalityCode}/barangays"
            ),
        ]);
    }

    private function cachedList(string $cacheKey, string $url): array
    {
        $cached = Cache::get($cacheKey);

        if (is_array($cached) && count($cached) > 0) {
            return $cached;
        }

        try {
            $response = Http::acceptJson()
                ->timeout(15)
                ->retry(2, 250)
                ->get($url);

            if (! $response->successful()) {
                return [];
            }

            $payload = $response->json();
            $items = is_array($payload) && isset($payload['data'])
                ? $payload['data']
                : $payload;

            if (! is_array($items) || count($items) === 0) {
                return [];
            }

            Cache::put($cacheKey, $items, now()->addDay());

            return $items;
        } catch (\Throwable $exception) {
            report($exception);
            return [];
        }
    }
}
