<?php

namespace Tests\Feature;

use App\Models\Order;
use App\Models\User;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;
use Tests\TestCase;

class AdminEWalletPaymentsTest extends TestCase
{
    protected function setUp(): void
    {
        parent::setUp();

        Schema::dropIfExists('order_items');
        Schema::dropIfExists('products');
        Schema::dropIfExists('orders');
        Schema::dropIfExists('users');

        Schema::create('users', function (Blueprint $table) {
            $table->id();
            $table->string('name');
            $table->string('email')->unique();
            $table->timestamp('email_verified_at')->nullable();
            $table->string('password');
            $table->string('role')->default('buyer');
            $table->string('status')->default('active');
            $table->rememberToken();
            $table->timestamps();
        });

        Schema::create('orders', function (Blueprint $table) {
            $table->id();
            $table->string('order_number');
            $table->foreignId('user_id');
            $table->foreignId('seller_id')->nullable();
            $table->string('status');
            $table->string('payment_status');
            $table->string('payment_method');
            $table->string('payment_proof_path')->nullable();
            $table->string('payment_reference_last6')->nullable();
            $table->decimal('subtotal', 10, 2);
            $table->decimal('shipping_fee', 10, 2);
            $table->decimal('discount', 10, 2)->default(0);
            $table->decimal('total', 10, 2);
            $table->timestamps();
        });

        Schema::create('products', function (Blueprint $table) {
            $table->id();
            $table->string('name');
        });

        Schema::create('order_items', function (Blueprint $table) {
            $table->id();
            $table->foreignId('order_id');
            $table->foreignId('product_id')->nullable();
            $table->unsignedInteger('quantity');
            $table->decimal('price', 10, 2);
            $table->string('variant')->nullable();
            $table->timestamps();
        });
    }

    public function test_list_uses_database_pagination_and_clamps_requested_pages(): void
    {
        $admin = User::factory()->create(['role' => 'admin']);
        $buyer = User::factory()->create(['role' => 'buyer']);

        foreach (range(1, 25) as $number) {
            Order::query()->create([
                'order_number' => sprintf('LMR-2026-%06d', $number),
                'user_id' => $buyer->id,
                'seller_id' => null,
                'payment_method' => $number % 2 === 0 ? 'maya' : 'gcash',
                'payment_status' => 'pending',
                'payment_proof_path' => 'receipts/'.$number.'.jpg',
                'payment_reference_last6' => sprintf('%06d', $number),
                'status' => 'pending',
                'subtotal' => 500,
                'shipping_fee' => 20,
                'discount' => 0,
                'total' => 520,
            ]);
        }

        $this->actingAs($admin)->get(route('admin.e-wallet-payments', ['page' => 1]))
            ->assertOk()
            ->assertSee('Showing 1&ndash;8 of 25 orders', false)
            ->assertSee('LMR-2026-000001')
            ->assertDontSee('LMR-2026-000009');

        $this->get(route('admin.e-wallet-payments', ['page' => 2]))
            ->assertOk()
            ->assertSee('Showing 9&ndash;16 of 25 orders', false)
            ->assertSee('LMR-2026-000009');

        $this->get(route('admin.e-wallet-payments', ['page' => 4]))
            ->assertOk()
            ->assertSee('Showing 25&ndash;25 of 25 orders', false)
            ->assertSee('LMR-2026-000025');

        $this->get(route('admin.e-wallet-payments', ['page' => 999]))
            ->assertOk()
            ->assertSee('Showing 25&ndash;25 of 25 orders', false)
            ->assertSee('LMR-2026-000025');

        $this->get(route('admin.e-wallet-payments', ['per_page' => 500]))
            ->assertOk()
            ->assertSee('Showing 1&ndash;8 of 25 orders', false);
    }

    public function test_filters_combine_with_pagination_and_empty_results_have_clear_link(): void
    {
        $admin = User::factory()->create(['role' => 'admin']);
        $buyer = User::factory()->create(['role' => 'buyer', 'name' => 'Wallet Buyer']);

        foreach (range(1, 18) as $number) {
            Order::query()->create([
                'order_number' => sprintf('LMR-2026-%06d', $number),
                'user_id' => $buyer->id,
                'seller_id' => null,
                'payment_method' => $number % 2 === 0 ? 'maya' : 'gcash',
                'payment_status' => 'pending',
                'payment_proof_path' => 'receipts/'.$number.'.jpg',
                'payment_reference_last6' => sprintf('%06d', $number),
                'status' => 'pending',
                'subtotal' => 500,
                'shipping_fee' => 20,
                'discount' => 0,
                'total' => 520,
            ]);
        }

        $this->actingAs($admin)
            ->get(route('admin.e-wallet-payments', [
                'page' => 2,
                'per_page' => 8,
                'status' => 'review',
                'method' => 'maya',
                'q' => 'Wallet Buyer',
                'sort' => 'oldest',
                'range' => '7',
            ]))
            ->assertOk()
            ->assertSee('Showing 9&ndash;9 of 9 orders', false)
            ->assertSee('LMR-2026-000018')
            ->assertDontSee('LMR-2026-000017');

        $this->get(route('admin.e-wallet-payments', ['q' => 'no matching buyer']))
            ->assertOk()
            ->assertSee('No payment submissions match your filters')
            ->assertSee('Clear filters')
            ->assertDontSee('aria-label="Pagination"', false);
    }
}
