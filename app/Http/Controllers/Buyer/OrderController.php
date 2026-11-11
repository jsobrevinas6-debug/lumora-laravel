<?php

namespace App\Http\Controllers\Buyer;

use App\Http\Controllers\Controller;
use App\Models\Order;
use App\Models\Product;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Illuminate\Validation\ValidationException;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Facades\Storage;
use Illuminate\View\View;

class OrderController extends Controller
{
    private const CART_KEY = 'lumora_cart';
    private const SELECTED_KEY = 'lumora_cart_selected';
    private const BUY_NOW_KEY = 'lumora_buy_now';

    public function index(Request $request): View
    {
        $sortOptions = [
            'latest',
            'oldest',
            'highest',
        ];

        $statuses = ['all', 'pending', 'packed', 'shipped', 'delivered', 'cancelled'];

        $activeStatus = $request->get('status', 'all');

        if (! in_array($activeStatus, $statuses, true)) {
            $activeStatus = 'all';
        }

        $search = trim((string) $request->get('search', ''));
        $sort = $request->get('sort', 'latest');

        if (! in_array($sort, $sortOptions, true)) {
            $sort = 'latest';
        }

        $baseQuery = Order::query()->where('user_id', $request->user()->id);
        $statusCounts = (clone $baseQuery)->selectRaw('status, COUNT(*) as aggregate')->groupBy('status')->pluck('aggregate', 'status');
        $totalOrderCount = (int) $statusCounts->sum();
        $returnRequestsEnabled = Schema::hasTable('return_requests');

        $relations = [
            'items.product:id,name,image,status,stock',
            'items.seller:id,name,role',
        ];
        if ($returnRequestsEnabled) {
            $relations[] = 'returnRequest';
        }

        $query = Order::query()
            ->where('user_id', $request->user()->id)
            ->with($relations);

        if ($activeStatus !== 'all') {
            $query->where('status', $activeStatus);
        }

        if ($search !== '') {
            $query->where(function ($query) use ($search) {
                $query->where('order_number', 'like', "%{$search}%")
                    ->orWhereHas('items.product', function ($productQuery) use ($search) {
                        $productQuery->where('name', 'like', "%{$search}%");
                    });
            });
        }

        match ($sort) {
            'oldest' => $query->oldest(),
            'highest' => $query->orderByDesc('total'),
            default => $query->latest(),
        };

        $orders = $query->orderByDesc('id')->paginate(10)->withQueryString();

        return view('buyer.orders.index', compact(
            'orders',
            'statuses',
            'statusCounts',
            'totalOrderCount',
            'returnRequestsEnabled',
            'activeStatus',
            'search',
            'sort'
        ));
    }

    public function cancel(Request $request, Order $order): RedirectResponse
    {
        abort_unless((int) $order->user_id === (int) $request->user()->id, 404);

        DB::transaction(function () use ($order, $request) {
            $lockedOrder = Order::query()->lockForUpdate()->with('items.product')->findOrFail($order->id);
            abort_unless($lockedOrder->status === 'pending', 422, 'Only pending orders can be cancelled.');

            foreach ($lockedOrder->items as $item) {
                if ($item->product) {
                    $item->product->increment('stock', $item->quantity);
                    $item->product->decrement('sales_count', min((int) $item->quantity, (int) $item->product->sales_count));
                }
            }

            $lockedOrder->updateStatus('cancelled', 'Cancelled by buyer.', event: [
                'changed_by' => $request->user()->id,
            ]);
        });

        return redirect()->route('buyer.orders.index')->with('success', 'Your order was cancelled.');
    }

    public function reorder(Request $request, Order $order): RedirectResponse
    {
        abort_unless((int) $order->user_id === (int) $request->user()->id, 404);
        abort_unless($order->status === 'delivered', 422, 'Only delivered orders can be reordered.');

        $order->load('items.product');
        $cart = $request->session()->get(self::CART_KEY, []);
        $selected = collect($request->session()->get(self::SELECTED_KEY, []))->map(fn ($id) => (int) $id);
        $added = 0;

        foreach ($order->items as $item) {
            $product = $item->product;
            if (! $product || $product->status !== 'active' || (int) $product->stock < 1) {
                continue;
            }

            $key = (string) $product->id;
            $quantity = min((int) $item->quantity, (int) $product->stock);
            $cart[$key] = ['quantity' => min((int) ($cart[$key]['quantity'] ?? 0) + $quantity, (int) $product->stock)];
            $selected->push((int) $product->id);
            $added++;
        }

        $request->session()->put(self::CART_KEY, $cart);
        $request->session()->put(self::SELECTED_KEY, $selected->unique()->values()->all());

        if ($added === 0) {
            return redirect()->route('buyer.orders.show', $order)->with('error', 'The products in this order are currently unavailable.');
        }

        return redirect()->route('buyer.cart')->with('success', 'Available items from this order were added to your cart.');
    }

    public function requestReturn(Request $request, Order $order): RedirectResponse
    {
        abort_unless(Schema::hasTable('return_requests'), 503, 'Return requests are temporarily unavailable.');
        abort_unless($order->user_id === $request->user()->id, 404);
        abort_unless($order->status === 'delivered', 422, 'Return requests are available for delivered orders only.');
        abort_if($order->returnRequest()->exists(), 409, 'A return request has already been submitted for this order.');

        $validated = $request->validate([
            'reason' => ['required', 'in:damaged,wrong_item,missing_items,not_as_described,changed_mind,other'],
            'details' => ['required', 'string', 'min:10', 'max:2000'],
            'evidence' => ['nullable', 'array', 'max:5'],
            'evidence.*' => ['file', 'mimes:jpg,jpeg,png,webp,mp4,mov,webm', 'max:51200'],
        ]);

        DB::transaction(function () use ($request, $order, $validated) {
            $returnRequest = $order->returnRequest()->create([
                'buyer_id' => $request->user()->id,
                'reason' => $validated['reason'],
                'details' => $validated['details'],
            ]);

            foreach ($request->file('evidence', []) as $file) {
                $returnRequest->evidence()->create([
                    'file_path' => $file->store('return_request_evidence', 'local'),
                    'mime_type' => $file->getMimeType(),
                ]);
            }

            $order->recordStatusUpdate('return_requested', 'Buyer submitted a return/refund request (' . ucwords(str_replace('_', ' ', $validated['reason'])) . '). Awaiting seller review.', event: [
                'tracking_status' => 'return_requested',
                'tracking_label' => 'Return Requested',
                'changed_by' => $request->user()->id,
            ]);
        });

        return redirect()->route('buyer.orders.index')->with('success', 'Your return/refund request has been submitted for review.');
    }

    public function create(Request $request): View|RedirectResponse
    {
        $checkoutMode = $request->routeIs('buyer.buy-now.checkout') ? 'buy_now' : 'cart';
        $items = $checkoutMode === 'buy_now' ? $this->buyNowItems($request) : $this->selectedItems($request);
        $oldQuantities = (array) $request->old('quantities', []);
        $items = $items->map(function (array $item) use ($oldQuantities) {
            $quantity = (int) ($oldQuantities[$item['product_id']] ?? $oldQuantities[(string) $item['product_id']] ?? $item['quantity']);
            if ($quantity >= 1 && $quantity <= (int) $item['product']->stock) {
                $item['quantity'] = $quantity;
                $item['line_discount'] = round(($item['original_price'] - $item['unit_price']) * $quantity, 2);
                $item['line_total'] = round($item['unit_price'] * $quantity, 2);
            }

            return $item;
        });
        $cartPaymentOption = $request->input('cart_payment_option', 'cod');

        if (! in_array($cartPaymentOption, ['cod', 'wallet'], true)) {
            $cartPaymentOption = 'cod';
        }

        $request->session()->put('cart_payment_option', $cartPaymentOption);

        if ($items->isEmpty()) {
            if ($checkoutMode === 'buy_now') {
                return redirect()
                    ->route('shop.index')
                    ->with('error', 'Choose an available product before checkout.');
            }

            return redirect()
                ->route('buyer.cart')
                ->with('error', 'Select at least one product before checkout.');
        }

        $activeVouchers = [];
        $unavailableVouchers = [];
        try {
            if (Schema::hasTable('vouchers')) {
                $rows = DB::table('vouchers')->whereIn('type', ['percent', 'shipping'])->get();
                foreach ($rows as $row) {
                    $codeKey = strtoupper(trim((string) $row->code));
                    $reason = null;
                    if (! $row->is_active) {
                        $reason = 'This voucher is currently unavailable.';
                    } elseif ($row->expires_at && $row->expires_at < now()->toDateString()) {
                        $reason = 'This voucher has expired.';
                    } elseif ($row->usage_limit !== null && (int) $row->used_count >= (int) $row->usage_limit) {
                        $reason = 'This voucher has already been fully used.';
                    }
                    $voucherData = [
                        'type' => $row->type,
                        'value' => (float) $row->value,
                        'min_spend' => (float) ($row->min_spend ?? 0),
                        'label' => $row->type === 'percent'
                            ? (rtrim(rtrim(number_format((float) $row->value, 2), '0'), '.').'% OFF')
                            : 'Free Shipping',
                        'error' => $reason,
                    ];
                    if ($reason) {
                        $unavailableVouchers[$codeKey] = $voucherData;
                    } else {
                        $activeVouchers[$codeKey] = $voucherData;
                    }
                }
            }
        } catch (\Throwable $e) {
            // Ignore if table is not available in this environment.
        }
        return view('buyer.checkout', [
            'cartItems' => $items,
            'summary' => $this->summary($items),
            'buyer' => $request->user(),
            'cartPaymentOption' => $cartPaymentOption,
            'checkoutMode' => $checkoutMode,
            'activeVouchers' => $activeVouchers,
            'unavailableVouchers' => $unavailableVouchers,
            'checkoutToken' => bin2hex(random_bytes(32)),
            'formattedPhone' => $this->formatPhilippinePhone($request->user()->contact_number),
            'addressReturnTo' => $checkoutMode === 'buy_now' ? route('buyer.buy-now.checkout') : route('buyer.cart.checkout'),
            'returnUrl' => $checkoutMode === 'buy_now'
                ? route('shop.product', ['id' => $items->first()['product_id']])
                : route('buyer.cart'),
            'paymentMethods' => $request->user()
                ->paymentMethods()
                ->whereIn('type', ['gcash', 'maya'])
                ->orderByDesc('is_default')
                ->latest()
                ->get(),
        ]);
    }

    public function buyNow(Request $request, Product $product): RedirectResponse
    {
        abort_unless($product->status === 'active', 404);

        $validated = $request->validate([
            'quantity' => ['required', 'integer', 'min:1'],
        ]);

        $quantity = (int) $validated['quantity'];

        if ($quantity > (int) $product->stock) {
            return back()
                ->with('error', 'The requested quantity is not available.')
                ->withInput();
        }

        $request->session()->put(self::BUY_NOW_KEY, [
            'product_id' => $product->id,
            'quantity' => $quantity,
        ]);

        return redirect()->route('buyer.buy-now.checkout');
    }

    public function store(Request $request): RedirectResponse
    {
        $validated = $request->validate([
            'checkout_mode' => ['nullable', 'string', 'in:cart,buy_now'],
            'checkout_token' => ['required', 'string', 'regex:/^[a-f0-9]{64}$/'],
            'payment_method' => ['required', 'string', 'in:cod,gcash,maya'],
            'payment_method_id' => ['nullable', 'integer'],
            'payment_proof' => ['required_if:payment_method,gcash,maya', 'nullable', 'image', 'mimes:jpg,jpeg,png,webp', 'max:5120'],
            'payment_reference_last6' => ['required_if:payment_method,gcash,maya', 'nullable', 'regex:/^\d{6}$/'],
            'voucher_code' => ['nullable', 'string', 'max:50'],
            'delivery_notes' => ['nullable', 'string', 'max:200'],
            'quantities' => ['nullable', 'array'],
            'quantities.*' => ['required', 'integer', 'min:1', 'max:99'],
        ]);

        $checkoutToken = $validated['checkout_token'];
        $existingOrder = Order::query()->where('user_id', $request->user()->id)->where('checkout_token', $checkoutToken)->first();
        if ($existingOrder) {
            return redirect()->route('buyer.orders.show', $existingOrder)->with('success', 'This order was already placed.');
        }

        $selectedWallet = null;
        if ($validated['payment_method'] === 'cod' && ! empty($validated['payment_method_id'])) {
            return back()->withErrors(['payment_method_id' => 'Cash on Delivery cannot use a saved wallet.'])->withInput();
        }

        if (! empty($validated['payment_method_id'])) {
            $selectedWallet = $request->user()->paymentMethods()
                ->whereIn('type', ['gcash', 'maya'])
                ->find($validated['payment_method_id']);

            if (! $selectedWallet || $selectedWallet->type !== $validated['payment_method']) {
                return back()->withErrors(['payment_method_id' => 'Select a saved GCash or Maya wallet that matches your payment method.'])->withInput();
            }
        }

        if ($validated['payment_method'] === 'cod') {
            $selectedWallet = null;
        }

        $checkoutMode = $validated['checkout_mode'] ?? 'cart';
        $voucherCode = strtoupper(trim((string) ($validated['voucher_code'] ?? '')));

        try {
            $order = DB::transaction(function () use ($request, $validated, $selectedWallet, $checkoutMode, $checkoutToken, $voucherCode) {
                $quantities = (array) ($validated['quantities'] ?? []);
                $lines = $checkoutMode === 'buy_now'
                    ? $this->buyNowOrderLines($request, $quantities)
                    : $this->cartOrderLines($request, $quantities);
                $totals = $this->calculateCheckoutTotals($lines, $voucherCode, true);

                $paymentProofPath = in_array($validated['payment_method'], ['gcash', 'maya'], true)
                    ? $request->file('payment_proof')?->store('payment-proofs', config('filesystems.payment_proof_disk'))
                    : null;

                $orderData = [
                    'order_number' => $this->generateOrderNumber(),
                    'checkout_token' => $checkoutToken,
                    'user_id' => $request->user()->id,
                    'seller_id' => $lines->pluck('product.seller_id')->filter()->first(),
                    'status' => 'pending',
                    'payment_status' => 'pending',
                    'payment_method' => $validated['payment_method'],
                    'payment_method_id' => $selectedWallet?->id,
                    'payment_proof_path' => $paymentProofPath,
                    'payment_reference_last6' => in_array($validated['payment_method'], ['gcash', 'maya'], true)
                        ? $validated['payment_reference_last6']
                        : null,
                    'subtotal' => $totals['subtotal'],
                    'shipping_fee' => $totals['shipping'],
                    'discount' => $totals['discount'],
                    'total' => $totals['total'],
                    'delivery_notes' => trim((string) ($validated['delivery_notes'] ?? '')) ?: null,
                ];

                if (Schema::hasColumn('orders', 'buyer_id')) {
                    $orderData['buyer_id'] = $request->user()->id;
                }
                if (Schema::hasColumn('orders', 'voucher_code')) {
                    $orderData['voucher_code'] = $totals['voucher_code'];
                    $orderData['voucher_type'] = $totals['voucher_type'];
                    $orderData['voucher_discount'] = $totals['voucher_savings'];
                    $orderData['shipping_discount'] = $totals['shipping_discount'];
                }

                $order = Order::create($orderData);
                if ($totals['voucher_id']) {
                    DB::table('vouchers')->where('id', $totals['voucher_id'])->increment('used_count');
                }
                $order->updateStatus('pending', 'Order placed.');

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

                if ($checkoutMode === 'buy_now') {
                    $request->session()->forget(self::BUY_NOW_KEY);
                } else {
                    $selectedIds = $lines->pluck('product.id')->map(fn ($id) => (int) $id);
                    $storedCart = $request->session()->get(self::CART_KEY, []);
                    $remainingCart = collect($storedCart)->reject(fn ($item, $id) => $selectedIds->contains((int) $id))->all();
                    $request->session()->put(self::CART_KEY, $remainingCart);
                    $request->session()->put(self::SELECTED_KEY, []);
                }

                return $order;
            });
        } catch (\Illuminate\Database\QueryException $exception) {
            $order = Order::query()->where('user_id', $request->user()->id)->where('checkout_token', $checkoutToken)->first();
            if (! $order) {
                throw $exception;
            }
        }

        $redirect = in_array($validated['payment_method'], ['gcash', 'maya'], true)
            ? redirect()->route('buyer.orders.index', ['status' => 'pending'])
            : redirect()->route('buyer.orders.show', $order);

        return $redirect->with('success', 'Order Successful');
    }
    public function show(Request $request, Order $order): View
    {
        abort_unless((int) $order->user_id === (int) $request->user()->id, 403);

        $order->load([
            'items.product',
            'statusHistories.changedBy',
        ]);

        $proofDisk = Storage::disk(config('filesystems.payment_proof_disk'));
        $order->setAttribute('payment_proof_available', (bool) $order->payment_proof_path && $proofDisk->exists($order->payment_proof_path));

        return view('buyer.order-success', compact('order'));
    }

    public function track(Request $request, Order $order): View
    {
        abort_unless((int) $order->user_id === (int) $request->user()->id, 404);

        $returnRequestsEnabled = Schema::hasTable('return_requests');
        $relations = ['user', 'seller', 'items.product', 'items.seller', 'statusHistories'];
        if ($returnRequestsEnabled) {
            $relations[] = 'returnRequest';
        }
        $order->load($relations);
        $cartCount = collect($request->session()->get(self::CART_KEY, []))->sum('quantity');

        return view('buyer.orders.track', compact('order', 'cartCount', 'returnRequestsEnabled'));
    }

    public function replacePaymentProof(Request $request, Order $order): RedirectResponse
    {
        abort_unless((int) $order->user_id === (int) $request->user()->id, 403);
        abort_unless(
            in_array($order->payment_method, ['gcash', 'maya', 'paymaya'], true)
            && $order->payment_status === 'pending'
            && $order->status === 'pending',
            422,
            'Only pending e-wallet orders can update their payment proof.'
        );

        $validated = $request->validate([
            'payment_proof' => ['required', 'image', 'mimes:jpg,jpeg,png,webp', 'max:5120'],
            'payment_reference_last6' => ['required', 'regex:/^\\d{6}$/'],
        ]);

        $diskName = config('filesystems.payment_proof_disk');
        $disk = Storage::disk($diskName);
        $previousPath = $order->payment_proof_path;
        $newPath = $request->file('payment_proof')->store('payment-proofs', $diskName);

        if (! $newPath) {
            return back()->withErrors(['payment_proof' => 'The receipt could not be saved. Please try again.'])->withInput();
        }

        $order->update([
            'payment_proof_path' => $newPath,
            'payment_reference_last6' => $validated['payment_reference_last6'],
        ]);

        if ($previousPath && $previousPath !== $newPath && $disk->exists($previousPath)) {
            $disk->delete($previousPath);
        }

        return redirect()->route('buyer.orders.show', $order)->with('success', 'Your payment receipt was submitted for review.');
    }

    private function selectedItems(Request $request)
    {
        $storedCart = $request->session()->get(self::CART_KEY, []);

        $selectedIds = collect($request->session()->get(self::SELECTED_KEY, []))
            ->map(fn ($id) => (int) $id)
            ->unique()
            ->values();

        if ($selectedIds->isEmpty()) {
            return collect();
        }

        $products = Product::query()
            ->whereIn('id', $selectedIds)
            ->where('status', 'active')
            ->get()
            ->keyBy('id');

        return $selectedIds->map(function (int $productId) use ($storedCart, $products) {
            $product = $products->get($productId);
            $quantity = (int) ($storedCart[(string) $productId]['quantity'] ?? 0);

            if (! $product || $quantity < 1) {
                return null;
            }

            return $this->orderLine($product, $quantity);
        })->filter()->values();
    }

    private function buyNowItems(Request $request)
    {
        $payload = $request->session()->get(self::BUY_NOW_KEY);

        if (! is_array($payload)) {
            return collect();
        }

        $product = Product::query()
            ->where('status', 'active')
            ->find((int) ($payload['product_id'] ?? 0));

        $quantity = (int) ($payload['quantity'] ?? 0);

        if (! $product || $quantity < 1 || $quantity > (int) $product->stock) {
            return collect();
        }

        return collect([$this->orderLine($product, $quantity)]);
    }

    private function cartOrderLines(Request $request, array $quantities = [])
    {
        $storedCart = $request->session()->get(self::CART_KEY, []);

        $selectedIds = collect($request->session()->get(self::SELECTED_KEY, []))
            ->map(fn ($id) => (int) $id)
            ->unique()
            ->values();

        if ($selectedIds->isEmpty()) {
            abort(422, 'Select at least one product before checkout.');
        }

        $products = Product::query()
            ->whereIn('id', $selectedIds)
            ->where('status', 'active')
            ->lockForUpdate()
            ->get()
            ->keyBy('id');

        $lines = collect();

        foreach ($selectedIds as $productId) {
            $product = $products->get($productId);
            $quantity = (int) ($quantities[$productId] ?? $quantities[(string) $productId] ?? $storedCart[(string) $productId]['quantity'] ?? 0);

            if (! $product || $quantity < 1) {
                abort(422, 'One of the selected products is no longer available.');
            }

            if ($quantity > (int) $product->stock) {
                abort(422, "Insufficient stock for {$product->name}.");
            }

            $lines->push($this->orderLine($product, $quantity));
        }

        return $lines;
    }

    private function buyNowOrderLines(Request $request, array $quantities = [])
    {
        $payload = $request->session()->get(self::BUY_NOW_KEY);

        if (! is_array($payload)) {
            abort(422, 'Choose an available product before checkout.');
        }

        $product = Product::query()
            ->where('status', 'active')
            ->whereKey((int) ($payload['product_id'] ?? 0))
            ->lockForUpdate()
            ->first();

        $productId = (int) ($payload['product_id'] ?? 0);
        $quantity = (int) ($quantities[$productId] ?? $quantities[(string) $productId] ?? $payload['quantity'] ?? 0);

        if (! $product || $quantity < 1) {
            abort(422, 'The selected product is no longer available.');
        }

        if ($quantity > (int) $product->stock) {
            abort(422, "Insufficient stock for {$product->name}.");
        }

        return collect([$this->orderLine($product, $quantity)]);
    }

    private function orderLine(Product $product, int $quantity): array
    {
        $originalPrice = (float) $product->price;
        $discountPercent = (float) ($product->discount_percent ?? 0);
        $unitPrice = round($originalPrice * (1 - ($discountPercent / 100)), 2);

        return [
            'product' => $product,
            'product_id' => $product->id,
            'quantity' => $quantity,
            'original_price' => $originalPrice,
            'unit_price' => $unitPrice,
            'line_discount' => round(($originalPrice - $unitPrice) * $quantity, 2),
            'line_total' => round($unitPrice * $quantity, 2),
        ];
    }

    private function summary($items): array
    {
        return $this->calculateCheckoutTotals($items);
    }

    private function calculateCheckoutTotals($items, string $voucherCode = '', bool $lockVoucher = false): array
    {
        $subtotal = round($items->sum(fn (array $item) => (float) $item['original_price'] * (int) $item['quantity']), 2);
        $productDiscount = round($items->sum(fn (array $item) => (float) $item['line_discount']), 2);
        $netItems = max(0, round($subtotal - $productDiscount, 2));
        $shipping = $items->isEmpty() ? 0.0 : 50.0;
        $voucherSavings = 0.0;
        $shippingDiscount = 0.0;
        $voucher = null;
        $voucherType = null;

        if ($voucherCode !== '') {
            if (Schema::hasTable('vouchers')) {
                $query = DB::table('vouchers')->where('code', $voucherCode);
                if ($lockVoucher) {
                    $query->lockForUpdate();
                }
                $voucher = $query->first();
            }

            if ($voucher) {
                if (! $voucher->is_active) {
                    throw ValidationException::withMessages(['voucher_code' => 'This voucher is currently unavailable.']);
                }
                if ($voucher->expires_at && $voucher->expires_at < now()->toDateString()) {
                    throw ValidationException::withMessages(['voucher_code' => 'This voucher has expired.']);
                }
                if ($voucher->usage_limit !== null && (int) $voucher->used_count >= (int) $voucher->usage_limit) {
                    throw ValidationException::withMessages(['voucher_code' => 'This voucher has already been fully used.']);
                }
                if ($netItems < (float) ($voucher->min_spend ?? 0)) {
                    throw ValidationException::withMessages(['voucher_code' => 'The minimum spend for this voucher has not been met.']);
                }

                $voucherType = $voucher->type;
                if ($voucherType === 'percent') {
                    $voucherSavings = round($netItems * ((float) $voucher->value / 100), 2);
                } elseif ($voucherType === 'shipping') {
                    $shippingDiscount = $shipping;
                } else {
                    throw ValidationException::withMessages(['voucher_code' => 'This voucher is invalid.']);
                }
            } elseif (in_array($voucherCode, ['LUMORA10', 'LUMORA20', 'FREESHIP'], true)) {
                $voucherType = $voucherCode === 'FREESHIP' ? 'shipping' : 'percent';
                $voucherSavings = $voucherType === 'percent'
                    ? round($netItems * ($voucherCode === 'LUMORA20' ? 0.20 : 0.10), 2)
                    : 0.0;
                $shippingDiscount = $voucherType === 'shipping' ? $shipping : 0.0;
            } else {
                throw ValidationException::withMessages(['voucher_code' => 'This voucher code is invalid.']);
            }
        }

        $discount = round($productDiscount + $voucherSavings, 2);

        return [
            'item_count' => (int) $items->sum('quantity'),
            'subtotal' => $subtotal,
            'product_discount' => $productDiscount,
            'voucher_savings' => $voucherSavings,
            'discount' => $discount,
            'shipping' => $shipping,
            'shipping_discount' => $shippingDiscount,
            'total_savings' => round($discount + $shippingDiscount, 2),
            'total' => max(0, round($subtotal + $shipping - $discount - $shippingDiscount, 2)),
            'voucher_id' => $voucher?->id,
            'voucher_code' => $voucherCode !== '' ? $voucherCode : null,
            'voucher_type' => $voucherType,
        ];
    }

    private function formatPhilippinePhone(?string $phone): string
    {
        $digits = preg_replace('/\D+/', '', (string) $phone);
        if (str_starts_with($digits, '63')) {
            $digits = '0'.substr($digits, 2);
        } elseif (strlen($digits) === 10 && str_starts_with($digits, '9')) {
            $digits = '0'.$digits;
        }

        if (strlen($digits) === 11 && str_starts_with($digits, '0')) {
            return substr($digits, 0, 4).' '.substr($digits, 4, 3).' '.substr($digits, 7, 4);
        }

        return trim(chunk_split($digits, 4, ' '));
    }

    private function generateOrderNumber(): string
    {
        $next = ((int) Order::query()->max('id')) + 1;

        do {
            $orderNumber = 'LMR-' . now()->year . '-' . str_pad((string) $next, 6, '0', STR_PAD_LEFT);
            $next++;
        } while (Order::query()->where('order_number', $orderNumber)->exists());

        return $orderNumber;
    }
}
