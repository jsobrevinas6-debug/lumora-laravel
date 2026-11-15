<?php

use App\Models\SellerApplication;
use App\Models\User;
use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        $user = User::updateOrCreate(
            ['email' => 'earrings@gmail.com'],
            [
                'name' => 'Earrings Store',
                'first_name' => 'Earrings',
                'last_name' => 'Store',
                'password' => Hash::make('123123123'),
                'role' => 'seller',
                'status' => 'active',
                'email_verified' => 1,
                'email_verified_at' => now(),
                'shop_name' => 'Earrings Store',
                'shop_description' => 'Earrings and jewelry accessories.',
            ]
        );

        $applicationData = [
            'business_name' => 'Earrings Store',
            'status' => 'approved',
            'reason' => 'Official Earrings seller account.',
        ];
        if (Schema::hasColumn('seller_applications', 'category')) {
            $applicationData['category'] = 'Fashion & Accessories';
        }

        SellerApplication::updateOrCreate(
            ['user_id' => $user->id],
            $applicationData
        );
    }

    public function down(): void
    {
        // Keep seller account intact on rollback.
    }
};
