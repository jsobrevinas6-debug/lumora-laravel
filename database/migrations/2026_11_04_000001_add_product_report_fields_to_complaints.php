<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    public function up(): void
    {
        Schema::table('complaints', function (Blueprint $table) {
            $table->string('complaint_type', 40)->default('customer_complaint');
            $table->foreignId('product_reporter_id')->nullable()->constrained('users')->nullOnDelete();
            $table->unique(['product_id', 'product_reporter_id'], 'complaints_product_reporter_unique');
        });
    }

    public function down(): void
    {
        Schema::table('complaints', function (Blueprint $table) {
            $table->dropUnique('complaints_product_reporter_unique');
            $table->dropForeign(['product_reporter_id']);
            $table->dropColumn(['complaint_type', 'product_reporter_id']);
        });
    }
};
