<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    public function up(): void
    {
        Schema::table('seller_applications', function (Blueprint $table) {
            if (! Schema::hasColumn('seller_applications', 'category')) {
                $table->string('category')->nullable();
            }
            if (! Schema::hasColumn('seller_applications', 'id_document')) {
                $table->string('id_document')->nullable();
            }
            if (! Schema::hasColumn('seller_applications', 'business_permit')) {
                $table->string('business_permit')->nullable();
            }
            if (! Schema::hasColumn('seller_applications', 'reviewed_at')) {
                $table->timestamp('reviewed_at')->nullable();
            }
            if (! Schema::hasColumn('seller_applications', 'reviewed_by')) {
                $table->foreignId('reviewed_by')->nullable()->constrained('users')->nullOnDelete();
            }
            if (! Schema::hasColumn('seller_applications', 'rejection_reason')) {
                $table->string('rejection_reason', 100)->nullable();
            }
            if (! Schema::hasColumn('seller_applications', 'admin_note')) {
                $table->text('admin_note')->nullable();
            }
        });

        DB::table('seller_applications')
            ->whereIn('status', ['approved', 'rejected'])
            ->whereNull('reviewed_at')
            ->update(['reviewed_at' => DB::raw('updated_at')]);
    }

    public function down(): void
    {
        Schema::table('seller_applications', function (Blueprint $table) {
            if (Schema::hasColumn('seller_applications', 'reviewed_by')) {
                $table->dropForeign(['reviewed_by']);
            }
            $columns = array_filter(['reviewed_at', 'reviewed_by', 'rejection_reason', 'admin_note'], fn (string $column) => Schema::hasColumn('seller_applications', $column));
            if ($columns !== []) {
                $table->dropColumn($columns);
            }
        });
    }
};
