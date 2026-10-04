<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('conversations', function (Blueprint $table) {
            if (! Schema::hasColumn('conversations', 'buyer_id')) {
                $table->foreignId('buyer_id')->nullable()->after('user_id')->constrained('users')->nullOnDelete();
            }

            if (! Schema::hasColumn('conversations', 'seller_id')) {
                $table->foreignId('seller_id')->nullable()->after('buyer_id')->constrained('users')->nullOnDelete();
            }

            if (! Schema::hasColumn('conversations', 'product_id')) {
                $table->foreignId('product_id')->nullable()->after('seller_id')->constrained('products')->nullOnDelete();
            }

            $table->unique(['buyer_id', 'seller_id'], 'conversations_buyer_seller_unique');
            $table->index('last_message_at');
        });

        Schema::table('messages', function (Blueprint $table) {
            if (! Schema::hasColumn('messages', 'read_at')) {
                $table->timestamp('read_at')->nullable()->after('is_read');
            }

            $table->index(['conversation_id', 'read_at']);
            $table->index('sender_id');
        });
    }

    public function down(): void
    {
        Schema::table('messages', function (Blueprint $table) {
            $table->dropIndex(['conversation_id', 'read_at']);
            $table->dropIndex(['sender_id']);

            if (Schema::hasColumn('messages', 'read_at')) {
                $table->dropColumn('read_at');
            }
        });

        Schema::table('conversations', function (Blueprint $table) {
            $table->dropUnique('conversations_buyer_seller_unique');
            $table->dropIndex(['last_message_at']);

            foreach (['product_id', 'seller_id', 'buyer_id'] as $column) {
                if (Schema::hasColumn('conversations', $column)) {
                    $table->dropConstrainedForeignId($column);
                }
            }
        });
    }
};
