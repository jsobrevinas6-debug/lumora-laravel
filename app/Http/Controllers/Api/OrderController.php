<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Order;
use App\Models\Product;
use App\Models\ProductReview;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

/**
 * Buyer orders and product reviews for the Lumora mobile app.
 * Mirrors the business logic in Buyer\OrderController and Buyer\ProductReviewController.
 */
class OrderController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $orders = Order::query()
            ->where('user_id', $request->user()->id)
            ->with([
                'items.product',
                'statusHistories',
            ])
            ->latest()
            ->get();

        return response()->json([
            'data' => $orders->map(fn (Order $o) => $this->transformOrder($o))->values(),
        ]);
    }

    public function store(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'payment_method' => ['required', 'string', 'in:cod,gcash,maya'],
            'shipping_address' => ['nullable', 'string', 'max:500'],
            'note_to_seller' => ['nullable', 'string', 'max:1000'],
            'voucher_code' => ['nullable', 'string', 'max:50'],
            'items' => ['required', 'array', 'min:1'],
            'items.*.product_id' => ['required'],
            'items.*.quantity' => ['required', 'integer', 'min:1', 'max:99'],
        ]);

        $paymentMethod = $this->normalizePaymentMethod($validated['payment_method']);

        $order = DB::transaction(function () use ($request, $validated, $paymentMethod) {
            $requestedItems = collect($validated['items']);
            $productIds = $requestedItems->pluck('product_id')->map(fn ($id) => (int) $id)->unique()->values();

            $products = Product::query()
                ->whereIn('id', $productIds)
                ->where('status', 'active')
                ->lockForUpdate()
                ->get()
                ->keyBy('id');

            $lines = collect();
            foreach ($requestedItems as $item) {
                $product = $products->get((int) $item['product_id']);
                $quantity = (int) $item['quantity'];

                if (! $product) {
                    abort(422, 'One of the selected products is no longer available.');
                }

                if ($quantity > (int) $product->stock) {
                    abort(422, "Insufficient stock for {$product->name}.");
                }

                $originalPrice = (float) $product->price;
                $discountPercent = (float) ($product->discount_percent ?? 0);
                $unitPrice = round($originalPrice * (1 - ($discountPercent / 100)), 2);

                $lines->push([
                    'product' => $product,
                    'quantity' => $quantity,
                    'unit_price' => $unitPrice,
                    'line_total' => round($unitPrice * $quantity, 2),
                ]);
            }

            $shipping = 50.0;
            $subtotal = round($lines->sum(fn (array $l) => (float) $l['product']->price * $l['quantity']), 2);
            $discount = round($lines->sum(fn (array $l) => ((float) $l['product']->price - $l['unit_price']) * $l['quantity']), 2);
            $netItems = max(0, round($subtotal - $discount, 2));

            $voucherCode = strtoupper(trim((string) ($validated['voucher_code'] ?? '')));
            $voucherSavings = 0.0;
            $shippingDiscount = 0.0;
            $appliedVoucherCode = null;
            $appliedVoucherType = null;

            if ($voucherCode !== '') {
                $dbVoucher = null;
                try {
                    if (Schema::hasTable('vouchers')) {
                        $dbVoucher = DB::table('vouchers')
                            ->where('code', $voucherCode)
                            ->where('is_active', true)
                            ->whereIn('type', ['percent', 'shipping'])
                            ->where(function ($q) {
                                $q->whereNull('expires_at')->orWhereDate('expires_at', '>=', now()->toDateString());
                            })
                            ->first();
                    }
                } catch (\Throwable) {
                    $dbVoucher = null;
                }

                if ($dbVoucher && $netItems >= (float) ($dbVoucher->min_spend ?? 0)) {
                    $appliedVoucherCode = $voucherCode;
                    $appliedVoucherType = $dbVoucher->type;
                    if ($dbVoucher->type === 'percent') {
                        $voucherSavings = round($netItems * (((float) $dbVoucher->value) / 100), 2);
                    } else {
                        $shippingDiscount = $shipping;
                    }
                } elseif (in_array($voucherCode, ['LUMORA10', 'LUMORA20', 'FREESHIP'], true)) {
                    $appliedVoucherCode = $voucherCode;
                    if ($voucherCode === 'FREESHIP') {
                        $appliedVoucherType = 'shipping';
                        $shippingDiscount = $shipping;
                    } else {
                        $appliedVoucherType = 'percent';
                        $voucherSavings = round($netItems * ($voucherCode === 'LUMORA20' ? 0.20 : 0.10), 2);
                    }
                }
            }

            $discount = round($discount + $voucherSavings, 2);
            $total = max(0, round($subtotal + $shipping - $discount - $shippingDiscount, 2));

            $orderData = [
                'order_number' => $this->generateOrderNumber(),
                'user_id' => $request->user()->id,
                'seller_id' => $lines->pluck('product.seller_id')->filter()->first(),
                'status' => 'pending',
                'payment_status' => 'pending',
                'payment_method' => $paymentMethod,
                'subtotal' => $subtotal,
                'shipping_fee' => $shipping,
                'discount' => $discount,
                'total' => $total,
                'notes' => $validated['note_to_seller'] ?? null,
            ];

            if (Schema::hasColumn('orders', 'buyer_id')) {
                $orderData['buyer_id'] = $request->user()->id;
            }

            if (Schema::hasColumn('orders', 'voucher_code')) {
                $orderData['voucher_code'] = $appliedVoucherCode;
                $orderData['voucher_type'] = $appliedVoucherType;
                $orderData['voucher_discount'] = $voucherSavings;
                $orderData['shipping_discount'] = $shippingDiscount;
            }

            $order = Order::create($orderData);

            $order->updateStatus('pending', 'Order placed via mobile app.', event: [
                'changed_by' => $request->user()->id,
            ]);

            foreach ($lines as $line) {
                $product = $line['product'];

                $order->items()->create([
                    'product_id' => $product->id,
                    'seller_id' => $product->seller_id,
                    'quantity' => $line['quantity'],
                    'price' => $line['unit_price'],
                    'subtotal' => $line['line_total'],
                ]);

                $product->decrement('stock', $line['quantity']);
                $product->increment('sales_count', $line['quantity']);
            }

            return $order->load(['items.product', 'statusHistories']);
        });

        return response()->json([
            'message' => 'Order placed successfully.',
            'data' => $this->transformOrder($order),
        ], 201);
    }

    public function cancel(Request $request, string $orderId): JsonResponse
    {
        $order = $this->findBuyerOrder($request, $orderId);

        if (! in_array($order->status, ['pending', 'processing'], true)) {
            return response()->json(['message' => 'This order can no longer be cancelled.'], 422);
        }

        $reason = trim((string) $request->input('reason', 'Cancelled by buyer'));

        DB::transaction(function () use ($request, $order, $reason) {
            $order->updateStatus('cancelled', 'Order cancelled by buyer: '.$reason, event: [
                'changed_by' => $request->user()->id,
            ]);

            foreach ($order->items as $item) {
                if ($item->product) {
                    $item->product->increment('stock', $item->quantity);
                    $item->product->decrement('sales_count', min((int) $item->product->sales_count, (int) $item->quantity));
                }
            }
        });

        return response()->json(['message' => 'Order cancelled.']);
    }

    public function requestReturn(Request $request, string $orderId): JsonResponse
    {
        $order = $this->findBuyerOrder($request, $orderId);

        $reason = trim((string) $request->input('reason', 'Return requested'));
        $solution = trim((string) $request->input('preferred_solution', 'Refund'));
        $description = trim((string) $request->input('description', ''));

        $order->updateStatus('returned', trim("Return & Refund requested ({$solution}) — {$reason}. {$description}"), event: [
            'changed_by' => $request->user()->id,
        ]);


        return response()->json(['message' => 'Return request submitted.']);
    }

    public function escalateDispute(Request $request, string $orderId): JsonResponse
    {
        $order = $this->findBuyerOrder($request, $orderId);
        $notes = trim((string) $request->input('dispute_notes', ''));
        $order->recordStatusUpdate('disputed', trim('Buyer escalated dispute to Admin. '.$notes), event: [
            'changed_by' => $request->user()->id,
        ]);


        return response()->json(['message' => 'Dispute escalated to Admin.']);
    }

    public function storeReview(Request $request, Product $product): JsonResponse
    {
        abort_unless($product->status === 'active', 404);

        $validated = $request->validate([
            'rating' => ['required', 'integer', 'min:1', 'max:5'],
            'comment' => ['nullable', 'string', 'max:2000'],
            'review' => ['nullable', 'string', 'max:2000'],
        ]);

        $deliveredOrder = Order::query()
            ->where('user_id', $request->user()->id)
            ->where('status', 'delivered')
            ->whereHas('items', fn ($q) => $q->where('product_id', $product->id))
            ->latest('delivered_at')
            ->latest('id')
            ->first();

        if (! $deliveredOrder) {
            return response()->json([
                'message' => 'Only buyers who have received this product can leave a review.',
            ], 422);
        }

        $reviewText = $validated['comment'] ?? $validated['review'] ?? null;

        $review = ProductReview::updateOrCreate(
            [
                'user_id' => $request->user()->id,
                'product_id' => $product->id,
            ],
            [
                'order_id' => $deliveredOrder->id,
                'rating' => $validated['rating'],
                'review' => $reviewText,
            ]
        );

        return response()->json([
            'message' => 'Your review has been saved.',
            'data' => $review,
        ]);
    }

    private function findBuyerOrder(Request $request, string $orderId): Order
    {
        $order = Order::query()
            ->where('user_id', $request->user()->id)
            ->where(function ($q) use ($orderId) {
                $q->where('order_number', $orderId);
                if (ctype_digit($orderId)) {
                    $q->orWhere('id', (int) $orderId);
                }
            })
            ->with('items.product')
            ->first();

        abort_if(! $order, 404, 'Order not found.');

        return $order;
    }

    private function normalizePaymentMethod(string $raw): string
    {
        $lower = strtolower($raw);
        if (str_contains($lower, 'gcash')) {
            return 'gcash';
        }
        if (str_contains($lower, 'maya')) {
            return 'maya';
        }
        return 'cod';
    }

    private function generateOrderNumber(): string
    {
        $next = ((int) Order::query()->max('id')) + 1;

        do {
            $orderNumber = 'LMR-'.now()->year.'-'.str_pad((string) $next, 6, '0', STR_PAD_LEFT);
            $next++;
        } while (Order::query()->where('order_number', $orderNumber)->exists());

        return $orderNumber;
    }

    private function transformOrder(Order $o): array
    {
        $user = $o->user;
        $address = $user
            ? collect([$user->house_number, $user->street, $user->barangay, $user->municipality, $user->province])
                ->filter()
                ->implode(', ')
            : '';

        return [
            'id' => $o->order_number ?: (string) $o->id,
            'order_number' => $o->order_number ?: (string) $o->id,
            'trackingNumber' => $o->tracking_number ?: ('PH-'.($o->order_number ?: $o->id)),
            'createdAt' => $o->created_at?->toIso8601String(),
            'created_at' => $o->created_at?->toIso8601String(),
            'status' => $o->status,
            'totalAmount' => (float) $o->total,
            'total' => (float) $o->total,
            'subtotalAmount' => (float) $o->subtotal,
            'shippingFeeAmount' => (float) $o->shipping_fee,
            'deliveryAddress' => $address ?: 'Philippines',
            'recipientName' => $user?->name ?: 'Customer',
            'paymentMethod' => strtoupper((string) $o->payment_method),
            'courierName' => $o->courier ?: 'Lumora Express Priority',
            'noteToSeller' => $o->notes,
            'voucherCode' => $o->voucher_code,
            'deliveredAt' => $o->delivered_at?->toIso8601String(),
            'items' => $o->items->map(fn ($it) => [
                'productId' => (string) $it->product_id,
                'product_id' => (string) $it->product_id,
                'productName' => $it->product?->name ?? 'Lumora Item',
                'price' => (float) $it->price,
                'quantity' => (int) $it->quantity,
                'imagePath' => $it->product?->image_url,
            ])->values(),
            'statusHistory' => $o->statusHistories->map(fn ($h) => [
                'status' => $h->status,
                'notes' => (string) ($h->note ?? ''),
                'location' => $h->location,
                'trackingStatus' => $h->tracking_status,
                'trackingLabel' => $h->tracking_label,
                'courierName' => $h->courier_name,
                'created_at' => $h->created_at?->toIso8601String(),
            ])->values(),
        ];
    }

    /**
     * Waybill barcode lookup for Lumora Logistics Scanner & Sorting Center.
     * Supports Code 39 Order IDs (*12* -> 12), order_number (LMR-2026-000012), or tracking_number.
     */
    public function waybillLookup(Request $request, string $barcode): JsonResponse
    {
        $cleanCode = trim($barcode);
        $cleanCode = trim($cleanCode, "*# \t\n\r\0\x0B");

        $numericId = null;
        if (is_numeric($cleanCode)) {
            $numericId = (int) $cleanCode;
        } elseif (preg_match('/^(?:ord|order|waybill|lm-trk|ph)[-_]?0*(\d+)$/i', $cleanCode, $matches)) {
            $numericId = (int) $matches[1];
        }

        $hasPaymentMethod = Schema::hasColumn('orders', 'payment_method');
        $hasOrderNumber = Schema::hasColumn('orders', 'order_number');
        $hasTrackingNumber = Schema::hasColumn('orders', 'tracking_number');
        $hasTotal = Schema::hasColumn('orders', 'total');

        $query = DB::table('orders as o')
            ->join('users as u', 'u.id', '=', 'o.user_id')
            ->select(
                'o.id',
                DB::raw($hasOrderNumber ? 'o.order_number' : 'NULL as order_number'),
                'o.status as order_status',
                'o.created_at',
                DB::raw($hasTotal ? 'o.total as order_total' : '0 as order_total'),
                'u.name as buyer_name',
                'u.contact_number',
                'u.province',
                'u.municipality',
                'u.barangay',
                'u.street',
                'u.house_number',
                DB::raw($hasPaymentMethod ? 'o.payment_method' : "'cod' as payment_method")
            );

        $query->where(function ($q) use ($numericId, $cleanCode, $hasOrderNumber, $hasTrackingNumber) {
            if ($numericId !== null) {
                $q->where('o.id', $numericId);
            }
            if ($hasOrderNumber) {
                $q->orWhere('o.order_number', $cleanCode);
            }
            if ($hasTrackingNumber) {
                $q->orWhere('o.tracking_number', $cleanCode);
            }
        });

        $order = $query->first();
        if (! $order) {
            return response()->json([
                'status' => 'not_found',
                'found' => false,
                'message' => "No waybill found for barcode {$cleanCode}.",
            ], 404);
        }

        $rawItems = DB::table('order_items as oi')
            ->join('products as p', 'p.id', '=', 'oi.product_id')
            ->where('oi.order_id', $order->id)
            ->select('oi.*', 'p.name as product_name', 'p.seller_id')
            ->get();

        $shopName = 'Lumora Marketplace';
        if ($rawItems->isNotEmpty()) {
            $sellerId = $rawItems->first()->seller_id ?? null;
            if ($sellerId && Schema::hasTable('seller_applications')) {
                $sellerApp = DB::table('seller_applications')
                    ->where('user_id', $sellerId)
                    ->where('status', 'approved')
                    ->first();
                if ($sellerApp && ! empty($sellerApp->business_name)) {
                    $shopName = $sellerApp->business_name;
                }
            }
        }

        $items = $rawItems->map(fn ($item) => [
            'product_id' => $item->product_id,
            'name' => $item->product_name,
            'qty' => (int) $item->quantity,
            'unit_price' => (float) $item->price,
            'price' => '₱' . number_format((float) $item->price, 2),
            'subtotal' => (float) ($item->price * $item->quantity),
        ]);

        $itemsSum = (float) $items->sum('subtotal');
        $total = (float) ($order->order_total > 0 ? $order->order_total : $itemsSum);
        $paymentMethod = strtolower((string) ($order->payment_method ?? 'cod'));
        $isCod = ($paymentMethod === 'cod');
        $codAmount = $isCod ? $total : 0.0;

        $addressLine = collect([
            $order->house_number ?? null,
            $order->street ?? null,
            $order->barangay ?? null,
            $order->municipality ?? null,
            $order->province ?? null,
        ])->filter()->implode(', ') ?: 'Laguna';

        $itemsSummary = $items->isNotEmpty()
            ? $items->map(fn ($i) => "{$i['qty']}x {$i['name']}")->implode(', ')
            : "Order #{$order->id} Package";

        return response()->json([
            'status' => 'success',
            'found' => true,
            'waybill' => [
                'barcode' => (string) $order->id,
                'order_id' => (int) $order->id,
                'order_number' => $order->order_number ?: ('ORD-' . str_pad((string) $order->id, 5, '0', STR_PAD_LEFT)),
                'order_status' => $order->order_status ?? 'packed',
                'created_at' => $order->created_at,
                'shop_name' => $shopName,
                'recipient_name' => $order->buyer_name ?: 'Lumora Buyer',
                'recipient_phone' => $order->contact_number ?: '09170000000',
                'house_number' => $order->house_number,
                'street' => $order->street,
                'barangay' => $order->barangay,
                'city' => $order->municipality ?: 'Pila',
                'province' => $order->province ?: 'Laguna',
                'postal_code' => null,
                'address_line' => $addressLine,
                'payment_method' => $paymentMethod,
                'is_cod' => $isCod,
                'cod_amount' => $codAmount,
                'total_amount' => $total,
                'items_summary' => $itemsSummary,
                'items' => $items->values()->all(),
            ],
        ]);
    }

    /**
     * Receive status updates from Lumora Logistics (Scanner & Rider App).
     */
    public function waybillStatusUpdate(Request $request, string $barcode): JsonResponse
    {
        $trackingUpdate = $request->validate([
            'status' => ['required', 'string', 'max:40'],
            'label' => ['nullable', 'string', 'max:160'],
            'location' => ['nullable', 'string', 'max:255'],
            'hub' => ['nullable', 'string', 'max:255'],
            'rider_name' => ['nullable', 'string', 'max:120'],
            'operator' => ['nullable', 'string', 'max:120'],
            'note' => ['nullable', 'string', 'max:2000'],
        ]);

        $cleanCode = trim($barcode, "*# \t\n\r\0\x0B");
        $numericId = is_numeric($cleanCode) ? (int) $cleanCode : null;
        if ($numericId === null && preg_match('/(\d+)$/', $cleanCode, $m)) {
            $numericId = (int) $m[1];
        }

        $hasOrderNumber = Schema::hasColumn('orders', 'order_number');
        $query = Order::query();
        $query->where(function ($q) use ($numericId, $cleanCode, $hasOrderNumber) {
            if ($numericId !== null) {
                $q->where('id', $numericId);
            }
            if ($hasOrderNumber) {
                $q->orWhere('order_number', $cleanCode);
            }
        });

        $order = $query->first();
        if (! $order) {
            return response()->json(['status' => 'not_found'], 404);
        }

        $logisticsStatus = strtolower(trim($trackingUpdate['status']));
        $mappedStatus = match ($logisticsStatus) {
            'delivered', 'completed' => 'delivered',
            'cancelled' => 'cancelled',
            'exception', 'failed' => $order->status,
            'out_for_delivery' => 'out_for_delivery',
            'received', 'scanned' => 'processing',
            'sorted', 'assigned' => 'packed',
            'rider_received', 'in_transit' => 'shipped',
            default => 'shipped',
        };

        $statusRank = ['pending' => 0, 'processing' => 1, 'packed' => 2, 'shipped' => 3, 'out_for_delivery' => 4, 'delivered' => 5];
        $isTerminal = in_array($order->status, ['cancelled', 'returned', 'delivered'], true);
        $canAdvance = ! $isTerminal && (($statusRank[$mappedStatus] ?? 0) >= ($statusRank[$order->status] ?? 0)
            || in_array($mappedStatus, ['cancelled'], true));

        $location = $trackingUpdate['location'] ?? ($trackingUpdate['hub'] ?? null);
        $note = $trackingUpdate['note'] ?? "Updated via Lumora Logistics ({$logisticsStatus})";
        $sameRecentEvent = $order->statusHistories()
            ->where('tracking_status', $logisticsStatus)
            ->where('location', $location)
            ->where('note', $note)
            ->where('created_at', '>=', now()->subSeconds(30))
            ->exists();

        if (! $sameRecentEvent && ($canAdvance || $order->status === $mappedStatus)) {
            $order->updateStatus($mappedStatus, $note, $location, [
                'tracking_status' => $logisticsStatus,
                'tracking_label' => $trackingUpdate['label'] ?? \Illuminate\Support\Str::headline($logisticsStatus),
                'courier_name' => $trackingUpdate['rider_name'] ?? ($trackingUpdate['operator'] ?? null),
            ]);
        }

        return response()->json([
            'status' => 'success',
            'order_id' => $order->id,
            'new_status' => $order->fresh()->status,
            'tracking_status' => $logisticsStatus,
        ]);
    }
}
