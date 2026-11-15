<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('seller_payout_methods', function (Blueprint $table) {
            $table->id();
            $table->foreignId('seller_id')->constrained('users')->cascadeOnDelete();
            $table->enum('method', ['gcash', 'paymaya', 'bank_transfer']);
            $table->string('account_name');
            $table->string('account_number'); // mobile number for gcash/paymaya, account no. for bank
            $table->string('bank_name')->nullable(); // only used when method = bank_transfer
            $table->timestamps();

            $table->unique('seller_id'); // one saved method per seller, keep it simple
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('seller_payout_methods');
    }
};