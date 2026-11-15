<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        if (Schema::hasTable('users')) {
            Schema::table('users', function (Blueprint $table) {
                $table->string('status')->default('active')->change();
                if (! Schema::hasColumn('users', 'suspended_until')) {
                    $table->timestamp('suspended_until')->nullable()->index();
                }
                if (! Schema::hasColumn('users', 'last_login_at')) {
                    $table->timestamp('last_login_at')->nullable()->index();
                }
            });
        }

        if (! Schema::hasTable('user_status_logs')) {
            Schema::create('user_status_logs', function (Blueprint $table) {
                $table->id();
                $table->foreignId('user_id')->constrained()->cascadeOnDelete();
                $table->foreignId('admin_id')->nullable()->constrained('users')->nullOnDelete();
                $table->string('action', 32);
                $table->string('reason')->nullable();
                $table->text('note')->nullable();
                $table->timestamp('until')->nullable();
                $table->timestamp('created_at')->useCurrent();
                $table->index(['user_id', 'created_at']);
            });
        }
    }

    public function down(): void
    {
        Schema::dropIfExists('user_status_logs');
        if (Schema::hasTable('users')) {
            Schema::table('users', function (Blueprint $table) {
                if (Schema::hasColumn('users', 'suspended_until')) $table->dropColumn('suspended_until');
                if (Schema::hasColumn('users', 'last_login_at')) $table->dropColumn('last_login_at');
                // Keep status as a string to avoid truncating newer account states.
            });
        }
    }
};
