<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('orders', function (Blueprint $table) {
            if (! Schema::hasColumn('orders', 'delivery_notes')) {
                $table->string('delivery_notes', 200)->nullable();
            }

            if (! Schema::hasColumn('orders', 'checkout_token')) {
                $table->string('checkout_token', 64)->nullable()->unique();
            }
        });
    }

    public function down(): void
    {
        Schema::table('orders', function (Blueprint $table) {
            if (Schema::hasColumn('orders', 'checkout_token')) {
                $table->dropUnique(['checkout_token']);
                $table->dropColumn('checkout_token');
            }

            if (Schema::hasColumn('orders', 'delivery_notes')) {
                $table->dropColumn('delivery_notes');
            }
        });
    }
};
