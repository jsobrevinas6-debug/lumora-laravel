<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        if (! Schema::hasTable('order_status_history')) {
            return;
        }

        Schema::table('order_status_history', function (Blueprint $table) {
            if (! Schema::hasColumn('order_status_history', 'tracking_status')) {
                $table->string('tracking_status', 40)->nullable();
            }
            if (! Schema::hasColumn('order_status_history', 'tracking_label')) {
                $table->string('tracking_label', 160)->nullable();
            }
            if (! Schema::hasColumn('order_status_history', 'location')) {
                $table->string('location', 255)->nullable();
            }
            if (! Schema::hasColumn('order_status_history', 'courier_name')) {
                $table->string('courier_name', 120)->nullable();
            }
        });
    }

    public function down(): void
    {
        if (! Schema::hasTable('order_status_history')) {
            return;
        }

        Schema::table('order_status_history', function (Blueprint $table) {
            foreach (['tracking_status', 'tracking_label', 'location', 'courier_name'] as $column) {
                if (Schema::hasColumn('order_status_history', $column)) {
                    $table->dropColumn($column);
                }
            }
        });
    }
};
