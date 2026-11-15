<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        if (Schema::hasTable('return_requests')) {
            Schema::table('return_requests', function (Blueprint $table) {
                if (! Schema::hasColumn('return_requests', 'preferred_solution')) {
                    $table->string('preferred_solution', 40)->default('refund')->after('reason');
                }
                if (! Schema::hasColumn('return_requests', 'dispute_status')) {
                    $table->string('dispute_status', 40)->nullable()->after('status');
                }
                if (! Schema::hasColumn('return_requests', 'disputed_at')) {
                    $table->timestamp('disputed_at')->nullable()->after('dispute_status');
                }
                if (! Schema::hasColumn('return_requests', 'dispute_notes')) {
                    $table->text('dispute_notes')->nullable()->after('disputed_at');
                }
                if (! Schema::hasColumn('return_requests', 'resolved_by')) {
                    $table->unsignedBigInteger('resolved_by')->nullable()->after('reviewed_at');
                }
                if (! Schema::hasColumn('return_requests', 'refund_amount')) {
                    $table->decimal('refund_amount', 10, 2)->nullable()->after('resolved_by');
                }
                if (! Schema::hasColumn('return_requests', 'refund_status')) {
                    $table->string('refund_status', 40)->nullable()->after('refund_amount');
                }
                if (! Schema::hasColumn('return_requests', 'refunded_at')) {
                    $table->timestamp('refunded_at')->nullable()->after('refund_status');
                }
            });
        }

        if (Schema::hasTable('orders')) {
            Schema::table('orders', function (Blueprint $table) {
                if (! Schema::hasColumn('orders', 'refund_amount')) {
                    $table->decimal('refund_amount', 10, 2)->nullable();
                }
                if (! Schema::hasColumn('orders', 'refunded_at')) {
                    $table->timestamp('refunded_at')->nullable();
                }
            });
        }
    }

    public function down(): void
    {
        if (Schema::hasTable('return_requests')) {
            Schema::table('return_requests', function (Blueprint $table) {
                $cols = array_values(array_filter([
                    'preferred_solution',
                    'dispute_status',
                    'disputed_at',
                    'dispute_notes',
                    'resolved_by',
                    'refund_amount',
                    'refund_status',
                    'refunded_at',
                ], fn ($col) => Schema::hasColumn('return_requests', $col)));

                if ($cols !== []) {
                    $table->dropColumn($cols);
                }
            });
        }

        if (Schema::hasTable('orders')) {
            Schema::table('orders', function (Blueprint $table) {
                $cols = array_values(array_filter([
                    'refund_amount',
                    'refunded_at',
                ], fn ($col) => Schema::hasColumn('orders', $col)));

                if ($cols !== []) {
                    $table->dropColumn($cols);
                }
            });
        }
    }
};
