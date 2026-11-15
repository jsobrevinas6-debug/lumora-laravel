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
            ['email' => 'groomings@gmail.com'],
            [
                'name' => 'Groomings Store',
                'first_name' => 'Groomings',
                'last_name' => 'Store',
                'password' => Hash::make('123123123'),
                'role' => 'seller',
                'status' => 'active',
                'email_verified' => 1,
                'email_verified_at' => now(),
                'shop_name' => 'Groomings Store',
                'shop_description' => 'Official Groomings seller account for personal grooming and shaving products.',
            ]
        );

        $applicationData = [
            'business_name' => 'Groomings Store',
            'status' => 'approved',
            'reason' => 'Official Groomings seller account.',
        ];
        if (Schema::hasColumn('seller_applications', 'category')) {
            $applicationData['category'] = 'Personal Care & Grooming';
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
