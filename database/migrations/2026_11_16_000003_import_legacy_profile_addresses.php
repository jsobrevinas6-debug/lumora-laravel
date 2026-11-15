<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('user_addresses', function (Blueprint $table) {
            $table->string('region')->nullable()->change();
            $table->string('street_address')->nullable()->change();
            $table->string('postal_code', 10)->nullable()->change();
        });

        $users = DB::table('users')
            ->whereNotNull('name')
            ->whereNotNull('contact_number')
            ->whereNotNull('province')
            ->whereNotNull('municipality')
            ->whereNotNull('barangay')
            ->orderBy('id');

        $hasPostalCode = Schema::hasColumn('users', 'postal_code');

        $users->chunkById(200, function ($rows) use ($hasPostalCode) {
            $existingByUser = DB::table('user_addresses')
                ->whereIn('user_id', $rows->pluck('id'))
                ->get()
                ->groupBy('user_id');

            foreach ($rows as $user) {
                $streetAddress = collect([$user->house_number ?? null, $user->street ?? null])
                    ->map(fn ($part) => trim((string) $part))
                    ->filter()
                    ->implode(' ');
                $postalCode = $hasPostalCode ? ($user->postal_code ?? null) : null;
                $existing = $existingByUser->get($user->id, collect());
                $alreadySaved = $existing->contains(function ($address) use ($user, $streetAddress, $postalCode) {
                    return trim((string) $address->full_name) === trim((string) $user->name)
                        && trim((string) $address->phone_number) === trim((string) $user->contact_number)
                        && trim((string) $address->province) === trim((string) $user->province)
                        && trim((string) $address->city_municipality) === trim((string) $user->municipality)
                        && trim((string) $address->barangay) === trim((string) $user->barangay)
                        && trim((string) ($address->street_address ?? '')) === $streetAddress
                        && trim((string) ($address->postal_code ?? '')) === trim((string) ($postalCode ?? ''));
                });
                if ($alreadySaved) {
                    continue;
                }

                DB::table('user_addresses')->insert([
                    'user_id' => $user->id,
                    'full_name' => $user->name,
                    'phone_number' => $user->contact_number,
                    'region' => null,
                    'region_code' => null,
                    'province' => $user->province,
                    'province_code' => null,
                    'city_municipality' => $user->municipality,
                    'city_municipality_code' => null,
                    'barangay' => $user->barangay,
                    'barangay_code' => null,
                    'street_address' => $streetAddress !== '' ? $streetAddress : null,
                    'postal_code' => $postalCode,
                    'label' => 'home',
                    'is_default' => ! $existing->contains(fn ($address) => (bool) $address->is_default),
                    'created_at' => now(),
                    'updated_at' => now(),
                ]);
            }
        });
    }

    public function down(): void
    {
        // Imported rows are customer address data; rollback must not delete or rewrite them.
    }
};
