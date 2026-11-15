<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        if (Schema::hasTable('products')) {
            Schema::table('products', function (Blueprint $table) {
                if (! Schema::hasColumn('products', 'discount_percent')) {
                    $table->decimal('discount_percent', 5, 1)->default(0)->after('price');
                }
                if (! Schema::hasColumn('products', 'variant_type')) {
                    $table->string('variant_type', 100)->nullable()->after('stock');
                }
            });
        }

        if (! Schema::hasTable('order_items')) {
            return;
        }

        Schema::table('order_items', function (Blueprint $table) {
            if (! Schema::hasColumn('order_items', 'variant_id')) {
                $table->unsignedBigInteger('variant_id')->nullable()->after('product_id');
            }
            if (! Schema::hasColumn('order_items', 'variant_name')) {
                $table->string('variant_name', 255)->nullable()->after('variant_id');
            }
        });
    }

    public function down(): void
    {
        if (! Schema::hasTable('order_items')) {
            return;
        }

        Schema::table('order_items', function (Blueprint $table) {
            if (Schema::hasColumn('order_items', 'variant_name')) {
                $table->dropColumn('variant_name');
            }
            if (Schema::hasColumn('order_items', 'variant_id')) {
                $table->dropColumn('variant_id');
            }
        });
    }
};
