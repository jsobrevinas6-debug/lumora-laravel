<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('user_addresses', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained()->cascadeOnDelete();
            $table->string('full_name');
            $table->string('phone_number', 25);
            $table->string('region');
            $table->string('region_code', 20)->nullable();
            $table->string('province');
            $table->string('province_code', 20)->nullable();
            $table->string('city_municipality');
            $table->string('city_municipality_code', 20)->nullable();
            $table->string('barangay');
            $table->string('barangay_code', 20)->nullable();
            $table->string('street_address');
            $table->string('postal_code', 10);
            $table->string('label', 20)->default('home');
            $table->boolean('is_default')->default(false);
            $table->timestamps();
            $table->index(['user_id', 'is_default']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('user_addresses');
    }
};
