<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    public function up(): void
    {
        if (! Schema::hasColumn('products', 'sku')) {
            Schema::table('products', function (Blueprint $table) {
                $table->string('sku', 64)->nullable()->index();
            });
        }
    }

    public function down(): void
    {
        if (Schema::hasColumn('products', 'sku')) {
            Schema::table('products', function (Blueprint $table) {
                $table->dropColumn('sku');
            });
        }
    }
};
