<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        $hasLegacyBuyerId = Schema::hasColumn('orders', 'buyer_id');
        $orderItemsNeedSellerId = ! Schema::hasColumn('order_items', 'seller_id');

        Schema::table('orders', function (Blueprint $table) use ($hasLegacyBuyerId) {
            if (! Schema::hasColumn('orders', 'order_number')) {
                $table->string('order_number')->nullable()->unique()->after('id');
            }

            if (! Schema::hasColumn('orders', 'user_id')) {
                $table->foreignId('user_id')->nullable()->after('order_number')->constrained('users')->cascadeOnDelete();
            }

            if (! Schema::hasColumn('orders', 'seller_id')) {
                $table->foreignId('seller_id')->nullable()->after('user_id')->constrained('users')->nullOnDelete();
            }

            if (! Schema::hasColumn('orders', 'payment_status')) {
                $table->enum('payment_status', ['pending', 'paid', 'failed', 'refunded'])->default('pending')->after('status');
            }

            if (! Schema::hasColumn('orders', 'payment_method')) {
                $table->string('payment_method')->nullable()->after('payment_status');
            }

            if (! Schema::hasColumn('orders', 'subtotal')) {
                $table->decimal('subtotal', 10, 2)->default(0)->after('payment_method');
            }

            if (! Schema::hasColumn('orders', 'shipping_fee')) {
                $table->decimal('shipping_fee', 10, 2)->default(0)->after('subtotal');
            }

            if (! Schema::hasColumn('orders', 'discount')) {
                $table->decimal('discount', 10, 2)->default(0)->after('shipping_fee');
            }

            if (! Schema::hasColumn('orders', 'tracking_number')) {
                $table->string('tracking_number')->nullable()->after('total')->index();
            }

            if (! Schema::hasColumn('orders', 'courier')) {
                $table->string('courier')->nullable()->after('tracking_number');
            }

            if (! Schema::hasColumn('orders', 'estimated_delivery')) {
                $table->timestamp('estimated_delivery')->nullable()->after('courier');
            }

            if (! Schema::hasColumn('orders', 'delivered_at')) {
                $table->timestamp('delivered_at')->nullable()->after('estimated_delivery');
            }

            if (! Schema::hasColumn('orders', 'cancelled_at')) {
                $table->timestamp('cancelled_at')->nullable()->after('delivered_at');
            }

            if (! Schema::hasColumn('orders', 'notes')) {
                $table->text('notes')->nullable()->after('cancelled_at');
            }

            if ($hasLegacyBuyerId) {
                $table->index('status', 'orders_status_index');
                $table->index(['user_id', 'status'], 'orders_user_id_status_index');
            }
        });

        $this->backfillOrders();

        Schema::table('order_items', function (Blueprint $table) use ($orderItemsNeedSellerId) {
            if (! Schema::hasColumn('order_items', 'seller_id')) {
                $table->foreignId('seller_id')->nullable()->after('product_id')->constrained('users')->nullOnDelete();
            }

            if (! Schema::hasColumn('order_items', 'subtotal')) {
                $table->decimal('subtotal', 10, 2)->default(0)->after('price');
            }

            if (! Schema::hasColumn('order_items', 'seen_at')) {
                $table->timestamp('seen_at')->nullable()->after('subtotal');
            }

            if (! Schema::hasColumn('order_items', 'packed_at')) {
                $table->timestamp('packed_at')->nullable()->after('seen_at');
            }

            if ($orderItemsNeedSellerId) {
                $table->index(['order_id', 'seller_id'], 'order_items_order_id_seller_id_index');
            }
        });

        $this->backfillOrderItems();
        $this->normalizeOrderStatusEnum();
        $this->addMissingIndexes();
    }

    public function down(): void
    {
        if (! Schema::hasColumn('orders', 'buyer_id')) {
            return;
        }

        Schema::table('order_items', function (Blueprint $table) {
            if (Schema::hasColumn('order_items', 'seller_id')) {
                $table->dropForeign(['seller_id']);
            }

            foreach (['packed_at', 'seen_at', 'subtotal', 'seller_id'] as $column) {
                if (Schema::hasColumn('order_items', $column)) {
                    $table->dropColumn($column);
                }
            }
        });

        Schema::table('orders', function (Blueprint $table) {
            foreach (['user_id', 'seller_id'] as $column) {
                if (Schema::hasColumn('orders', $column)) {
                    $table->dropForeign([$column]);
                }
            }

            foreach ([
                'notes',
                'cancelled_at',
                'delivered_at',
                'estimated_delivery',
                'courier',
                'tracking_number',
                'discount',
                'shipping_fee',
                'subtotal',
                'payment_method',
                'payment_status',
                'seller_id',
                'user_id',
                'order_number',
            ] as $column) {
                if (Schema::hasColumn('orders', $column)) {
                    $table->dropColumn($column);
                }
            }
        });
    }

    private function backfillOrders(): void
    {
        if (Schema::hasColumn('orders', 'buyer_id') && Schema::hasColumn('orders', 'user_id')) {
            DB::table('orders')->whereNull('user_id')->update([
                'user_id' => DB::raw('buyer_id'),
            ]);
        }

        if (Schema::hasColumn('orders', 'order_number')) {
            DB::table('orders')
                ->whereNull('order_number')
                ->orderBy('id')
                ->select('id', 'created_at')
                ->chunkById(100, function ($orders): void {
                    foreach ($orders as $order) {
                        $year = $order->created_at ? date('Y', strtotime((string) $order->created_at)) : now()->year;

                        DB::table('orders')->where('id', $order->id)->update([
                            'order_number' => 'LMR-'.$year.'-'.str_pad((string) $order->id, 6, '0', STR_PAD_LEFT),
                        ]);
                    }
                });
        }

        if (Schema::hasColumn('orders', 'payment_status')) {
            DB::table('orders')->where('status', 'paid')->update(['payment_status' => 'paid']);
            DB::table('orders')->where('status', 'completed')->update(['payment_status' => 'paid']);
            DB::table('orders')->where('status', 'cancelled')->update(['payment_status' => 'pending']);
        }

        if (Schema::hasColumn('orders', 'payment_method')) {
            DB::table('orders')->whereNull('payment_method')->update(['payment_method' => 'cod']);
        }

        if (Schema::hasColumn('orders', 'subtotal')) {
            DB::table('orders')->where('subtotal', 0)->update([
                'subtotal' => DB::raw('total'),
            ]);
        }
    }

    private function backfillOrderItems(): void
    {
        if (Schema::hasColumn('order_items', 'seller_id')) {
            DB::table('order_items')
                ->whereNull('seller_id')
                ->whereNotNull('product_id')
                ->orderBy('id')
                ->select('id', 'product_id')
                ->chunkById(100, function ($items): void {
                    $productIds = $items->pluck('product_id')->filter()->unique()->all();

                    $sellerIds = DB::table('products')
                        ->whereIn('id', $productIds)
                        ->pluck('seller_id', 'id');

                    foreach ($items as $item) {
                        $sellerId = $sellerIds[$item->product_id] ?? null;

                        if ($sellerId !== null) {
                            DB::table('order_items')
                                ->where('id', $item->id)
                                ->update(['seller_id' => $sellerId]);
                        }
                    }
                });
        }

        if (Schema::hasColumn('order_items', 'subtotal')) {
            DB::table('order_items')->where('subtotal', 0)->update([
                'subtotal' => DB::raw('price * quantity'),
            ]);
        }

        if (Schema::hasColumn('orders', 'seller_id')) {
            DB::table('orders')
                ->whereNull('seller_id')
                ->orderBy('id')
                ->select('id')
                ->chunkById(100, function ($orders): void {
                    $orderIds = $orders->pluck('id')->all();

                    $sellerIds = DB::table('order_items')
                        ->whereIn('order_id', $orderIds)
                        ->whereNotNull('seller_id')
                        ->orderBy('id')
                        ->get(['order_id', 'seller_id'])
                        ->groupBy('order_id')
                        ->map(fn ($items) => $items->first()->seller_id);

                    foreach ($orders as $order) {
                        $sellerId = $sellerIds[$order->id] ?? null;

                        if ($sellerId !== null) {
                            DB::table('orders')
                                ->where('id', $order->id)
                                ->update(['seller_id' => $sellerId]);
                        }
                    }
                });
        }
    }

    private function normalizeOrderStatusEnum(): void
    {
        DB::table('orders')->where('status', 'paid')->update(['status' => 'processing']);
        DB::table('orders')->where('status', 'completed')->update(['status' => 'delivered']);

        if (DB::getDriverName() === 'mysql') {
            DB::statement("ALTER TABLE orders MODIFY status ENUM('pending','processing','packed','shipped','out_for_delivery','delivered','cancelled','returned') NOT NULL DEFAULT 'pending'");
            DB::statement('ALTER TABLE orders MODIFY order_number VARCHAR(255) NOT NULL');
            DB::statement('ALTER TABLE orders MODIFY user_id BIGINT UNSIGNED NOT NULL');
            DB::statement('ALTER TABLE orders MODIFY payment_method VARCHAR(255) NOT NULL');
        }
    }

    private function addMissingIndexes(): void
    {
        if (DB::getDriverName() !== 'mysql') {
            return;
        }

        if (! $this->indexExists('orders', 'orders_status_index')) {
            DB::statement('CREATE INDEX orders_status_index ON orders (status)');
        }

        if (! $this->indexExists('orders', 'orders_user_id_status_index')) {
            DB::statement('CREATE INDEX orders_user_id_status_index ON orders (user_id, status)');
        }

        if (! $this->indexExists('order_items', 'order_items_order_id_seller_id_index')) {
            DB::statement('CREATE INDEX order_items_order_id_seller_id_index ON order_items (order_id, seller_id)');
        }
    }

    private function indexExists(string $table, string $index): bool
    {
        return (bool) DB::table('information_schema.statistics')
            ->where('table_schema', DB::raw('DATABASE()'))
            ->where('table_name', $table)
            ->where('index_name', $index)
            ->exists();
    }
};
