<?php

namespace Database\Seeders;

use App\Models\Order;
use App\Models\Product;
use App\Models\User;
use Illuminate\Database\Seeder;
use Illuminate\Support\Carbon;
use Illuminate\Support\Collection;

class OrderSeeder extends Seeder
{
    /**
     * @var array<int, array{status: string, remarks: string}>
     */
    private array $timelineRemarks = [
        ['status' => 'pending', 'remarks' => 'Order Placed'],
        ['status' => 'processing', 'remarks' => 'Payment Confirmed'],
        ['status' => 'processing', 'remarks' => 'Preparing Order'],
        ['status' => 'packed', 'remarks' => 'Packed'],
        ['status' => 'shipped', 'remarks' => 'Shipped'],
        ['status' => 'out_for_delivery', 'remarks' => 'Out for Delivery'],
        ['status' => 'delivered', 'remarks' => 'Delivered'],
    ];

    public function run(): void
    {
        $buyers = User::query()->where('role', 'buyer')->get();
        $products = Product::query()->where('status', 'active')->get();
        $sellers = User::query()->where('role', 'seller')->pluck('id');

        if ($buyers->isEmpty() || $products->isEmpty()) {
            return;
        }

        $sequence = Order::query()->count() + 1;

        $buyers->each(function (User $buyer) use ($products, $sellers, &$sequence): void {
            foreach (range(1, fake()->numberBetween(1, 8)) as $_) {
                $createdAt = Carbon::instance(fake()->dateTimeBetween('-90 days', '-1 day'));
                $status = $this->realisticStatus();
                $selectedProducts = $products->random(min(fake()->numberBetween(1, 5), $products->count()));
                $selectedProducts = $selectedProducts instanceof Collection ? $selectedProducts : collect([$selectedProducts]);
                $orderSellerId = $selectedProducts->pluck('seller_id')->filter()->first() ?? $sellers->first();

                $lines = $selectedProducts->map(function (Product $product): array {
                    $quantity = fake()->numberBetween(1, 4);
                    $price = (float) $product->price;

                    return [
                        'product' => $product,
                        'quantity' => $quantity,
                        'price' => $price,
                        'subtotal' => round($price * $quantity, 2),
                    ];
                });

                $subtotal = round($lines->sum('subtotal'), 2);
                $shippingFee = $subtotal >= 2500 ? 0 : fake()->randomElement([49, 75, 99, 150]);
                $discount = fake()->boolean(35) ? round(min($subtotal * fake()->randomFloat(2, 0.05, 0.15), 750), 2) : 0;
                $total = round($subtotal + $shippingFee - $discount, 2);
                $trackingNumber = in_array($status, ['shipped', 'out_for_delivery', 'delivered', 'returned'], true)
                    ? 'LMRTRK'.$createdAt->format('Y').str_pad((string) $sequence, 6, '0', STR_PAD_LEFT)
                    : null;

                $order = Order::query()->create([
                    'order_number' => 'LMR-'.$createdAt->format('Y').'-'.str_pad((string) $sequence, 6, '0', STR_PAD_LEFT),
                    'user_id' => $buyer->id,
                    'seller_id' => $orderSellerId,
                    'status' => $status,
                    'payment_status' => $this->paymentStatusFor($status),
                    'payment_method' => fake()->randomElement(['cod', 'gcash', 'maya', 'card']),
                    'subtotal' => $subtotal,
                    'shipping_fee' => $shippingFee,
                    'discount' => $discount,
                    'total' => $total,
                    'tracking_number' => $trackingNumber,
                    'courier' => $trackingNumber ? fake()->randomElement(['LBC', 'J&T Express', 'Ninja Van', 'Flash Express']) : null,
                    'estimated_delivery' => in_array($status, ['cancelled', 'returned'], true) ? null : $createdAt->copy()->addDays(fake()->numberBetween(3, 9)),
                    'delivered_at' => in_array($status, ['delivered', 'returned'], true) ? $createdAt->copy()->addDays(fake()->numberBetween(3, 8)) : null,
                    'cancelled_at' => $status === 'cancelled' ? $createdAt->copy()->addHours(fake()->numberBetween(2, 48)) : null,
                    'notes' => fake()->optional(0.2)->sentence(),
                    'created_at' => $createdAt,
                    'updated_at' => $createdAt,
                ]);

                $lines->each(function (array $line) use ($order, $createdAt): void {
                    $order->items()->create([
                        'product_id' => $line['product']->id,
                        'seller_id' => $line['product']->seller_id,
                        'quantity' => $line['quantity'],
                        'price' => $line['price'],
                        'subtotal' => $line['subtotal'],
                        'created_at' => $createdAt,
                        'updated_at' => $createdAt,
                    ]);
                });

                $this->createStatusHistory($order, $createdAt);
                $sequence++;
            }
        });
    }

    private function realisticStatus(): string
    {
        return fake()->randomElement([
            'pending',
            'processing',
            'processing',
            'packed',
            'shipped',
            'out_for_delivery',
            'delivered',
            'delivered',
            'delivered',
            'cancelled',
            'returned',
        ]);
    }

    private function paymentStatusFor(string $status): string
    {
        return match ($status) {
            'cancelled' => fake()->randomElement(['pending', 'refunded']),
            'returned' => 'refunded',
            default => fake()->randomElement(['paid', 'paid', 'paid', 'pending']),
        };
    }

    private function createStatusHistory(Order $order, Carbon $createdAt): void
    {
        $steps = $this->timelineFor($order->status);
        $changedAt = $createdAt->copy();

        foreach ($steps as $step) {
            $order->statusHistory()->create([
                'status' => $step['status'],
                'remarks' => $step['remarks'],
                'changed_by' => $step['status'] === 'pending' ? null : $order->seller_id,
                'created_at' => $changedAt,
                'updated_at' => $changedAt,
            ]);

            $changedAt = $changedAt->copy()->addHours(fake()->numberBetween(4, 24));
        }
    }

    /**
     * @return array<int, array{status: string, remarks: string}>
     */
    private function timelineFor(string $status): array
    {
        if ($status === 'cancelled') {
            return [
                ['status' => 'pending', 'remarks' => 'Order Placed'],
                ['status' => 'cancelled', 'remarks' => 'Cancelled'],
            ];
        }

        if ($status === 'returned') {
            return [
                ...$this->timelineRemarks,
                ['status' => 'returned', 'remarks' => 'Returned'],
            ];
        }

        $targetIndex = collect($this->timelineRemarks)
            ->search(fn (array $step): bool => $step['status'] === $status);

        if ($targetIndex === false) {
            return [$this->timelineRemarks[0]];
        }

        return array_slice($this->timelineRemarks, 0, $targetIndex + 1);
    }
}
