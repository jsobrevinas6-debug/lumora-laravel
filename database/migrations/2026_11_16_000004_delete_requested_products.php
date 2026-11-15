<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        if (! Schema::hasTable('products')) {
            return;
        }

        // The user requested to remove:
        // "the ball", "charcoal soap bar", "lavender body butter", "and the 2 rose clay mask"
        $products = DB::table('products')
            ->where(function ($query) {
                $query->whereRaw('LOWER(TRIM(name)) LIKE ?', ['%ball%'])
                    ->orWhereRaw('LOWER(TRIM(name)) LIKE ?', ['%charcoal soap%'])
                    ->orWhereRaw('LOWER(TRIM(name)) LIKE ?', ['%lavender body butter%'])
                    ->orWhereRaw('LOWER(TRIM(name)) LIKE ?', ['%rose clay mask%']);
            })
            ->get();

        if ($products->isEmpty()) {
            return;
        }

        $productIds = $products->pluck('id')->all();

        // 1. Product Variants
        if (Schema::hasTable('product_variants')) {
            DB::table('product_variants')->whereIn('product_id', $productIds)->delete();
        }

        // 2. Product Reviews
        if (Schema::hasTable('product_reviews')) {
            DB::table('product_reviews')->whereIn('product_id', $productIds)->delete();
        }

        // 3. Saved Products / Wishlist
        if (Schema::hasTable('saved_products')) {
            DB::table('saved_products')->whereIn('product_id', $productIds)->delete();
        }

        // 4. Product Approval Logs
        if (Schema::hasTable('product_approval_logs')) {
            DB::table('product_approval_logs')->whereIn('product_id', $productIds)->delete();
        }

        // 5. Complaints and Complaint Evidence
        if (Schema::hasTable('complaint_evidence') && Schema::hasTable('complaints')) {
            $complaintIds = DB::table('complaints')->whereIn('product_id', $productIds)->pluck('id');
            if ($complaintIds->isNotEmpty()) {
                DB::table('complaint_evidence')->whereIn('complaint_id', $complaintIds)->delete();
            }
        }
        if (Schema::hasTable('complaints')) {
            DB::table('complaints')->whereIn('product_id', $productIds)->delete();
        }

        // 6. Conversations
        if (Schema::hasTable('conversations') && Schema::hasColumn('conversations', 'product_id')) {
            DB::table('conversations')->whereIn('product_id', $productIds)->update(['product_id' => null]);
        }

        // 7. Order Items
        if (Schema::hasTable('order_items')) {
            $affectedOrderIds = DB::table('order_items')
                ->whereIn('product_id', $productIds)
                ->pluck('order_id')
                ->unique()
                ->all();

            DB::table('order_items')->whereIn('product_id', $productIds)->delete();

            // Check if any orders now have zero order items left, and remove them cleanly
            if (Schema::hasTable('orders') && !empty($affectedOrderIds)) {
                $emptyOrders = DB::table('orders')
                    ->whereIn('id', $affectedOrderIds)
                    ->whereNotExists(function ($query) {
                        $query->select(DB::raw(1))
                            ->from('order_items')
                            ->whereColumn('order_items.order_id', 'orders.id');
                    })
                    ->pluck('id')
                    ->all();

                if (!empty($emptyOrders)) {
                    if (Schema::hasTable('order_status_history')) {
                        DB::table('order_status_history')->whereIn('order_id', $emptyOrders)->delete();
                    }
                    if (Schema::hasTable('order_status_histories')) {
                        DB::table('order_status_histories')->whereIn('order_id', $emptyOrders)->delete();
                    }
                    if (Schema::hasTable('return_requests')) {
                        DB::table('return_requests')->whereIn('order_id', $emptyOrders)->delete();
                    }
                    DB::table('orders')->whereIn('id', $emptyOrders)->delete();
                }
            }
        }

        // 8. Delete the products
        DB::table('products')->whereIn('id', $productIds)->delete();
    }

    public function down(): void
    {
        // No-op
    }
};
