<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    public function up(): void
    {
        Schema::table('products', function (Blueprint $table) {
            if (! Schema::hasColumn('products', 'approval_note')) $table->text('approval_note')->nullable();
            if (! Schema::hasColumn('products', 'approval_reviewed_by')) $table->foreignId('approval_reviewed_by')->nullable()->constrained('users')->nullOnDelete();
            if (! Schema::hasColumn('products', 'approval_reviewed_at')) $table->timestamp('approval_reviewed_at')->nullable();
            if (! Schema::hasColumn('products', 'submitted_at')) $table->timestamp('submitted_at')->nullable();
        });

        // Products present when this workflow is introduced remain available in the store.
        DB::table('products')->orderBy('id')->chunkById(500, function ($products) {
            foreach ($products as $product) {
                DB::table('products')->where('id', $product->id)->update([
                    'approval_status' => 'approved',
                    'submitted_at' => $product->created_at,
                    'approval_submitted_at' => $product->created_at,
                    'approval_reviewed_at' => now(),
                    'approval_note' => 'Existing product, approved automatically when product approval was introduced',
                    'status' => $product->status === 'archived' ? 'archived' : 'active',
                ]);
            }
        });

        if (! Schema::hasTable('product_approval_logs')) {
            Schema::create('product_approval_logs', function (Blueprint $table) {
                $table->id();
                $table->foreignId('product_id')->constrained()->cascadeOnDelete();
                $table->foreignId('admin_id')->nullable()->constrained('users')->nullOnDelete();
                $table->string('action', 40);
                $table->text('note')->nullable();
                $table->timestamp('created_at')->useCurrent();
                $table->index(['product_id', 'created_at']);
            });

            DB::table('products')->orderBy('id')->chunkById(500, function ($products) {
                $now = now();
                $logs = [];
                foreach ($products as $product) {
                    $logs[] = ['product_id' => $product->id, 'admin_id' => null, 'action' => 'imported_approved', 'note' => 'Imported as approved', 'created_at' => $now];
                }
                if ($logs) DB::table('product_approval_logs')->insert($logs);
            });
        }
    }

    public function down(): void
    {
        Schema::dropIfExists('product_approval_logs');
        Schema::table('products', function (Blueprint $table) {
            foreach (['approval_note', 'approval_reviewed_by', 'approval_reviewed_at', 'submitted_at'] as $column) {
                if (Schema::hasColumn('products', $column)) $table->dropColumn($column);
            }
        });
    }
};
