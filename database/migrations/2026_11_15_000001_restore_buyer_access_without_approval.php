<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        if (! Schema::hasTable('users') || ! Schema::hasColumn('users', 'approval_status')) {
            return;
        }

        // Seller accounts and seller_applications retain their current review state.
        DB::table('users')->where(function ($query) {
            $query->whereNull('role')->orWhere('role', '!=', 'seller');
        })->update(['approval_status' => 'approved']);
    }

    public function down(): void
    {
        // Intentionally preserve buyer access when rolling back this data migration.
    }
};
