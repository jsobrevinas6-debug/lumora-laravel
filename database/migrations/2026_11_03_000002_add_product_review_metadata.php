<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    public function up(): void
    {
        Schema::table('products', function (Blueprint $table) {
            foreach (['approval_submitted_at', 'approved_at', 'rejected_at'] as $column) {
                if (! Schema::hasColumn('products', $column)) {
                    $table->timestamp($column)->nullable();
                }
            }

            if (! Schema::hasColumn('products', 'rejection_reason')) {
                $table->string('rejection_reason', 80)->nullable();
            }

            if (! Schema::hasColumn('products', 'rejection_note')) {
                $table->text('rejection_note')->nullable();
            }
        });
    }

    public function down(): void
    {
        Schema::table('products', function (Blueprint $table) {
            $columns = array_filter(
                ['approval_submitted_at', 'approved_at', 'rejected_at', 'rejection_reason', 'rejection_note'],
                fn (string $column) => Schema::hasColumn('products', $column)
            );

            if ($columns !== []) {
                $table->dropColumn($columns);
            }
        });
    }
};
