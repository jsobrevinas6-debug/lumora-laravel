<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
    public function up(): void
    {
        DB::transaction(function (): void {
            DB::table('orders as o')
                ->whereIn('o.status', ['pending', 'processing'])
                ->whereExists(function ($query): void {
                    $query->selectRaw('1')
                        ->from('order_items as oi')
                        ->whereColumn('oi.order_id', 'o.id')
                        ->whereNotNull('oi.packed_at');
                })
                ->select('o.id')
                ->chunkById(100, function ($orders): void {
                    $orderIds = $orders->pluck('id');
                    $now = now();

                    DB::table('orders')
                        ->whereIn('id', $orderIds)
                        ->update([
                            'status' => 'packed',
                            'updated_at' => $now,
                        ]);

                    $existingHistory = DB::table('order_status_history')
                        ->whereIn('order_id', $orderIds)
                        ->where('status', 'packed')
                        ->pluck('order_id')
                        ->all();

                    $historyRows = $orderIds
                        ->diff($existingHistory)
                        ->map(fn (int $orderId): array => [
                            'order_id' => $orderId,
                            'status' => 'packed',
                            'remarks' => 'Order status synchronized from packed seller items.',
                            'changed_by' => null,
                            'created_at' => $now,
                            'updated_at' => $now,
                        ])
                        ->values()
                        ->all();

                    if ($historyRows !== []) {
                        DB::table('order_status_history')->insert($historyRows);
                    }
                }, 'o.id', 'id');
        });
    }

    public function down(): void
    {
        //
    }
};
