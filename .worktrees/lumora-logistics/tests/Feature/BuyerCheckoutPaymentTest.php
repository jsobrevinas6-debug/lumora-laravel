<?php

namespace Tests\Feature;

use App\Models\Order;
use App\Models\PaymentMethod;
use App\Models\Product;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Schema;
use Tests\TestCase;

class BuyerCheckoutPaymentTest extends TestCase
{
    use RefreshDatabase;

    public function test_cart_summary_shows_payment_preview_and_wallet_link(): void
    {
        $buyer = User::factory()->create(['role' => 'buyer']);
        $product = $this->product();

        $response = $this
            ->actingAs($buyer)
            ->withSession([
                'lumora_cart' => [(string) $product->id => ['quantity' => 1]],
                'lumora_cart_selected' => [$product->id],
            ])
            ->get('/cart');

        $response
            ->assertOk()
            ->assertSee('Payment Method')
            ->assertSee('Cash on Delivery or Wallet available at checkout.')
            ->assertSee(route('buyer.wallet.index'))
            ->assertSee('name="cart_payment_option"', false)
            ->assertSee('value="cod"', false)
            ->assertSee('value="wallet"', false)
            ->assertSee('Cash on Delivery')
            ->assertSee('Wallet');
    }

    public function test_cart_wallet_option_shows_default_wallet_preview(): void
    {
        $buyer = User::factory()->create(['role' => 'buyer']);
        $product = $this->product();

        PaymentMethod::create([
            'user_id' => $buyer->id,
            'type' => 'gcash',
            'provider' => 'GCash',
            'account_name' => 'Lumora Buyer',
            'account_identifier' => '09171234567',
            'is_default' => true,
        ]);

        $response = $this
            ->actingAs($buyer)
            ->withSession([
                'lumora_cart' => [(string) $product->id => ['quantity' => 1]],
                'lumora_cart_selected' => [$product->id],
                'cart_payment_option' => 'wallet',
            ])
            ->get('/cart');

        $response
            ->assertOk()
            ->assertSee('Saved Wallet')
            ->assertSee('GCash')
            ->assertSee('Lumora Buyer')
            ->assertSee('0917 *** 4567');
    }

    public function test_checkout_shows_payment_options_and_saved_wallets(): void
    {
        $buyer = User::factory()->create(['role' => 'buyer']);
        $product = $this->product();

        PaymentMethod::create([
            'user_id' => $buyer->id,
            'type' => 'gcash',
            'provider' => 'GCash',
            'account_name' => 'Lumora Buyer',
            'account_identifier' => '09171234567',
            'is_default' => true,
        ]);

        $response = $this
            ->actingAs($buyer)
            ->withSession([
                'lumora_cart' => [(string) $product->id => ['quantity' => 1]],
                'lumora_cart_selected' => [$product->id],
            ])
            ->get('/cart/checkout', ['cart_payment_option' => 'wallet']);

        $response
            ->assertOk()
            ->assertSee('Payment Method')
            ->assertSee('Choose how you want to pay for your order.')
            ->assertSee('Cash on Delivery')
            ->assertSee('GCash')
            ->assertSee('Maya')
            ->assertSee('Bank Account')
            ->assertSee('Saved Wallets')
            ->assertSee('0917 *** 4567')
            ->assertSee('Manage Wallet');
    }

    public function test_cart_cod_shortcut_preselects_cod_on_checkout(): void
    {
        $buyer = User::factory()->create(['role' => 'buyer']);
        $product = $this->product();

        PaymentMethod::create([
            'user_id' => $buyer->id,
            'type' => 'maya',
            'provider' => 'Maya',
            'account_name' => 'Lumora Buyer',
            'account_identifier' => '09170000000',
            'is_default' => true,
        ]);

        $response = $this
            ->actingAs($buyer)
            ->withSession([
                'lumora_cart' => [(string) $product->id => ['quantity' => 1]],
                'lumora_cart_selected' => [$product->id],
            ])
            ->get('/cart/checkout', ['cart_payment_option' => 'cod']);

        $response
            ->assertOk()
            ->assertSeeInOrder(['value="cod"', 'data-payment-method', 'checked'], false);
    }

    public function test_checkout_saves_cod_with_buyer_id_when_schema_requires_it(): void
    {
        $this->addBuyerIdColumnToOrders();

        $buyer = User::factory()->create(['role' => 'buyer']);
        $product = $this->product();

        $response = $this
            ->actingAs($buyer)
            ->withSession([
                'lumora_cart' => [(string) $product->id => ['quantity' => 1]],
                'lumora_cart_selected' => [$product->id],
            ])
            ->post('/checkout/place-order', [
                'payment_method' => 'cod',
            ]);

        $order = Order::query()->first();

        $response
            ->assertSessionHasNoErrors()
            ->assertRedirect(route('buyer.orders.show', $order));

        $this->assertDatabaseHas('orders', [
            'id' => $order->id,
            'user_id' => $buyer->id,
            'buyer_id' => $buyer->id,
            'payment_method' => 'cod',
            'payment_method_id' => null,
            'payment_status' => 'pending',
        ]);
    }

    public function test_checkout_saves_selected_wallet_reference_on_order(): void
    {
        $buyer = User::factory()->create(['role' => 'buyer']);
        $product = $this->product();
        $wallet = PaymentMethod::create([
            'user_id' => $buyer->id,
            'type' => 'maya',
            'provider' => 'Maya',
            'account_name' => 'Lumora Buyer',
            'account_identifier' => '09170000000',
            'is_default' => true,
        ]);

        $response = $this
            ->actingAs($buyer)
            ->withSession([
                'lumora_cart' => [(string) $product->id => ['quantity' => 1]],
                'lumora_cart_selected' => [$product->id],
            ])
            ->post('/checkout/place-order', [
                'payment_method' => 'maya',
                'payment_method_id' => $wallet->id,
            ]);

        $order = Order::query()->first();

        $response
            ->assertSessionHasNoErrors()
            ->assertRedirect(route('buyer.orders.show', $order));

        $this->assertDatabaseHas('orders', [
            'id' => $order->id,
            'payment_method' => 'maya',
            'payment_method_id' => $wallet->id,
        ]);
    }

    public function test_checkout_saves_each_wallet_type_with_buyer_id_when_schema_requires_it(): void
    {
        $this->addBuyerIdColumnToOrders();

        $buyer = User::factory()->create(['role' => 'buyer']);

        foreach (['gcash', 'maya', 'bank_transfer'] as $type) {
            $product = $this->product();
            $wallet = PaymentMethod::create([
                'user_id' => $buyer->id,
                'type' => $type,
                'provider' => ['gcash' => 'GCash', 'maya' => 'Maya', 'bank_transfer' => 'Bank Account'][$type],
                'account_name' => 'Lumora Buyer',
                'account_identifier' => $type === 'bank_transfer' ? '1234 5678 9012' : '09171234567',
                'is_default' => true,
            ]);

            $response = $this
                ->actingAs($buyer)
                ->withSession([
                    'lumora_cart' => [(string) $product->id => ['quantity' => 1]],
                    'lumora_cart_selected' => [$product->id],
                ])
                ->post('/checkout/place-order', [
                    'payment_method' => $type,
                    'payment_method_id' => $wallet->id,
                ]);

            $order = Order::query()->latest('id')->first();

            $response
                ->assertSessionHasNoErrors()
                ->assertRedirect(route('buyer.orders.show', $order));

            $this->assertDatabaseHas('orders', [
                'id' => $order->id,
                'user_id' => $buyer->id,
                'buyer_id' => $buyer->id,
                'payment_method' => $type,
                'payment_method_id' => $wallet->id,
                'payment_status' => 'pending',
            ]);
        }
    }

    public function test_checkout_rejects_wallet_that_does_not_belong_to_user_or_match_type(): void
    {
        $buyer = User::factory()->create(['role' => 'buyer']);
        $otherBuyer = User::factory()->create(['role' => 'buyer']);
        $product = $this->product();

        $otherWallet = PaymentMethod::create([
            'user_id' => $otherBuyer->id,
            'type' => 'gcash',
            'provider' => 'GCash',
            'account_name' => 'Other Buyer',
            'account_identifier' => '09171234567',
            'is_default' => true,
        ]);

        $this
            ->actingAs($buyer)
            ->withSession([
                'lumora_cart' => [(string) $product->id => ['quantity' => 1]],
                'lumora_cart_selected' => [$product->id],
            ])
            ->post('/checkout/place-order', [
                'payment_method' => 'gcash',
                'payment_method_id' => $otherWallet->id,
            ])
            ->assertSessionHasErrors('payment_method_id');

        $ownWallet = PaymentMethod::create([
            'user_id' => $buyer->id,
            'type' => 'maya',
            'provider' => 'Maya',
            'account_name' => 'Lumora Buyer',
            'account_identifier' => '09170000000',
            'is_default' => true,
        ]);

        $this
            ->actingAs($buyer)
            ->withSession([
                'lumora_cart' => [(string) $product->id => ['quantity' => 1]],
                'lumora_cart_selected' => [$product->id],
            ])
            ->post('/checkout/place-order', [
                'payment_method' => 'gcash',
                'payment_method_id' => $ownWallet->id,
            ])
            ->assertSessionHasErrors('payment_method_id');

        $this->assertDatabaseCount('orders', 0);
    }

    public function test_checkout_rejects_wallet_reference_for_cod(): void
    {
        $buyer = User::factory()->create(['role' => 'buyer']);
        $product = $this->product();
        $wallet = PaymentMethod::create([
            'user_id' => $buyer->id,
            'type' => 'gcash',
            'provider' => 'GCash',
            'account_name' => 'Lumora Buyer',
            'account_identifier' => '09171234567',
            'is_default' => true,
        ]);

        $this
            ->actingAs($buyer)
            ->withSession([
                'lumora_cart' => [(string) $product->id => ['quantity' => 1]],
                'lumora_cart_selected' => [$product->id],
            ])
            ->post('/checkout/place-order', [
                'payment_method' => 'cod',
                'payment_method_id' => $wallet->id,
            ])
            ->assertSessionHasErrors('payment_method_id');

        $this->assertDatabaseCount('orders', 0);
    }

    private function addBuyerIdColumnToOrders(): void
    {
        Schema::table('orders', function ($table): void {
            $table->unsignedBigInteger('buyer_id');
        });
    }

    private function product(): Product
    {
        $seller = User::factory()->create(['role' => 'seller']);

        return Product::create([
            'seller_id' => $seller->id,
            'name' => 'Lumora Glow Serum',
            'category' => 'Skincare',
            'description' => 'A brightening serum.',
            'price' => 1200,
            'stock' => 12,
            'status' => 'active',
        ]);
    }
}
