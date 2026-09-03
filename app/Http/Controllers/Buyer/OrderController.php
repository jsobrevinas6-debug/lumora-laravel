<?php

namespace App\Http\Controllers\Buyer;

use App\Http\Controllers\Controller;
use App\Models\Order;
use App\Models\Product;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\View\View;

class OrderController extends Controller
{
    private const CART_KEY = 'lumora_cart';
    private const SELECTED_KEY = 'lumora_cart_selected';

    public function create(Request $request): View|RedirectResponse
    {
        $items = $this->selectedItems($request);

        if ($items->isEmpty()) {
            return redirect()
                ->route('buyer.cart')
                ->with('error', 'Select at least one product before checkout.');
        }

        return view('buyer.checkout', [
            'cartItems' => $items,
            'summary' => $this->summary($items),
            'buyer' => $request->user(),
        ]);
    }

    public function store(Request $request): RedirectResponse
    {
        $request->validate([
            'payment_method' => ['required', 'in:cod'],
        ]);

        $order = DB::transaction(function () use ($request) {
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
                $quantity = (int) ($storedCart[(string) $productId]['quantity'] ?? 0);

                if (! $product || $quantity < 1) {
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

            $shipping = 15;
            $total = round($lines->sum('line_total') + $shipping, 2);

            $order = Order::create([
                'buyer_id' => $request->user()->id,
                'status' => 'pending',
                'total' => $total,
            ]);

            foreach ($lines as $line) {
                $product = $line['product'];

                $order->items()->create([
                    'product_id' => $product->id,
                    'quantity' => $line['quantity'],
                    'price' => $line['unit_price'],
                ]);

                $product->decrement('stock', $line['quantity']);
                $product->increment('sales_count', $line['quantity']);
            }

            $remainingCart = collect($storedCart)
                ->reject(fn ($item, $id) => $selectedIds->contains((int) $id))
                ->all();

            $request->session()->put(self::CART_KEY, $remainingCart);
            $request->session()->put(self::SELECTED_KEY, []);

            return $order;
        });

        return redirect()
            ->route('buyer.orders.show', $order)
            ->with('success', 'Your order has been placed successfully.');
    }

    public function show(Request $request, Order $order): View
    {
        abort_unless((int) $order->buyer_id === (int) $request->user()->id, 403);

        $order->load('items.product');

        return view('buyer.order-success', compact('order'));
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
        })->filter()->values();
    }

    private function summary($items): array
    {
        return [
            'item_count' => (int) $items->sum('quantity'),
            'subtotal' => round($items->sum(fn (array $item) => $item['original_price'] * $item['quantity']), 2),
            'discount' => round($items->sum('line_discount'), 2),
            'shipping' => $items->isEmpty() ? 0 : 15,
            'total' => round($items->sum('line_total') + ($items->isEmpty() ? 0 : 15), 2),
        ];
    }
}