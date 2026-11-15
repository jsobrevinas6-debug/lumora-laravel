<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('products', function (Blueprint $table) {
            $table->index(['approval_status', 'status', 'category', 'price'], 'products_shop_category_price_idx');
            $table->index(['approval_status', 'status', 'discount_percent', 'stock'], 'products_shop_offer_stock_idx');
            $table->index(['approval_status', 'status', 'sales_count'], 'products_shop_sales_idx');
        });

        Schema::table('product_reviews', function (Blueprint $table) {
            $table->index(['product_id', 'rating'], 'product_reviews_product_rating_idx');
        });
    }

    public function down(): void
    {
        Schema::table('product_reviews', function (Blueprint $table) {
            $table->dropIndex('product_reviews_product_rating_idx');
        });
        Schema::table('products', function (Blueprint $table) {
            $table->dropIndex('products_shop_category_price_idx');
            $table->dropIndex('products_shop_offer_stock_idx');
            $table->dropIndex('products_shop_sales_idx');
        });
    }
};
