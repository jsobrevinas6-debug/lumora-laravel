<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Cache;

class AddressController extends Controller
{
    private string $base = 'https://psgc.cloud/api/v2';

    public function provinces()
    {
        $data = Cache::remember('psgc_provinces', now()->addDay(), function () {
            $res = Http::timeout(10)->get("{$this->base}/provinces");
            return $res->successful() ? $res->json() : [];
        });

        return response()->json($data);
    }

    public function municipalities(string $provinceCode)
    {
        $data = Cache::remember("psgc_municipalities_{$provinceCode}", now()->addDay(), function () use ($provinceCode) {
            $res = Http::timeout(10)->get("{$this->base}/provinces/{$provinceCode}/cities-municipalities");
            return $res->successful() ? $res->json() : [];
        });

        return response()->json($data);
    }

    public function barangays(string $municipalityCode)
    {
        $data = Cache::remember("psgc_barangays_{$municipalityCode}", now()->addDay(), function () use ($municipalityCode) {
            $res = Http::timeout(10)->get("{$this->base}/cities-municipalities/{$municipalityCode}/barangays");
            return $res->successful() ? $res->json() : [];
        });

        return response()->json($data);
    }
}