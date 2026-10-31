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
                'statusHistory' => fn ($q) => $q->oldest(),
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
            'payment_method' => ['required', 'string', 'max:50'],
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

            $shipping = 15.0;
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

            $order->statusHistory()->create([
                'status' => 'pending',
                'remarks' => 'Order Placed via Mobile App',
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

            return $order->load(['items.product', 'statusHistory']);
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
            $order->update([
                'status' => 'cancelled',
                'cancelled_at' => now(),
            ]);

            $order->statusHistory()->create([
                'status' => 'cancelled',
                'remarks' => 'Order cancelled by buyer: '.$reason,
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

        $order->update(['status' => 'returned']);
        $order->statusHistory()->create([
            'status' => 'returned',
            'remarks' => trim("Return & Refund requested ({$solution}) — {$reason}. {$description}"),
            'changed_by' => $request->user()->id,
        ]);

        return response()->json(['message' => 'Return request submitted.']);
    }

    public function escalateDispute(Request $request, string $orderId): JsonResponse
    {
        $order = $this->findBuyerOrder($request, $orderId);
        $notes = trim((string) $request->input('dispute_notes', ''));

        $order->statusHistory()->create([
            'status' => 'disputed',
            'remarks' => trim('Buyer escalated dispute to Admin. '.$notes),
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
        if (str_contains($lower, 'bank')) {
            return 'bank_transfer';
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
            'statusHistory' => $o->statusHistory->map(fn ($h) => [
                'status' => $h->status,
                'notes' => (string) ($h->remarks ?? ''),
                'created_at' => $h->created_at?->toIso8601String(),
            ])->values(),
        ];
    }
}
