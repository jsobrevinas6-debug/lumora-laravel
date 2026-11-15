<?php

namespace Database\Factories;

use App\Models\Order;
use App\Models\User;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends Factory<Order>
 */
class OrderFactory extends Factory
{
    protected $model = Order::class;

    public function definition(): array
    {
        $subtotal = fake()->randomFloat(2, 250, 8000);
        $shippingFee = fake()->randomElement([0, 49, 75, 99, 150]);
        $discount = fake()->randomFloat(2, 0, min($subtotal * 0.2, 1000));
        $total = round($subtotal + $shippingFee - $discount, 2);
        $status = fake()->randomElement([
            'pending',
            'processing',
            'packed',
            'shipped',
            'out_for_delivery',
            'delivered',
            'cancelled',
            'returned',
        ]);

        return [
            'order_number' => fake()->unique()->numerify('LMR-'.now()->year.'-######'),
            'user_id' => User::query()->where('role', 'buyer')->inRandomOrder()->value('id')
                ?? User::factory()->create(['role' => 'buyer'])->id,
            'seller_id' => User::query()->where('role', 'seller')->inRandomOrder()->value('id'),
            'status' => $status,
            'payment_status' => fake()->randomElement(['pending', 'paid', 'failed', 'refunded']),
            'payment_method' => fake()->randomElement(['cod', 'gcash', 'maya', 'bank_transfer']),
            'payment_method_id' => null,
            'subtotal' => $subtotal,
            'shipping_fee' => $shippingFee,
            'discount' => $discount,
            'total' => $total,
            'tracking_number' => in_array($status, ['shipped', 'out_for_delivery', 'delivered', 'returned'], true)
                ? fake()->unique()->numerify('LMRTRK'.now()->year.'######')
                : null,
            'courier' => in_array($status, ['shipped', 'out_for_delivery', 'delivered', 'returned'], true)
                ? fake()->randomElement(['LBC', 'J&T Express', 'Ninja Van', 'Flash Express'])
                : null,
            'estimated_delivery' => fake()->optional(0.75)->dateTimeBetween('now', '+10 days'),
            'delivered_at' => in_array($status, ['delivered', 'returned'], true)
                ? fake()->dateTimeBetween('-14 days', 'now')
                : null,
            'cancelled_at' => $status === 'cancelled' ? fake()->dateTimeBetween('-14 days', 'now') : null,
            'notes' => fake()->optional(0.2)->sentence(),
        ];
    }
}
