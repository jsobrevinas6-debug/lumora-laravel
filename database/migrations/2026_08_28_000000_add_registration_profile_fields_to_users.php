<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('users', function (Blueprint $table) {
            // Add only columns that do not already exist in your users table.
            // Remove each line for a column already created by an existing migration.
            if (! Schema::hasColumn('users', 'middle_initial')) {
                $table->string('middle_initial', 4)->nullable();
            }
            if (! Schema::hasColumn('users', 'sex')) {
                $table->string('sex', 20)->nullable();
            }
            if (! Schema::hasColumn('users', 'age')) {
                $table->unsignedTinyInteger('age')->nullable();
            }
            if (! Schema::hasColumn('users', 'province')) {
                $table->string('province')->nullable();
            }
            if (! Schema::hasColumn('users', 'municipality')) {
                $table->string('municipality')->nullable();
            }
            if (! Schema::hasColumn('users', 'barangay')) {
                $table->string('barangay')->nullable();
            }
            if (! Schema::hasColumn('users', 'street')) {
                $table->string('street')->nullable();
            }
            if (! Schema::hasColumn('users', 'house_number')) {
                $table->string('house_number', 100)->nullable();
            }
        });
    }

    public function down(): void
    {
        Schema::table('users', function (Blueprint $table) {
            foreach ([
                'middle_initial', 'sex', 'age', 'province', 'municipality',
                'barangay', 'street', 'house_number',
            ] as $column) {
                if (Schema::hasColumn('users', $column)) {
                    $table->dropColumn($column);
                }
            }
        });
    }
};
