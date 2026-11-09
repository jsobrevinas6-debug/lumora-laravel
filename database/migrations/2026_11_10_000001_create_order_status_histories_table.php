<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('orders', function (Blueprint $table) {
            if (! Schema::hasColumn('orders', 'tracking_number')) {
                $table->string('tracking_number')->nullable();
            }
            if (! Schema::hasColumn('orders', 'courier')) {
                $table->string('courier')->nullable();
            }
            if (! Schema::hasColumn('orders', 'estimated_delivery')) {
                $table->date('estimated_delivery')->nullable();
            }
        });

        if (! Schema::hasTable('order_status_histories')) {
            Schema::create('order_status_histories', function (Blueprint $table) {
                $table->id();
                $table->foreignId('order_id')->constrained('orders')->cascadeOnDelete();
                $table->string('status', 40);
                $table->text('note')->nullable();
                $table->string('location', 255)->nullable();
                $table->string('tracking_status', 40)->nullable();
                $table->string('tracking_label', 160)->nullable();
                $table->string('courier_name', 120)->nullable();
                $table->foreignId('changed_by')->nullable()->constrained('users')->nullOnDelete();
                $table->timestamps();
                $table->index(['order_id', 'created_at']);
            });
        } else {
            Schema::table('order_status_histories', function (Blueprint $table) {
                if (! Schema::hasColumn('order_status_histories', 'note')) {
                    $table->text('note')->nullable();
                }
                if (! Schema::hasColumn('order_status_histories', 'location')) {
                    $table->string('location', 255)->nullable();
                }
                if (! Schema::hasColumn('order_status_histories', 'tracking_status')) {
                    $table->string('tracking_status', 40)->nullable();
                }
                if (! Schema::hasColumn('order_status_histories', 'tracking_label')) {
                    $table->string('tracking_label', 160)->nullable();
                }
                if (! Schema::hasColumn('order_status_histories', 'courier_name')) {
                    $table->string('courier_name', 120)->nullable();
                }
                if (! Schema::hasColumn('order_status_histories', 'changed_by')) {
                    $table->foreignId('changed_by')->nullable()->constrained('users')->nullOnDelete();
                }
            });
        }

        $this->copyLegacyHistory('order_status_history', 'remarks');
        $this->copyLegacyHistory('order_status_histories', 'notes', true);
        $this->backfillCurrentOrderStatuses();
    }

    public function down(): void
    {
        Schema::dropIfExists('order_status_histories');
    }

    private function copyLegacyHistory(string $tableName, string $noteColumn, bool $isTargetTable = false): void
    {
        if (! Schema::hasTable($tableName)) {
            return;
        }

        $columns = Schema::getColumnListing($tableName);
        if (! in_array('order_id', $columns, true) || ! in_array('status', $columns, true)) {
            return;
        }

        $source = DB::table($tableName)->orderBy('id');
        $source->chunkById(200, function ($rows) use ($columns, $noteColumn, $isTargetTable): void {
            foreach ($rows as $row) {
                $values = (array) $row;
                if ($isTargetTable && isset($values['note'])) {
                    continue;
                }

                $note = $values[$noteColumn] ?? $values['note'] ?? null;
                $trackingStatus = $values['tracking_status'] ?? null;
                $createdAt = $values['created_at'] ?? now();
                $duplicate = DB::table('order_status_histories')
                    ->where('order_id', $values['order_id'])
                    ->where('status', $values['status'])
                    ->where('created_at', $createdAt)
                    ->exists();

                if ($duplicate) {
                    continue;
                }

                DB::table('order_status_histories')->insert([
                    'order_id' => $values['order_id'],
                    'status' => $values['status'],
                    'note' => $note,
                    'location' => $values['location'] ?? null,
                    'tracking_status' => $trackingStatus,
                    'tracking_label' => $values['tracking_label'] ?? null,
                    'courier_name' => $values['courier_name'] ?? null,
                    'changed_by' => $values['changed_by'] ?? null,
                    'created_at' => $createdAt,
                    'updated_at' => $values['updated_at'] ?? $createdAt,
                ]);
            }
        });
    }

    private function backfillCurrentOrderStatuses(): void
    {
        DB::table('orders')
            ->select(['id', 'status'])
            ->orderBy('id')
            ->chunkById(200, function ($orders): void {
                foreach ($orders as $order) {
                    $latest = DB::table('order_status_histories')
                        ->where('order_id', $order->id)
                        ->orderByDesc('created_at')
                        ->orderByDesc('id')
                        ->first();

                    if ($latest && strtolower((string) $latest->status) === strtolower((string) $order->status)) {
                        continue;
                    }

                    DB::table('order_status_histories')->insert([
                        'order_id' => $order->id,
                        'status' => $order->status,
                        'note' => 'Current status synchronized from the order record.',
                        'created_at' => now(),
                        'updated_at' => now(),
                    ]);
                }
            });
    }
};
