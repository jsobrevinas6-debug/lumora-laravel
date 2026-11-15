<?php

namespace Tests\Feature\Auth;

use Illuminate\Support\Facades\DB;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\Storage;
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
            'password' => 'Password1!',
            'password_confirmation' => 'Password1!',
            'signup_type' => 'buyer',
        ]);

        $this->assertAuthenticated();
        $response->assertRedirect(route('dashboard', absolute: false));
        $this->assertDatabaseHas('users', ['email' => 'test@example.com', 'approval_status' => 'approved', 'id_type' => null, 'id_file_path' => null]);
        $response->assertSessionHasNoErrors();
    }

    public function test_registration_page_has_no_buyer_identity_upload_fields(): void
    {
        $this->get('/register')->assertOk()->assertDontSee('Upload your ID')->assertDontSee('id_type');
    }

    public function test_sign_up_as_seller_still_creates_a_seller_application(): void
    {
        Storage::fake('local');
        DB::table('email_verification_codes')->insert([
            'email' => 'seller@example.com', 'code' => '123456', 'verified' => true,
            'expires_at' => now()->addMinutes(10), 'created_at' => now(), 'updated_at' => now(),
        ]);

        $response = $this->post('/register', [
            'first_name' => 'Seller', 'last_name' => 'Test', 'sex' => 'female',
            'contact_number' => '09123456789', 'date_of_birth' => '2000-01-01',
            'province' => 'Laguna', 'municipality' => 'Majayjay', 'barangay' => 'Poblacion',
            'email' => 'seller@example.com', 'password' => 'Password1!', 'password_confirmation' => 'Password1!',
            'signup_type' => 'seller', 'terms_accepted' => '1', 'seller_terms_accepted' => '1',
            'business_name' => 'Test Shop', 'category' => 'Beauty',
            'id_document' => UploadedFile::fake()->create('id.pdf', 20, 'application/pdf'),
            'business_permit' => UploadedFile::fake()->create('permit.pdf', 20, 'application/pdf'),
        ]);

        $response->assertRedirect(route('seller.pending', absolute: false));
        $this->assertDatabaseHas('seller_applications', [
            'user_id' => DB::table('users')->where('email', 'seller@example.com')->value('id'),
            'business_name' => 'Test Shop', 'status' => 'pending',
        ]);
    }
}
