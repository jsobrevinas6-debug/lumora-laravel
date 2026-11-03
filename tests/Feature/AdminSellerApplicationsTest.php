<?php

namespace Tests\Feature;

use App\Mail\SellerApplicationRejectedMail;
use App\Mail\SellerApprovedMail;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Mail;
use Illuminate\Support\Facades\Storage;
use Tests\TestCase;

class AdminSellerApplicationsTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();
        $this->withoutVite();
    }

    public function test_application_page_uses_real_counts_search_filters_sort_and_pagination(): void
    {
        $admin = User::factory()->create(['role' => 'admin']);
        $seller = User::factory()->create(['role' => 'seller']);
        $this->application($seller, ['business_name' => 'Approved Shop', 'status' => 'approved', 'reviewed_at' => now()->subDays(2)]);
        $this->application($seller, ['business_name' => 'Rejected Shop', 'status' => 'rejected', 'reviewed_at' => now()->subDays(3)]);

        $pendingOwners = [];
        foreach (range(1, 8) as $number) {
            $owner = User::factory()->create(['name' => 'Owner '.$number, 'email' => 'owner'.$number.'@example.test']);
            $pendingOwners[] = $owner;
            $this->application($owner, [
                'business_name' => 'Store '.$number,
                'created_at' => now()->subDays($number),
                'updated_at' => now()->subDays($number),
            ]);
        }

        $this->actingAs($admin)->get(route('admin.applications'))
            ->assertOk()->assertSee('Pending review')->assertSee('Approved sellers')->assertSee('Rejected')->assertSee('Approval rate')
            ->assertSee('Showing 1–7 of 8')->assertSee('Store 8')->assertDontSee('Store 1');
        $this->get(route('admin.applications', ['page' => 2]))
            ->assertOk()->assertSee('Showing 8–8 of 8')->assertSee('Store 1');
        $this->get(route('admin.applications', ['q' => 'Store 4', 'status' => 'all']))
            ->assertOk()->assertSee('Store 4')->assertDontSee('Store 3');
        $this->get(route('admin.applications', ['period' => 'today']))
            ->assertOk()->assertSee('No pending applications match these filters.');
        $this->get(route('admin.applications', ['status' => 'approved']))
            ->assertOk()->assertSee('Approved Shop')->assertDontSee('Rejected Shop');
    }

    public function test_approval_activates_seller_once_and_sends_existing_approval_email(): void
    {
        Mail::fake();
        $admin = User::factory()->create(['role' => 'admin']);
        $seller = User::factory()->create(['role' => 'buyer']);
        $applicationId = $this->application($seller, ['business_name' => 'Luna Crafts']);

        $this->actingAs($admin)->post(route('admin.applications.approve', $applicationId))
            ->assertRedirect(route('admin.applications', ['status' => 'pending']));
        $this->assertDatabaseHas('users', ['id' => $seller->id, 'role' => 'seller']);
        $this->assertDatabaseHas('seller_applications', ['id' => $applicationId, 'status' => 'approved', 'reviewed_by' => $admin->id]);
        $this->assertNotNull(DB::table('seller_applications')->where('id', $applicationId)->value('reviewed_at'));
        Mail::assertSent(SellerApprovedMail::class);

        $this->post(route('admin.applications.approve', $applicationId))->assertStatus(409);
    }

    public function test_rejection_requires_reason_persists_note_and_sends_email(): void
    {
        Mail::fake();
        $admin = User::factory()->create(['role' => 'admin']);
        $seller = User::factory()->create(['role' => 'buyer']);
        $applicationId = $this->application($seller);

        $this->actingAs($admin)->from(route('admin.applications'))->post(route('admin.applications.reject', $applicationId))
            ->assertSessionHasErrors('reason');
        $this->assertDatabaseHas('seller_applications', ['id' => $applicationId, 'status' => 'pending']);

        $this->post(route('admin.applications.reject', $applicationId), [
            'reason' => 'Invalid business documents',
            'note' => 'Please provide a readable business permit.',
        ])->assertRedirect(route('admin.applications', ['status' => 'pending']));
        $this->assertDatabaseHas('seller_applications', [
            'id' => $applicationId,
            'status' => 'rejected',
            'rejection_reason' => 'Invalid business documents',
            'admin_note' => 'Please provide a readable business permit.',
            'reviewed_by' => $admin->id,
        ]);
        $this->assertDatabaseHas('users', ['id' => $seller->id, 'role' => 'buyer']);
        Mail::assertSent(SellerApplicationRejectedMail::class);
    }

    public function test_only_admin_can_preview_documents_and_document_route_is_private(): void
    {
        Storage::fake('local');
        $seller = User::factory()->create(['role' => 'buyer']);
        $idPath = 'seller_documents/id-card.pdf';
        Storage::disk('local')->put($idPath, '%PDF-1.4 test file');
        $applicationId = $this->application($seller, ['id_document' => $idPath]);

        $this->get(route('admin.applications.documents', [$applicationId, 'id_document']))->assertRedirect(route('login'));
        $admin = User::factory()->create(['role' => 'admin']);
        $this->actingAs($admin)->get(route('admin.applications.documents', [$applicationId, 'id_document']))
            ->assertOk()->assertHeader('Content-Type', 'application/pdf')->assertHeader('Cache-Control', 'private, no-store');
        $this->get(route('admin.applications.documents', [$applicationId, '../users']))->assertNotFound();
    }

    public function test_existing_seller_application_submission_still_saves_documents_privately(): void
    {
        Storage::fake('local');
        $buyer = User::factory()->create(['role' => 'buyer', 'provider' => 'google']);

        $this->actingAs($buyer)->post(route('seller.apply.store'), [
            'contact_number' => '09171234567', 'province' => 'Laguna', 'municipality' => 'Santa Rosa',
            'barangay' => 'Balibago', 'business_name' => 'Fresh Store', 'category' => 'Beauty',
            'id_document' => UploadedFile::fake()->create('id.pdf', 20, 'application/pdf'),
            'business_permit' => UploadedFile::fake()->create('permit.pdf', 20, 'application/pdf'),
            'reason' => 'Beauty products and personal care.',
        ])->assertRedirect(route('seller.pending'));

        $application = DB::table('seller_applications')->where('user_id', $buyer->id)->first();
        $this->assertSame('pending', $application->status);
        $this->assertTrue(Storage::disk('local')->exists($application->id_document));
        $this->assertTrue(Storage::disk('local')->exists($application->business_permit));
    }

    private function application(User $user, array $overrides = []): int
    {
        $now = now();
        return (int) DB::table('seller_applications')->insertGetId(array_merge([
            'user_id' => $user->id,
            'business_name' => 'Sample Shop',
            'category' => 'Beauty',
            'id_document' => null,
            'business_permit' => null,
            'reason' => 'Seller application details.',
            'status' => 'pending',
            'created_at' => $now,
            'updated_at' => $now,
        ], $overrides));
    }
}
