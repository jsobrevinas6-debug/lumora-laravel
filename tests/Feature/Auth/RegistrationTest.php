<?php

namespace Tests\Feature\Auth;

use Illuminate\Support\Facades\DB;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class RegistrationTest extends TestCase
{
    use RefreshDatabase;

    public function test_registration_screen_can_be_rendered(): void
    {
        $response = $this->get('/register');

        $response->assertStatus(200);
    }

    public function test_new_users_can_register(): void
    {
        DB::table('email_verification_codes')->insert([
            'email' => 'test@example.com',
            'code' => '123456',
            'verified' => true,
            'expires_at' => now()->addMinutes(10),
            'created_at' => now(),
            'updated_at' => now(),
        ]);

        $response = $this->post('/register', [
            'first_name' => 'Test',
            'last_name' => 'User',
            'middle_initial' => null,
            'sex' => 'female',
            'contact_number' => '09123456789',
            'date_of_birth' => '2000-01-01',
            'province' => 'Laguna',
            'municipality' => 'Majayjay',
            'barangay' => 'Poblacion',
            'street' => 'Main Street',
            'house_number' => '1',
            'email' => 'test@example.com',
            'password' => 'password',
            'password_confirmation' => 'password',
            'signup_type' => 'buyer',
        ]);

        $this->assertAuthenticated();
        $response->assertRedirect(route('dashboard', absolute: false));
    }
}
