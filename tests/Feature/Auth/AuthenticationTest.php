<?php

namespace Tests\Feature\Auth;

use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class AuthenticationTest extends TestCase
{
    use RefreshDatabase;

    public function test_login_screen_can_be_rendered(): void
    {
        $response = $this->get('/login');

        $response->assertStatus(200);
    }

    public function test_users_can_authenticate_using_the_login_screen(): void
    {
        $user = User::factory()->create();

        $response = $this->post('/login', [
            'email' => $user->email,
            'password' => 'password',
        ]);

        $this->assertAuthenticated();
        $response->assertRedirect(route('dashboard', absolute: false));
    }

    public function test_pending_and_rejected_buyers_can_authenticate(): void
    {
        foreach (['pending', 'rejected'] as $status) {
            $user = User::factory()->create(['role' => 'buyer', 'approval_status' => $status]);

            $this->post('/login', ['email' => $user->email, 'password' => 'password'])
                ->assertRedirect(route('dashboard', absolute: false));

            $this->assertAuthenticatedAs($user);
            auth()->logout();
        }
    }

    public function test_pending_buyer_is_not_blocked_from_checkout_orders_or_account_routes(): void
    {
        $user = User::factory()->create(['role' => 'buyer', 'approval_status' => 'pending']);

        foreach (['/cart/checkout', '/account/orders', '/profile'] as $path) {
            $response = $this->actingAs($user)->get($path);
            $this->assertNotSame(403, $response->getStatusCode(), $path.' must not require buyer approval.');
        }
    }

    public function test_users_can_not_authenticate_with_invalid_password(): void
    {
        $user = User::factory()->create();

        $this->post('/login', [
            'email' => $user->email,
            'password' => 'wrong-password',
        ]);

        $this->assertGuest();
    }

    public function test_users_can_logout(): void
    {
        $user = User::factory()->create();

        $response = $this->actingAs($user)->post('/logout');

        $this->assertGuest();
        $response->assertRedirect('/');
    }
}
