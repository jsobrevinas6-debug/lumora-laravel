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

        $response->assertStatus(200)
            ->assertSee('data-legal-modal="userAgreementModal"', false)
            ->assertSee('data-legal-modal="privacyNoticeModal"', false)
            ->assertSee('Read the full Data Privacy Notice', false)
            ->assertSee('DRAFT FOR REVIEW')
            ->assertSee('Acceptance of Terms')
            ->assertSee('Personal Information Collected');
    }

    public function test_legal_document_pages_show_the_same_complete_draft_content(): void
    {
        $this->get('/legal/user-agreement')->assertOk()
            ->assertSee('DRAFT FOR REVIEW')
            ->assertSee('Account Suspension and Termination');

        $this->get('/legal/privacy-notice')->assertOk()
            ->assertSee('DRAFT FOR REVIEW')
            ->assertSee('Contact Information')
            ->assertSee('Republic Act No. 10173');
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
            'terms_accepted' => '1',
            'signup_type' => 'buyer',
        ]);

        $this->assertAuthenticated();
        $response->assertRedirect(route('dashboard', absolute: false));
        $this->assertDatabaseHas('users', [
            'email' => 'test@example.com',
            'approval_status' => 'approved',
            'id_type' => null,
            'id_file_path' => null,
            'terms_version' => config('legal.terms_version'),
            'privacy_notice_version' => config('legal.privacy_notice_version'),
        ]);
        $this->assertNotNull(\App\Models\User::where('email', 'test@example.com')->value('terms_accepted_at'));
        $this->assertNotNull(\App\Models\User::where('email', 'test@example.com')->value('privacy_notice_acknowledged_at'));
        $response->assertSessionHasNoErrors();
    }

    public function test_registration_cannot_skip_required_user_agreement_acceptance(): void
    {
        DB::table('email_verification_codes')->insert([
            'email' => 'no-consent@example.com', 'code' => '123456', 'verified' => true,
            'expires_at' => now()->addMinutes(10), 'created_at' => now(), 'updated_at' => now(),
        ]);

        $response = $this->post('/register', [
            'first_name' => 'No', 'last_name' => 'Consent', 'sex' => 'female',
            'contact_number' => '09123456789', 'date_of_birth' => '2000-01-01',
            'province' => 'Laguna', 'municipality' => 'Majayjay', 'barangay' => 'Poblacion',
            'email' => 'no-consent@example.com', 'password' => 'Password1!',
            'password_confirmation' => 'Password1!', 'signup_type' => 'buyer',
        ]);

        $response->assertSessionHasErrors('terms_accepted');
        $this->assertDatabaseMissing('users', ['email' => 'no-consent@example.com']);
    }

    public function test_api_registration_also_requires_user_agreement_acceptance(): void
    {
        $this->postJson('/api/auth/register', [
            'full_name' => 'API Consent',
            'email' => 'api-consent@example.com',
            'password' => 'Password1!',
        ])->assertUnprocessable()->assertJsonValidationErrors('terms_accepted');

        $this->assertDatabaseMissing('users', ['email' => 'api-consent@example.com']);
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
