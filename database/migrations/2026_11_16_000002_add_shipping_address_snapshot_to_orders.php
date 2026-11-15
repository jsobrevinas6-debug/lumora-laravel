<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('orders', function (Blueprint $table) {
            if (! Schema::hasColumn('orders', 'shipping_address_id')) {
                $table->foreignId('shipping_address_id')->nullable()->after('user_id')->constrained('user_addresses')->nullOnDelete();
            }
            foreach ([
                'recipient_name' => fn (Blueprint $table) => $table->string('recipient_name')->nullable(),
                'recipient_phone' => fn (Blueprint $table) => $table->string('recipient_phone', 25)->nullable(),
                'shipping_region' => fn (Blueprint $table) => $table->string('shipping_region')->nullable(),
                'shipping_province' => fn (Blueprint $table) => $table->string('shipping_province')->nullable(),
                'shipping_city_municipality' => fn (Blueprint $table) => $table->string('shipping_city_municipality')->nullable(),
                'shipping_barangay' => fn (Blueprint $table) => $table->string('shipping_barangay')->nullable(),
                'shipping_street_address' => fn (Blueprint $table) => $table->string('shipping_street_address')->nullable(),
                'shipping_postal_code' => fn (Blueprint $table) => $table->string('shipping_postal_code', 10)->nullable(),
                'shipping_address_label' => fn (Blueprint $table) => $table->string('shipping_address_label', 20)->nullable(),
            ] as $column => $definition) {
                if (! Schema::hasColumn('orders', $column)) {
                    $definition($table);
                }
            }
        });
    }

    public function down(): void
    {
        Schema::table('orders', function (Blueprint $table) {
            if (Schema::hasColumn('orders', 'shipping_address_id')) {
                $table->dropConstrainedForeignId('shipping_address_id');
            }
            $columns = [
                'recipient_name', 'recipient_phone', 'shipping_region', 'shipping_province',
                'shipping_city_municipality', 'shipping_barangay', 'shipping_street_address',
                'shipping_postal_code', 'shipping_address_label',
            ];
            foreach ($columns as $column) {
                if (Schema::hasColumn('orders', $column)) {
                    $table->dropColumn($column);
                }
            }
        });
    }
};
