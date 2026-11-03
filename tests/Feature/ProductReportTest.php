<?php

namespace Tests\Feature;

use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Str;
use Tests\TestCase;

class ProductReportTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();
        $this->withoutVite();
    }

    public function test_product_report_requires_authentication_and_saves_report_against_product_and_user(): void
    {
        Storage::fake('local');
        $seller = User::factory()->create(['role' => 'seller']);
        $reporter = User::factory()->create(['role' => 'buyer']);
        $productId = $this->product($seller);

        $this->post(route('shop.product.report', $productId), ['reason' => 'Suspicious seller'])
            ->assertRedirect(route('login'));

        $this->actingAs($reporter)->post(route('shop.product.report', $productId), [
            'reason' => 'Suspicious seller',
            'details' => 'The seller profile uses suspicious contact details.',
            'attachment' => UploadedFile::fake()->create('seller-evidence.pdf', 40, 'application/pdf'),
        ])->assertRedirect();

        $this->assertDatabaseHas('complaints', [
            'buyer_id' => $reporter->id,
            'seller_id' => $seller->id,
            'product_id' => $productId,
            'product_reporter_id' => $reporter->id,
            'complaint_type' => 'product_report',
            'category' => 'other',
            'report_reason' => 'Suspicious seller',
            'description' => 'The seller profile uses suspicious contact details.',
            'status' => 'pending',
        ]);
        $evidence = DB::table('complaint_evidence')->first();
        $this->assertNotNull($evidence);
        $this->assertTrue(Storage::disk('local')->exists($evidence->image_path));

        $complaintId = (int) DB::table('complaints')->where('product_id', $productId)->value('id');
        $this->get(route('admin.complaints.evidence', [$complaintId, $evidence->id]))->assertRedirect(route('login'));
        $admin = User::factory()->create(['role' => 'admin']);
        $this->actingAs($admin)->get(route('admin.complaints.evidence', [$complaintId, $evidence->id]))
            ->assertOk()->assertHeader('Content-Type', 'application/pdf')->assertHeader('Cache-Control', 'private, no-store');
    }

    public function test_report_reason_is_validated_and_duplicate_product_reports_are_rejected(): void
    {
        $seller = User::factory()->create(['role' => 'seller']);
        $reporter = User::factory()->create(['role' => 'buyer']);
        $productId = $this->product($seller);
        $this->actingAs($reporter);

        $this->from(route('shop.product', $productId))->post(route('shop.product.report', $productId), ['reason' => 'Something else'])
            ->assertSessionHasErrors('reason');

        $this->post(route('shop.product.report', $productId), ['reason' => 'Wrong product images'])
            ->assertSessionHas('success');
        $this->post(route('shop.product.report', $productId), ['reason' => 'Other'])
            ->assertSessionHas('error');

        $this->assertSame(1, DB::table('complaints')->where('product_reporter_id', $reporter->id)->where('product_id', $productId)->count());
    }

    public function test_admin_complaints_page_lists_product_reports_and_mutations_remain_admin_only(): void
    {
        $seller = User::factory()->create(['role' => 'seller']);
        $reporter = User::factory()->create(['role' => 'buyer']);
        $admin = User::factory()->create(['role' => 'admin']);
        $productId = $this->product($seller);
        $reportId = (int) DB::table('complaints')->insertGetId([
            'buyer_id' => $reporter->id, 'seller_id' => $seller->id, 'product_id' => $productId,
            'category' => 'other', 'report_reason' => 'Counterfeit or fake product', 'description' => 'Logo does not look authentic.',
            'status' => 'pending', 'complaint_type' => 'product_report', 'product_reporter_id' => $reporter->id,
            'created_at' => now(), 'updated_at' => now(),
        ]);

        $this->actingAs($reporter)->get(route('admin.complaints'))->assertForbidden();
        $this->actingAs($admin)->get(route('admin.complaints'))
            ->assertOk()->assertSee('Product report')->assertSee('Counterfeit or fake product')->assertSee('Logo does not look authentic.');
        $this->actingAs($reporter)->post(route('admin.complaints.resolve', $reportId), ['admin_note' => 'Handled'])
            ->assertForbidden();
    }

    private function product(User $seller): int
    {
        $now = now();
        return (int) DB::table('products')->insertGetId([
            'seller_id' => $seller->id, 'name' => 'Reported product', 'sku' => 'SKU-'.Str::upper(Str::random(8)),
            'category' => 'clothing', 'description' => 'Test listing', 'price' => 300, 'stock' => 4,
            'image' => 'products/example.jpg', 'status' => 'active', 'created_at' => $now, 'updated_at' => $now,
        ]);
    }
}
