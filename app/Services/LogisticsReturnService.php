<?php

namespace App\Services;

use App\Models\Order;
use App\Models\ReturnRequest;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Schema;

class LogisticsReturnService
{
    /**
     * Dispatch an approved return/refund request to Lumora Logistics
     * and automatically assign it to the delivering rider.
     */
    public static function dispatchReturnToLogistics(ReturnRequest $returnRequest, ?string $sellerNote = null): array
    {
        $order = $returnRequest->order;

        // 1. Build the list of return items
        $items = $order->items->map(function ($item) {
            return [
                'id' => $item->id,
                'product_id' => $item->product_id,
                'name' => $item->product?->name ?? 'Product Item',
                'quantity' => (int) $item->quantity,
                'price' => (float) $item->price,
                'subtotal' => round(((float) $item->price) * ((int) $item->quantity), 2),
            ];
        })->values()->all();

        // 2. Identify the delivering rider who delivered this parcel
        $deliveringRiderName = self::resolveDeliveringRiderName($order);
        $deliveringRiderId = null;

        // 3. Build evidence URLs
        $evidence = $returnRequest->evidence->map(function ($ev) use ($returnRequest) {
            return [
                'id' => $ev->id,
                'mime_type' => $ev->mime_type,
                'url' => route('seller.returns.evidence', [$returnRequest, $ev->id]),
            ];
        })->values()->all();

        // 4. Update local logistics tables if they exist in the same database (monolith / shared DB)
        $localUpdated = false;
        if (Schema::hasTable('parcels')) {
            try {
                $localUpdated = self::updateLocalParcel(
                    $order,
                    $returnRequest,
                    $items,
                    $evidence,
                    $sellerNote,
                    $deliveringRiderName,
                    $deliveringRiderId
                );
            } catch (\Throwable $e) {
                Log::warning('LogisticsReturnService::updateLocalParcel error: ' . $e->getMessage());
            }
        }

        // 5. Send HTTP API dispatch to Lumora Logistics service
        $logisticsBaseUrl = rtrim((string) env('LUMORA_LOGISTICS_URL', 'https://logistics.lumora.party'), '/');
        $httpSuccess = false;
        $httpResponseData = [];

        $payload = [
            'order_id' => $order->id,
            'order_number' => $order->order_number,
            'tracking_number' => $order->tracking_number ?: ('LM-TRK-' . str_pad((string) $order->id, 6, '0', STR_PAD_LEFT)),
            'barcode' => (string) $order->id,
            'reason' => $returnRequest->reason,
            'reason_label' => ucwords(str_replace('_', ' ', $returnRequest->reason)),
            'details' => $returnRequest->details,
            'seller_id' => auth()->id(),
            'seller_name' => auth()->user()?->name ?? 'Seller',
            'seller_note' => $sellerNote,
            'approved_at' => now()->toIso8601String(),
            'delivering_rider' => $deliveringRiderName,
            'delivering_rider_id' => $deliveringRiderId,
            'customer' => [
                'name' => $returnRequest->buyer?->name ?? 'Customer',
                'email' => $returnRequest->buyer?->email,
                'phone' => $order->contact_number ?? ($returnRequest->buyer?->contact_number ?? '09170000000'),
                'address' => collect([
                    $order->house_number,
                    $order->street,
                    $order->barangay,
                    $order->municipality,
                    $order->province,
                ])->filter()->implode(', '),
                'city' => $order->municipality ?: 'Pila',
                'province' => $order->province ?: 'Laguna',
            ],
            'items' => $items,
            'evidence' => $evidence,
        ];

        try {
            $response = Http::timeout(6)
                ->acceptJson()
                ->post("{$logisticsBaseUrl}/api/v1/logistics/return-request", $payload);

            if ($response->successful()) {
                $httpSuccess = true;
                $httpResponseData = $response->json();
                if (! empty($httpResponseData['assigned_rider'])) {
                    $deliveringRiderName = $httpResponseData['assigned_rider'];
                }
            } else {
                // Also attempt webhook fallback if dedicated return endpoint returned non-200
                $secret = (string) env('LOGISTICS_WEBHOOK_SECRET', 'demo-webhook-secret');
                $rawPayload = json_encode($payload);
                $signature = hash_hmac('sha256', $rawPayload, $secret);

                $webhookRes = Http::timeout(5)
                    ->withHeaders([
                        'X-Event-Id' => 'return-' . $returnRequest->id . '-' . time(),
                        'X-Event-Type' => 'order.return_approved',
                        'X-Webhook-Signature' => $signature,
                    ])
                    ->post("{$logisticsBaseUrl}/api/v1/webhooks/order-events", $payload);

                $httpSuccess = $webhookRes->successful();
            }
        } catch (\Throwable $e) {
            Log::info('LogisticsReturnService HTTP call non-blocking: ' . $e->getMessage());
        }

        // 6. Update the logistics notification record
        try {
            $returnRequest->logisticsNotification()->updateOrCreate(
                ['return_request_id' => $returnRequest->id],
                [
                    'status' => ($httpSuccess || $localUpdated) ? 'processed' : 'pending',
                    'processed_at' => ($httpSuccess || $localUpdated) ? now() : null,
                ]
            );
        } catch (\Throwable $e) {
            Log::warning('LogisticsReturnService update notification error: ' . $e->getMessage());
        }

        // 7. Record the assigned courier in order status histories for visibility
        try {
            $order->recordStatusUpdate('return_assigned', "Return/Refund approved by seller. Automatically assigned to courier {$deliveringRiderName} for return pickup.", event: [
                'tracking_status' => 'return_assigned',
                'tracking_label' => 'Assigned for Return Pickup',
                'courier_name' => $deliveringRiderName,
                'changed_by' => auth()->id(),
            ]);
        } catch (\Throwable $e) {
            // ignore
        }

        return [
            'success' => $httpSuccess || $localUpdated,
            'courier_name' => $deliveringRiderName,
            'items_count' => count($items),
        ];
    }

    /**
     * Resolve the delivering courier from the order history or parcel records.
     */
    public static function resolveDeliveringRiderName(Order $order): string
    {
        // 1. Look in order status histories where a courier name was recorded
        $historyCourier = $order->statusHistories()
            ->whereNotNull('courier_name')
            ->where('courier_name', '!=', '')
            ->latest('id')
            ->value('courier_name');

        if (! empty($historyCourier)) {
            return trim($historyCourier);
        }

        // 2. Look in the order courier column
        if (! empty($order->courier)) {
            return trim($order->courier);
        }

        // 3. Look in local parcels table if present
        if (Schema::hasTable('parcels') && Schema::hasTable('rider_profiles')) {
            $parcel = DB::table('parcels')
                ->where('order_id', $order->id)
                ->orWhere('parcel_number', $order->order_number)
                ->first();

            if ($parcel && $parcel->assigned_rider_id) {
                $rider = DB::table('rider_profiles')
                    ->join('users', 'users.id', '=', 'rider_profiles.user_id')
                    ->where('rider_profiles.id', $parcel->assigned_rider_id)
                    ->value('users.name');

                if (! empty($rider)) {
                    return trim($rider);
                }
            }
        }

        return 'Assigned Delivery Courier';
    }

    /**
     * Directly update parcel in local database when sharing same database.
     */
    private static function updateLocalParcel(
        Order $order,
        ReturnRequest $returnRequest,
        array $items,
        array $evidence,
        ?string $sellerNote,
        string &$deliveringRiderName,
        ?int &$deliveringRiderId
    ): bool {
        $parcel = DB::table('parcels')
            ->where('order_id', $order->id)
            ->orWhere('parcel_number', $order->order_number)
            ->first();

        if (! $parcel) {
            return false;
        }

        $meta = json_decode($parcel->metadata ?? '{}', true) ?: [];

        // Check assigned rider on parcel
        if (! empty($parcel->assigned_rider_id)) {
            $deliveringRiderId = (int) $parcel->assigned_rider_id;
            $riderUser = DB::table('rider_profiles')
                ->join('users', 'users.id', '=', 'rider_profiles.user_id')
                ->where('rider_profiles.id', $deliveringRiderId)
                ->select('users.name')
                ->first();

            if ($riderUser && ! empty($riderUser->name)) {
                $deliveringRiderName = $riderUser->name;
            }
        } elseif (! empty($deliveringRiderName)) {
            // Find rider profile matching name
            $rider = DB::table('rider_profiles')
                ->join('users', 'users.id', '=', 'rider_profiles.user_id')
                ->where('users.name', 'like', "%{$deliveringRiderName}%")
                ->select('rider_profiles.id', 'users.name')
                ->first();

            if ($rider) {
                $deliveringRiderId = (int) $rider->id;
                $deliveringRiderName = $rider->name;
            }
        }

        $meta['is_return_refund'] = true;
        $meta['return_status'] = 'approved';
        $meta['return_approved_by'] = 'seller';
        $meta['return_approved_at'] = now()->toIso8601String();
        $meta['return_reported_at'] = now()->toIso8601String();
        $meta['return_resolution'] = 'Approved by Seller · Assigned to Courier';
        $meta['return_reason'] = $returnRequest->reason;
        $meta['return_details'] = $returnRequest->details;
        $meta['return_items'] = $items;
        $meta['return_evidence'] = $evidence;
        $meta['seller_note'] = $sellerNote;
        $meta['assigned_rider_name'] = $deliveringRiderName;

        if ($deliveringRiderId) {
            $meta['assigned_rider_id'] = $deliveringRiderId;
            $meta['delivering_rider_id'] = $deliveringRiderId;
        }

        DB::table('parcels')
            ->where('id', $parcel->id)
            ->update([
                'status' => 'returned',
                'assigned_rider_id' => $deliveringRiderId ?: $parcel->assigned_rider_id,
                'metadata' => json_encode($meta),
                'updated_at' => now(),
            ]);

        // Add scan record if table exists
        if (Schema::hasTable('parcel_scans')) {
            DB::table('parcel_scans')->insert([
                'parcel_id' => $parcel->id,
                'user_id' => auth()->id() ?? 1,
                'scan_type' => 'returned',
                'barcode' => $parcel->barcode ?: $parcel->parcel_number,
                'result' => 'success',
                'note' => "Return approved by seller. Automatically assigned to courier {$deliveringRiderName} for return pickup.",
                'scanned_at' => now(),
                'created_at' => now(),
                'updated_at' => now(),
            ]);
        }

        return true;
    }
}
