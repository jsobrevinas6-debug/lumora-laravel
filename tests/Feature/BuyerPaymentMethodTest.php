<?php

namespace Tests\Feature;

use App\Models\PaymentMethod;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class BuyerPaymentMethodTest extends TestCase
{
    use RefreshDatabase;

    public function test_payment_methods_page_is_displayed(): void
    {
        $user = User::factory()->create();

        $response = $this
            ->actingAs($user)
            ->get('/account/payment-methods');

        $response
            ->assertOk()
            ->assertSee('Payment Methods')
            ->assertSee('Add New Payment Method');
    }

    public function test_payment_method_can_be_saved(): void
    {
        $user = User::factory()->create();

        $response = $this
            ->actingAs($user)
            ->post('/account/payment-methods', [
                'type' => 'gcash',
                'provider' => 'GCash',
                'account_name' => 'Lumora Buyer',
                'account_identifier' => '09171234567',
                'notes' => 'Main wallet',
                'is_default' => '1',
            ]);

        $response
            ->assertSessionHasNoErrors()
            ->assertRedirect('/account/payment-methods');

        $this->assertDatabaseHas('payment_methods', [
            'user_id' => $user->id,
            'type' => 'gcash',
            'provider' => 'GCash',
            'account_name' => 'Lumora Buyer',
            'is_default' => true,
        ]);
    }

    public function test_card_reference_only_saves_last_four_digits(): void
    {
        $user = User::factory()->create();

        $response = $this
            ->actingAs($user)
            ->post('/account/payment-methods', [
                'type' => 'card_reference',
                'provider' => 'Visa',
                'account_name' => 'Lumora Buyer',
                'account_identifier' => '4242',
            ]);

        $response->assertSessionHasNoErrors();

        $this->assertDatabaseHas('payment_methods', [
            'user_id' => $user->id,
            'type' => 'card_reference',
            'account_identifier' => null,
            'last_four' => '4242',
        ]);
    }

    public function test_only_one_default_payment_method_exists_for_user(): void
    {
        $user = User::factory()->create();

        $first = PaymentMethod::create([
            'user_id' => $user->id,
            'type' => 'cod',
            'provider' => 'Cash on Delivery',
            'is_default' => true,
        ]);

        $second = PaymentMethod::create([
            'user_id' => $user->id,
            'type' => 'maya',
            'provider' => 'Maya',
            'account_identifier' => '09170000000',
            'is_default' => false,
        ]);

        $response = $this
            ->actingAs($user)
            ->patch("/account/payment-methods/{$second->id}/default");

        $response
            ->assertSessionHasNoErrors()
            ->assertRedirect('/account/payment-methods');

        $this->assertFalse($first->fresh()->is_default);
        $this->assertTrue($second->fresh()->is_default);
    }

    public function test_user_cannot_manage_another_users_payment_method(): void
    {
        $user = User::factory()->create();
        $otherUser = User::factory()->create();

        $paymentMethod = PaymentMethod::create([
            'user_id' => $otherUser->id,
            'type' => 'cod',
            'provider' => 'Cash on Delivery',
            'is_default' => true,
        ]);

        $this
            ->actingAs($user)
            ->patch("/account/payment-methods/{$paymentMethod->id}/default")
            ->assertForbidden();

        $this
            ->actingAs($user)
            ->delete("/account/payment-methods/{$paymentMethod->id}")
            ->assertForbidden();

        $this->assertDatabaseHas('payment_methods', [
            'id' => $paymentMethod->id,
            'user_id' => $otherUser->id,
        ]);
    }

    public function test_payment_methods_card_is_not_on_profile_page(): void
    {
        $user = User::factory()->create();

        $response = $this
            ->actingAs($user)
            ->get('/profile');

        $response
            ->assertOk()
            ->assertDontSee('Cash on delivery is available for eligible orders.');
    }
}
