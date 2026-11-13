<?php

namespace Tests\Feature;

use App\Mail\BuyerApplicationApprovedMail;
use App\Mail\BuyerApplicationRejectedMail;
use App\Models\SellerApplication;
use App\Models\User;
use Illuminate\Auth\Events\Registered;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\Event;
use Illuminate\Support\Facades\Mail;
use Illuminate\Support\Facades\Storage;
use Tests\TestCase;

class BuyerApprovalTest extends TestCase
{
    use RefreshDatabase;

    public function test_buyer_signup_requires_an_id_and_rejects_invalid_files(): void
    {
        Storage::fake('local');
        $this->verifyEmail('newbuyer@example.test');

        $this->post(route('register'), $this->registrationData())->assertSessionHasErrors(['buyer_id_document', 'id_type']);

        $this->post(route('register'), $this->registrationData([
            'id_type' => 'Passport',
            'buyer_id_document' => UploadedFile::fake()->createWithContent('fake.txt', 'not an image'),
        ]))->assertSessionHasErrors('buyer_id_document');

        $this->post(route('register'), $this->registrationData([
            'id_type' => 'Passport',
            'buyer_id_document' => UploadedFile::fake()->create('large.jpg', 5121, 'image/jpeg'),
        ]))->assertSessionHasErrors('buyer_id_document');
    }

    public function test_valid_buyer_signup_stores_private_id_and_waits_for_approval_without_login(): void
    {
        Event::fake([Registered::class]);
        Storage::fake('local');
        $this->verifyEmail('newbuyer@example.test');

        $this->post(route('register'), $this->registrationData([
            'id_type' => 'Passport',
            'buyer_id_document' => UploadedFile::fake()->image('passport.jpg'),
        ]))->assertRedirect(route('registration.pending'));

        $buyer = User::where('email', 'newbuyer@example.test')->firstOrFail();
        $this->assertSame('pending', $buyer->approval_status);
        $this->assertSame('Passport', $buyer->id_type);
        $this->assertNotSame('passport.jpg', basename($buyer->id_file_path));
        Storage::disk('local')->assertExists($buyer->id_file_path);
        $this->assertGuest();
    }

    public function test_pending_and_rejected_buyers_cannot_log_in(): void
    {
        $pending = User::factory()->create(['role' => 'buyer', 'approval_status' => 'pending']);
        $this->post(route('login'), ['email' => $pending->email, 'password' => 'password'])->assertSessionHasErrors('email');
        $this->assertGuest();

        $rejected = User::factory()->create(['role' => 'buyer', 'approval_status' => 'rejected', 'approval_rejection_reason' => 'Could not verify identity']);
        $this->post(route('login'), ['email' => $rejected->email, 'password' => 'password'])->assertSessionHasErrors('email');
        $this->assertGuest();
    }

    public function test_admin_approval_sends_email_and_buyer_can_log_in_afterward(): void
    {
        Mail::fake();
        $buyer = User::factory()->create(['role' => 'buyer', 'approval_status' => 'pending']);
        $admin = User::factory()->create(['role' => 'admin']);

        $this->actingAs($admin)->post(route('admin.applications.review.approve', ['type' => 'buyer', 'id' => $buyer->id]))
            ->assertRedirect(route('admin.applications', ['status' => 'pending']));
        $this->assertSame('approved', $buyer->fresh()->approval_status);
        Mail::assertSent(BuyerApplicationApprovedMail::class);

        $this->post(route('logout'));
        $this->post(route('login'), ['email' => $buyer->email, 'password' => 'password'])->assertRedirect(route('dashboard'));
        $this->assertAuthenticatedAs($buyer->fresh());
    }

    public function test_pending_buyer_with_existing_session_is_blocked_and_seller_is_unaffected(): void
    {
        $buyer = User::factory()->create(['role' => 'buyer', 'approval_status' => 'pending']);
        $this->actingAs($buyer)->get('/account/orders')->assertRedirect(route('login'));
        $this->assertGuest();

        $seller = User::factory()->create(['role' => 'seller', 'approval_status' => 'pending']);
        $this->post(route('login'), ['email' => $seller->email, 'password' => 'password'])->assertRedirect(route('dashboard'));
        $this->assertAuthenticatedAs($seller);
    }

    public function test_existing_buyer_accounts_remain_approved_without_an_id(): void
    {
        $existingBuyer = User::factory()->create(['role' => 'buyer']);

        $this->assertSame('approved', $existingBuyer->approval_status);
        $this->assertNull($existingBuyer->id_file_path);
        $this->assertNull($existingBuyer->buyer_id_document);
    }

    public function test_only_admin_can_view_buyer_id_and_admin_can_approve_or_reject_applications(): void
    {
        Mail::fake();
        Storage::fake('local');
        $path = 'buyer_identity_documents/private-id.png';
        Storage::disk('local')->put($path, UploadedFile::fake()->image('id.png')->getContent());
        $buyer = User::factory()->create(['role' => 'buyer', 'approval_status' => 'pending', 'id_file_path' => $path, 'buyer_id_document' => $path]);

        $this->get(route('admin.applications.id', ['type' => 'buyer', 'id' => $buyer->id]))->assertForbidden();
        $this->actingAs(User::factory()->create(['role' => 'seller']))
            ->get(route('admin.applications.id', ['type' => 'buyer', 'id' => $buyer->id]))->assertForbidden();
        auth()->logout();
        $this->actingAs(User::factory()->create(['role' => 'admin']))
            ->get(route('admin.applications.id', ['type' => 'buyer', 'id' => $buyer->id]))
            ->assertOk()->assertHeader('X-Content-Type-Options', 'nosniff');

        $this->post(route('admin.applications.review.reject', ['type' => 'buyer', 'id' => $buyer->id]))
            ->assertSessionHasErrors('reason');
        $this->post(route('admin.applications.review.reject', ['type' => 'buyer', 'id' => $buyer->id]), ['reason' => 'Could not verify identity'])
            ->assertRedirect(route('admin.applications', ['status' => 'pending']));
        $this->assertSame('rejected', $buyer->fresh()->approval_status);
        Mail::assertSent(BuyerApplicationRejectedMail::class);
        $this->post(route('logout'));
        $this->post(route('login'), ['email' => $buyer->email, 'password' => 'password'])->assertSessionHasErrors('email');
    }

    public function test_admin_application_list_combines_buyer_and_seller_types(): void
    {
        $admin = User::factory()->create(['role' => 'admin']);
        $seller = User::factory()->create(['role' => 'buyer', 'approval_status' => 'approved']);
        SellerApplication::create(['user_id' => $seller->id, 'business_name' => 'Seller Shop', 'category' => 'Fashion & Accessories', 'status' => 'pending']);
        User::factory()->create(['role' => 'buyer', 'approval_status' => 'pending', 'id_file_path' => 'buyer_identity_documents/id.png']);

        $this->actingAs($admin)->get(route('admin.applications', ['type' => 'buyer', 'status' => 'pending']))
            ->assertOk()->assertSee('Seller / Buyer Applications')->assertSee('Buyer')->assertDontSee('Seller Shop');
        $this->get(route('admin.applications', ['type' => 'seller', 'status' => 'pending']))->assertSee('Seller Shop');
    }

    private function verifyEmail(string $email): void
    {
        \Illuminate\Support\Facades\DB::table('email_verification_codes')->insert([
            'email' => $email, 'code' => '123456', 'verified' => true,
            'expires_at' => now()->addMinutes(10), 'created_at' => now(), 'updated_at' => now(),
        ]);
    }

    private function registrationData(array $overrides = []): array
    {
        return array_merge([
            'signup_type' => 'buyer', 'first_name' => 'Test', 'last_name' => 'Buyer',
            'sex' => 'female', 'contact_number' => '09171234567', 'date_of_birth' => '1995-01-01',
            'province' => 'Laguna', 'municipality' => 'Majayjay', 'barangay' => 'Poblacion',
            'email' => 'newbuyer@example.test', 'password' => 'Password123!', 'password_confirmation' => 'Password123!',
            'terms_accepted' => '1',
        ], $overrides);
    }
}
