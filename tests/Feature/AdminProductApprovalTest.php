<?php

namespace Tests\Feature;

use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;
use Tests\TestCase;

class AdminProductApprovalTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();
        $this->withoutVite();
    }

    public function test_pending_queue_shows_summary_tabs_and_all_caught_up_state(): void
    {
        $admin = User::factory()->create(['role' => 'admin']);
        $seller = User::factory()->create(['role' => 'seller']);
        $this->product($seller, ['name' => 'Waiting item', 'created_at' => now()->subHours(52), 'updated_at' => now()->subHours(52)]);

        $this->actingAs($admin)->get(route('admin.product-approval'))
            ->assertOk()
            ->assertSee('Pending review')
            ->assertSee('Waiting over 48 hours')
            ->assertSee('Waiting item')
            ->assertSee('Waiting 2d 4h');

        DB::table('products')->where('approval_status', 'pending')->update(['approval_status' => 'approved', 'status' => 'active']);
        $this->get(route('admin.product-approval'))
            ->assertOk()
            ->assertSee("You're all caught up")
            ->assertSee('New seller listings show up here as soon as they are submitted.')
            ->assertSee('View recently approved');
    }

    public function test_search_category_seller_type_and_sort_are_applied_server_side(): void
    {
        $admin = User::factory()->create(['role' => 'admin']);
        $newSeller = User::factory()->create(['role' => 'seller', 'name' => 'New Seller']);
        $verifiedSeller = User::factory()->create(['role' => 'seller', 'name' => 'Verified Seller']);
        DB::table('seller_applications')->insert(['user_id' => $verifiedSeller->id, 'status' => 'approved', 'reason' => null, 'created_at' => now(), 'updated_at' => now()]);
        $this->product($newSeller, ['name' => 'Linen Shirt', 'sku' => 'SKU-LINEN', 'category' => 'mens-clothing', 'price' => 100]);
        $this->product($verifiedSeller, ['name' => 'Silk Shirt', 'sku' => 'SKU-SILK', 'category' => 'mens-clothing', 'price' => 500]);
        $this->product($verifiedSeller, ['name' => 'Phone Case', 'sku' => 'SKU-CASE', 'category' => 'electronics-accessories', 'price' => 200]);

        $this->actingAs($admin)->get(route('admin.product-approval', ['q' => 'SKU-SILK']))
            ->assertOk()->assertSee('Silk Shirt')->assertDontSee('Linen Shirt');
        $this->get(route('admin.product-approval', ['category' => 'mens-clothing', 'seller_type' => 'verified']))
            ->assertOk()->assertSee('Silk Shirt')->assertDontSee('Linen Shirt')->assertDontSee('Phone Case');
        $this->get(route('admin.product-approval', ['sort' => 'price']))
            ->assertOk()->assertSeeInOrder(['Silk Shirt', 'Phone Case', 'Linen Shirt']);
    }

    public function test_queue_paginates_five_products_per_page(): void
    {
        $admin = User::factory()->create(['role' => 'admin']);
        $seller = User::factory()->create(['role' => 'seller']);
        foreach (range(1, 6) as $number) {
            $this->product($seller, ['name' => 'Queued '.$number, 'created_at' => now()->addSeconds($number), 'updated_at' => now()]);
        }

        $this->actingAs($admin)->get(route('admin.product-approval'))
            ->assertOk()->assertSee('Showing 1-5 of 6')->assertSee('Queued 1')->assertDontSee('Queued 6');
        $this->get(route('admin.product-approval', ['page' => 2]))
            ->assertOk()->assertSee('Showing 6-6 of 6')->assertSee('Queued 6');
    }

    public function test_single_approval_publishes_and_rejection_saves_reason_and_notifies_seller(): void
    {
        $admin = User::factory()->create(['role' => 'admin']);
        $seller = User::factory()->create(['role' => 'seller']);
        $approvedId = $this->product($seller, ['name' => 'Good product']);
        $rejectedId = $this->product($seller, ['name' => 'Bad product']);

        $this->actingAs($admin)->post(route('admin.product-approval.approve', $approvedId))
            ->assertRedirect(route('admin.product-approval'));
        $this->assertDatabaseHas('products', ['id' => $approvedId, 'approval_status' => 'approved', 'status' => 'active']);
        $this->assertNotNull(DB::table('products')->where('id', $approvedId)->value('approved_at'));

        $this->post(route('admin.product-approval.reject', $rejectedId), ['reason' => 'Photos unclear or missing', 'note' => 'Please upload a clearer front photo.'])
            ->assertRedirect(route('admin.product-approval'));
        $this->assertDatabaseHas('products', ['id' => $rejectedId, 'approval_status' => 'rejected', 'status' => 'inactive', 'rejection_reason' => 'Photos unclear or missing', 'rejection_note' => 'Please upload a clearer front photo.']);
        $this->assertDatabaseHas('notifications', ['notifiable_id' => $seller->id]);

        $notification = DB::table('notifications')->where('notifiable_id', $seller->id)->first();
        $this->actingAs($seller)->get(route('seller.orders.notifications'))
            ->assertOk()->assertJsonPath('product_approvals.0.product_name', 'Bad product');
        $this->postJson(route('seller.notifications.products.read'), ['ids' => [$notification->id]])
            ->assertOk()->assertJsonPath('success', true);
        $this->assertNotNull(DB::table('notifications')->where('id', $notification->id)->value('read_at'));
    }

    public function test_bulk_approve_and_reject_require_valid_reason_and_update_only_pending_products(): void
    {
        $admin = User::factory()->create(['role' => 'admin']);
        $seller = User::factory()->create(['role' => 'seller']);
        $first = $this->product($seller, ['name' => 'First']);
        $second = $this->product($seller, ['name' => 'Second']);

        $this->actingAs($admin)->postJson(route('admin.product-approval.bulk'), ['action' => 'approved', 'ids' => [$first, $second]])
            ->assertOk()->assertJsonPath('ids', [$first, $second]);
        $third = $this->product($seller, ['name' => 'Third']);
        $this->postJson(route('admin.product-approval.bulk'), ['action' => 'rejected', 'ids' => [$third], 'reason' => 'Prohibited item'])
            ->assertOk()->assertJsonPath('ids', [$third]);
        $this->assertDatabaseHas('products', ['id' => $first, 'status' => 'active', 'approval_status' => 'approved']);
        $this->assertDatabaseHas('products', ['id' => $third, 'status' => 'inactive', 'approval_status' => 'rejected']);
    }

    public function test_rejection_reason_is_required(): void
    {
        $admin = User::factory()->create(['role' => 'admin']);
        $seller = User::factory()->create(['role' => 'seller']);
        $product = $this->product($seller);

        $this->actingAs($admin)->postJson(route('admin.product-approval.reject', $product))
            ->assertUnprocessable()->assertJsonValidationErrors('reason');
        $this->assertDatabaseHas('products', ['id' => $product, 'approval_status' => 'pending']);
    }

    private function product(User $seller, array $overrides = []): int
    {
        $now = now();
        return (int) DB::table('products')->insertGetId(array_merge([
            'seller_id' => $seller->id,
            'name' => 'Test product',
            'sku' => 'SKU-'.Str::upper(Str::random(8)),
            'category' => 'mens-clothing',
            'description' => 'A product for review.',
            'price' => 200,
            'stock' => 10,
            'image' => 'products/example.jpg',
            'status' => 'inactive',
            'approval_status' => 'pending',
            'created_at' => $now,
            'updated_at' => $now,
        ], $overrides));
    }
}
