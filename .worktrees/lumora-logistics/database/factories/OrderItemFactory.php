<?php

namespace Database\Factories;

use App\Models\Order;
use App\Models\OrderItem;
use App\Models\Product;
use Illuminate\Database\Eloquent\Factories\Factory;
use RuntimeException;

/**
 * @extends Factory<OrderItem>
 */
class OrderItemFactory extends Factory
{
    protected $model = OrderItem::class;

    public function definition(): array
    {
        $product = Product::query()->inRandomOrder()->first();

        if (! $product) {
            throw new RuntimeException('OrderItemFactory requires at least one existing product.');
        }

        $quantity = fake()->numberBetween(1, 5);
        $price = (float) $product->price;

        return [
            'order_id' => Order::factory(),
            'product_id' => $product->id,
            'seller_id' => $product->seller_id,
            'quantity' => $quantity,
            'price' => $price,
            'subtotal' => round($price * $quantity, 2),
        ];
    }
}
