<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('platform_policies', function (Blueprint $table) {
            $table->id();
            $table->string('slug')->unique();
            $table->string('title');
            $table->longText('content');
            $table->unsignedInteger('version')->default(1);
            $table->foreignId('updated_by')->nullable()->constrained('users');
            $table->timestamps();
        });

        DB::table('platform_policies')->insert([
            ['slug' => 'terms-of-service', 'title' => 'Terms of Service', 'content' => '', 'version' => 1, 'created_at' => now(), 'updated_at' => now()],
            ['slug' => 'privacy-policy', 'title' => 'Privacy Policy', 'content' => '', 'version' => 1, 'created_at' => now(), 'updated_at' => now()],
            ['slug' => 'seller-agreement', 'title' => 'Seller Agreement', 'content' => '', 'version' => 1, 'created_at' => now(), 'updated_at' => now()],
            ['slug' => 'refund-policy', 'title' => 'Refund Policy', 'content' => '', 'version' => 1, 'created_at' => now(), 'updated_at' => now()],
        ]);
    }

    public function down(): void
    {
        Schema::dropIfExists('platform_policies');
    }
};