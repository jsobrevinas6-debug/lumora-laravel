<?php

namespace Tests\Feature;

use App\Models\PaymentMethod;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\DB;
use Tests\TestCase;

class BuyerPaymentMethodTest extends TestCase
{
    use RefreshDatabase;

    public function test_payment_methods_page_is_displayed(): void
    {
        $user = User::factory()->create(['role' => 'buyer']);

        $response = $this
            ->actingAs($user)
            ->get('/account/wallet');

        $response
            ->assertOk()
            ->assertSee('Wallet')
            ->assertSee('Add New Wallet')
            ->assertSee('GCash')
            ->assertSee('Maya')
            ->assertSee('Bank Account')
            ->assertDontSee('Cash on Delivery')
            ->assertDontSee('Card Reference');
    }

    public function test_payment_method_can_be_saved(): void
    {
        $user = User::factory()->create(['role' => 'buyer']);

        $response = $this
            ->actingAs($user)
            ->post('/account/wallet', [
                'type' => 'gcash',
                'account_name' => 'Lumora Buyer',
                'account_identifier' => '09171234567',
                'notes' => 'Main wallet',
                'is_default' => '1',
            ]);

        $response
            ->assertSessionHasNoErrors()
            ->assertRedirect('/account/wallet');

        $this->assertDatabaseHas('payment_methods', [
            'user_id' => $user->id,
            'type' => 'gcash',
            'provider' => 'GCash',
            'account_name' => 'Lumora Buyer',
            'is_default' => true,
        ]);

        $paymentMethod = PaymentMethod::query()->first();
        $rawIdentifier = DB::table('payment_methods')->where('id', $paymentMethod->id)->value('account_identifier');

        $this->assertSame('09171234567', $paymentMethod->account_identifier);
        $this->assertNotSame('09171234567', $rawIdentifier);
    }

    public function test_cod_and_card_reference_cannot_be_saved_as_wallets(): void
    {
        $user = User::factory()->create(['role' => 'buyer']);

        foreach (['cod', 'card_reference'] as $type) {
            $this
                ->actingAs($user)
                ->post('/account/wallet', [
                    'type' => $type,
                    'account_name' => 'Lumora Buyer',
                    'account_identifier' => '09171234567',
                ])
                ->assertSessionHasErrors('type');
        }

        $this->assertDatabaseCount('payment_methods', 0);
    }

    public function test_gcash_and_maya_wallet_numbers_must_use_mobile_format(): void
    {
        $user = User::factory()->create(['role' => 'buyer']);

        $this
            ->actingAs($user)
            ->post('/account/wallet', [
                'type' => 'maya',
                'account_name' => 'Lumora Buyer',
                'account_identifier' => '12345',
            ])
            ->assertSessionHasErrors('account_identifier');
    }

    public function test_bank_account_accepts_numbers_spaces_and_dashes(): void
    {
        $user = User::factory()->create(['role' => 'buyer']);

        $this
            ->actingAs($user)
            ->post('/account/wallet', [
                'type' => 'bank_transfer',
                'account_name' => 'Lumora Buyer',
                'account_identifier' => '1234-5678 9012',
            ])
            ->assertSessionHasNoErrors()
            ->assertRedirect('/account/wallet');

        $this->assertDatabaseHas('payment_methods', [
            'user_id' => $user->id,
            'type' => 'bank_transfer',
            'provider' => 'Bank Account',
        ]);

        $this->assertSame('1234-5678 9012', PaymentMethod::query()->first()->account_identifier);
    }

    public function test_only_one_default_payment_method_exists_for_user(): void
    {
        $user = User::factory()->create(['role' => 'buyer']);

        $first = PaymentMethod::create([
            'user_id' => $user->id,
            'type' => 'gcash',
            'provider' => 'GCash',
            'account_name' => 'Lumora Buyer',
            'account_identifier' => '09171234567',
            'is_default' => true,
        ]);

        $second = PaymentMethod::create([
            'user_id' => $user->id,
            'type' => 'maya',
            'provider' => 'Maya',
            'account_name' => 'Lumora Buyer',
            'account_identifier' => '09170000000',
            'is_default' => false,
        ]);

        $response = $this
            ->actingAs($user)
            ->patch("/account/wallet/{$second->id}/default");

        $response
            ->assertSessionHasNoErrors()
            ->assertRedirect('/account/wallet');

        $this->assertFalse($first->fresh()->is_default);
        $this->assertTrue($second->fresh()->is_default);
    }

    public function test_user_cannot_manage_another_users_payment_method(): void
    {
        $user = User::factory()->create(['role' => 'buyer']);
        $otherUser = User::factory()->create(['role' => 'buyer']);

        $paymentMethod = PaymentMethod::create([
            'user_id' => $otherUser->id,
            'type' => 'maya',
            'provider' => 'Maya',
            'account_name' => 'Other Buyer',
            'account_identifier' => '09170000000',
            'is_default' => true,
        ]);

        $this
            ->actingAs($user)
            ->patch("/account/wallet/{$paymentMethod->id}/default")
            ->assertForbidden();

        $this
            ->actingAs($user)
            ->delete("/account/wallet/{$paymentMethod->id}")
            ->assertForbidden();

        $this->assertDatabaseHas('payment_methods', [
            'id' => $paymentMethod->id,
            'user_id' => $otherUser->id,
        ]);
    }

    public function test_payment_methods_card_is_not_on_profile_page(): void
    {
        $user = User::factory()->create(['role' => 'buyer']);

        $response = $this
            ->actingAs($user)
            ->get('/profile');

        $response
            ->assertOk()
            ->assertDontSee('Cash on delivery is available for eligible orders.');
    }

    public function test_seller_in_buyer_mode_can_access_payment_methods_page(): void
    {
        $user = User::factory()->create(['role' => 'seller']);

        $this
            ->actingAs($user)
            ->withSession(['account_mode' => 'buyer'])
            ->get('/account/wallet')
            ->assertOk()
            ->assertSee('Wallet');
    }

    public function test_seller_in_seller_mode_and_admin_cannot_access_payment_methods_page(): void
    {
        foreach (['seller', 'admin'] as $role) {
            $user = User::factory()->create(['role' => $role]);

            $this
                ->actingAs($user)
                ->get('/account/wallet')
                ->assertForbidden();
        }
    }

    public function test_legacy_payment_methods_route_still_displays_wallet_page(): void
    {
        $user = User::factory()->create(['role' => 'buyer']);

        $this
            ->actingAs($user)
            ->get('/account/payment-methods')
            ->assertOk()
            ->assertSee('Wallet');
    }
}
