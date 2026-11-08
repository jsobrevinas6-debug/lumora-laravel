<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('return_requests', function (Blueprint $table) {
            $table->id();
            $table->foreignId('order_id')->constrained()->cascadeOnDelete();
            $table->foreignId('buyer_id')->constrained('users')->cascadeOnDelete();
            $table->string('reason');
            $table->text('details');
            $table->string('status')->default('pending');
            $table->text('admin_note')->nullable();
            $table->timestamp('reviewed_at')->nullable();
            $table->timestamps();
            $table->unique('order_id');
        });

        Schema::create('return_request_evidence', function (Blueprint $table) {
            $table->id();
            $table->foreignId('return_request_id')->constrained()->cascadeOnDelete();
            $table->string('file_path');
            $table->string('mime_type');
            $table->timestamps();
        });

        Schema::create('logistics_return_notifications', function (Blueprint $table) {
            $table->id();
            $table->foreignId('return_request_id')->unique()->constrained()->cascadeOnDelete();
            $table->string('status')->default('pending');
            $table->timestamp('created_at')->useCurrent();
            $table->timestamp('processed_at')->nullable();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('logistics_return_notifications');
        Schema::dropIfExists('return_request_evidence');
        Schema::dropIfExists('return_requests');
    }
};
