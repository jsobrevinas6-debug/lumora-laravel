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
            ['email' => 'newbalance@gmail.com'],
            [
                'name' => 'New Balance Store',
                'first_name' => 'New Balance',
                'last_name' => 'Store',
                'password' => Hash::make('123123'),
                'role' => 'seller',
                'status' => 'active',
                'email_verified' => 1,
                'email_verified_at' => now(),
                'shop_name' => 'New Balance Store',
                'shop_description' => 'Official New Balance footwear and apparel.',
            ]
        );

        $applicationData = [
            'business_name' => 'New Balance Store',
            'status' => 'approved',
            'reason' => 'Official New Balance seller account.',
        ];
        if (Schema::hasColumn('seller_applications', 'category')) {
            $applicationData['category'] = 'Footwear & Apparel';
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
