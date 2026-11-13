<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('users', function (Blueprint $table) {
            $table->string('approval_status')->default('approved');
            $table->foreignId('approval_reviewed_by')->nullable()->constrained('users')->nullOnDelete();
            $table->timestamp('approval_reviewed_at')->nullable();
            $table->text('approval_rejection_reason')->nullable();
            $table->string('id_type')->nullable();
            $table->string('id_file_path')->nullable();
            $table->timestamp('approval_archived_at')->nullable();
        });

        // All accounts that existed before this feature remain able to log in.
        DB::table('users')->update(['approval_status' => 'approved']);
    }

    public function down(): void
    {
        Schema::table('users', function (Blueprint $table) {
            $table->dropForeign(['approval_reviewed_by']);
            $table->dropColumn([
                'approval_status', 'approval_reviewed_by', 'approval_reviewed_at',
                'approval_rejection_reason', 'id_type', 'id_file_path', 'approval_archived_at',
            ]);
        });
    }
};
