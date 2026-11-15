<?php

namespace Tests\Feature;

use App\Http\Controllers\Admin\DashboardController;
use App\Models\Order;
use App\Models\Product;
use App\Models\ReturnRequest;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Mail;
use Illuminate\Support\Facades\Notification;
use Illuminate\Support\Facades\Storage;
use Tests\TestCase;

class ReturnAndRefundWorkflowTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();
        $this->withoutVite();
    }

    private function seedDeliveredOrder(
        int $stock = 10,
        int $salesCount = 3,
        ?int $daysAgoDelivered = 2,
        string $paymentStatus = 'paid',
        string $paymentMethod = 'gcash'
    ): array {
        $seller = User::factory()->create(['role' => 'seller', 'approval_status' => 'approved', 'status' => 'active']);
        $buyer = User::factory()->create(['role' => 'buyer', 'approval_status' => 'approved', 'status' => 'active']);
        $admin = User::factory()->create(['role' => 'admin', 'approval_status' => 'approved', 'status' => 'active']);

        $product = Product::create([
            'seller_id' => $seller->id,
            'name' => 'Crimson Silk Matte Lipstick',
            'category' => 'makeup',
            'description' => 'Velvet matte lip color',
            'price' => 500,
            'stock' => $stock,
            'sales_count' => $salesCount,
            'status' => 'active',
            'approval_status' => 'approved',
        ]);

        $deliveredAt = $daysAgoDelivered !== null ? now()->subDays($daysAgoDelivered) : now()->subDays(1);

        $order = Order::create([
            'order_number' => 'LMR-2026-' . str_pad((string) random_int(100000, 999999), 6, '0', STR_PAD_LEFT),
            'user_id' => $buyer->id,
            'seller_id' => $seller->id,
            'status' => 'delivered',
            'payment_status' => $paymentStatus,
            'payment_method' => $paymentMethod,
            'subtotal' => 1000,
            'shipping_fee' => 0,
            'discount' => 0,
            'total' => 1000,
            'delivered_at' => $deliveredAt,
        ]);

        DB::table('order_items')->insert([
            'order_id' => $order->id,
            'product_id' => $product->id,
            'seller_id' => $seller->id,
            'quantity' => 2,
            'price' => 500,
            'subtotal' => 1000,
            'created_at' => now(),
            'updated_at' => now(),
        ]);

        return compact('seller', 'buyer', 'admin', 'product', 'order');
    }

    public function test_mobile_return_request_creates_return_record_enforces_7_day_window_and_syncs_api(): void
    {
        Storage::fake('local');
        Http::fake(['*' => Http::response(['found' => false], 404)]);

        ['buyer' => $buyer, 'order' => $order] = $this->seedDeliveredOrder(daysAgoDelivered: 2);

        $tinyPng = 'data:image/png;base64,' . base64_encode('fake-png-bytes');

        $res = $this->actingAs($buyer, 'sanctum')->postJson("/api/buyer/orders/{$order->order_number}/return", [
            'reason' => 'Wrong item received',
            'preferred_solution' => 'Full Refund',
            'details' => 'Received wrong shade instead of crimson silk.',
            'evidence_photos' => [$tinyPng],
        ]);

        $res->assertCreated()
            ->assertJsonPath('data.status', 'return_requested')
            ->assertJsonPath('data.return_status', 'pending')
            ->assertJsonPath('data.return_reason', 'wrong_item')
            ->assertJsonPath('data.preferred_solution', 'refund')
            ->assertJsonPath('data.refund_status', 'pending');

        $order->refresh();
        $this->assertSame('delivered', $order->status);

        $rr = ReturnRequest::where('order_id', $order->id)->first();
        $this->assertNotNull($rr);
        $this->assertSame('wrong_item', $rr->reason);
        $this->assertSame('refund', $rr->preferred_solution);
        $this->assertCount(1, $rr->evidence);

        $listRes = $this->actingAs($buyer, 'sanctum')->getJson('/api/buyer/orders');
        $listRes->assertOk()
            ->assertJsonPath('data.0.status', 'return_requested')
            ->assertJsonPath('data.0.return_status', 'pending');

        // Expired 7-day return window check
        ['buyer' => $buyer2, 'order' => $oldOrder] = $this->seedDeliveredOrder(daysAgoDelivered: 10);

        $expiredRes = $this->actingAs($buyer2, 'sanctum')->postJson("/api/buyer/orders/{$oldOrder->order_number}/return", [
            'reason' => 'damaged',
            'details' => 'Arrived broken in transit.',
        ]);

        $expiredRes->assertStatus(422)
            ->assertJsonPath('message', 'The 7-day return window for this order has expired.');
    }

    public function test_seller_approval_processes_refund_restores_stock_and_excludes_from_payouts_and_commission(): void
    {
        Storage::fake('local');
        Notification::fake();
        Mail::fake();
        Http::fake(['*' => Http::response(['dispatched' => true, 'courier_name' => 'Rider 01'], 200)]);

        ['seller' => $seller, 'buyer' => $buyer, 'admin' => $admin, 'product' => $product, 'order' => $order] =
            $this->seedDeliveredOrder(stock: 8, salesCount: 4, daysAgoDelivered: 1, paymentStatus: 'paid');

        // Baseline: Seller can see earned balance BEFORE approval
        $this->actingAs($seller)->get(route('seller.payouts.index'))
            ->assertOk()
            ->assertViewHas('totalSales', fn ($v) => (float) $v === 1000.0)
            ->assertViewHas('availableBalance', fn ($v) => (float) $v === 900.0);

        $this->actingAs($buyer)->post(route('buyer.orders.return-request', $order), [
            'reason' => 'wrong_item',
            'preferred_solution' => 'refund',
            'details' => 'Received the wrong product variant inside the box.',
        ])->assertRedirect(route('buyer.orders.index'));

        $rr = ReturnRequest::where('order_id', $order->id)->firstOrFail();

        $this->actingAs($seller)
            ->post(route('seller.returns.approve', $rr))
            ->assertSessionHas('success');

        $rr->refresh();
        $order->refresh();
        $product->refresh();

        $this->assertSame('approved', $rr->status);
        $this->assertSame('refunded', $rr->refund_status);
        $this->assertSame('returned', $order->status);
        $this->assertSame('refunded', $order->payment_status);
        $this->assertSame(1000.0, (float) $order->refund_amount);
        $this->assertSame(10, (int) $product->stock);
        $this->assertSame(2, (int) $product->sales_count);

        // Excluded from Seller Payout balance & Admin Commission
        $this->actingAs($seller)->get(route('seller.payouts.index'))
            ->assertOk()
            ->assertViewHas('totalSales', fn ($v) => (float) $v === 0.0)
            ->assertViewHas('availableBalance', fn ($v) => (float) $v === 0.0);

        $this->actingAs($admin)->get(route('admin.commission'))
            ->assertOk()
            ->assertViewHas('totalGrossSales', fn ($v) => (float) $v === 0.0)
            ->assertViewHas('totalCommission', fn ($v) => (float) $v === 0.0);

        // Mobile API now reflects returned + refunded cleanly (never overwritten back to delivered)
        $apiOrder = $this->actingAs($buyer, 'sanctum')->getJson('/api/buyer/orders');
        $apiOrder->assertOk()
            ->assertJsonPath('data.0.status', 'returned')
            ->assertJsonPath('data.0.return_status', 'approved')
            ->assertJsonPath('data.0.refund_status', 'refunded')
            ->assertJsonPath('data.0.payment_status', 'refunded');
    }

    public function test_seller_denial_and_buyer_dispute_escalation_allow_admin_arbitration_override(): void
    {
        Storage::fake('local');
        Notification::fake();
        Mail::fake();
        Http::fake(['*' => Http::response(['dispatched' => true, 'courier_name' => 'Rider 02'], 200)]);

        ['seller' => $seller, 'buyer' => $buyer, 'admin' => $admin, 'product' => $product, 'order' => $order] =
            $this->seedDeliveredOrder(stock: 5, salesCount: 2, daysAgoDelivered: 2, paymentStatus: 'paid');

        // 1. Buyer requests return via mobile API (damaged item -> stock NOT restocked)
        $this->actingAs($buyer, 'sanctum')->postJson("/api/buyer/orders/{$order->order_number}/return", [
            'reason' => 'damaged',
            'preferred_solution' => 'refund',
            'details' => 'Bottle arrived shattered with broken dropper.',
            'evidence_photos' => ['data:image/png;base64,' . base64_encode('broken-glass-proof')],
        ])->assertCreated();

        $rr = ReturnRequest::where('order_id', $order->id)->firstOrFail();

        // 2. Seller denies claim
        $this->actingAs($seller)->post(route('seller.returns.deny', $rr), [
            'seller_note' => 'Packaging left warehouse intact.',
        ])->assertSessionHas('success');

        $rr->refresh();
        $this->assertSame('denied', $rr->status);
        $this->assertSame('Packaging left warehouse intact.', $rr->admin_note);

        $afterDenial = $this->actingAs($buyer, 'sanctum')->getJson('/api/buyer/orders');
        $afterDenial->assertOk()
            ->assertJsonPath('data.0.return_status', 'denied')
            ->assertJsonPath('data.0.return_rejection_reason', 'Packaging left warehouse intact.');

        // 3. Buyer escalates dispute to Admin via mobile API
        $disputeRes = $this->actingAs($buyer, 'sanctum')->postJson("/api/buyer/orders/{$order->order_number}/dispute", [
            'dispute_notes' => 'Outer parcel was crushed on delivery.',
        ]);
        $disputeRes->assertOk()
            ->assertJsonPath('data.is_disputed', true)
            ->assertJsonPath('data.return_dispute_status', 'under_arbitration');

        // 4. Admin filters disputed returns and overrides denial
        $this->actingAs($admin)->get(route('admin.returns.index', ['status' => 'disputed']))
            ->assertOk()
            ->assertSee($order->order_number);

        $this->actingAs($admin)->post(route('admin.returns.approve', $rr), [
            'admin_note' => 'Approved after photographic inspection.',
        ])->assertRedirect(route('admin.returns.index'));

        $rr->refresh();
        $order->refresh();
        $product->refresh();

        $this->assertSame('approved', $rr->status);
        $this->assertSame('resolved_approved', $rr->dispute_status);
        $this->assertSame('refunded', $rr->refund_status);
        $this->assertSame('returned', $order->status);
        $this->assertSame('refunded', $order->payment_status);
        // Damaged item: stock stays 5, sales_count decrements from 2 to 0
        $this->assertSame(5, (int) $product->stock);
        $this->assertSame(0, (int) $product->sales_count);
    }

    public function test_cancelling_paid_pending_order_records_refund_and_excludes_from_earnings(): void
    {
        Notification::fake();
        Mail::fake();

        $seller = User::factory()->create(['role' => 'seller', 'approval_status' => 'approved', 'status' => 'active']);
        $buyer = User::factory()->create(['role' => 'buyer', 'approval_status' => 'approved', 'status' => 'active']);

        $product = Product::create([
            'seller_id' => $seller->id,
            'name' => 'Noir Velvet Cushion',
            'category' => 'makeup',
            'description' => 'Longwear velvet cushion',
            'price' => 750,
            'stock' => 4,
            'sales_count' => 1,
            'status' => 'active',
            'approval_status' => 'approved',
        ]);

        $order = Order::create([
            'order_number' => 'LMR-2026-CANCEL01',
            'user_id' => $buyer->id,
            'seller_id' => $seller->id,
            'status' => 'pending',
            'payment_status' => 'paid',
            'payment_method' => 'gcash',
            'subtotal' => 750,
            'shipping_fee' => 0,
            'discount' => 0,
            'total' => 750,
        ]);

        DB::table('order_items')->insert([
            'order_id' => $order->id,
            'product_id' => $product->id,
            'seller_id' => $seller->id,
            'quantity' => 1,
            'price' => 750,
            'subtotal' => 750,
            'created_at' => now(),
            'updated_at' => now(),
        ]);

        $this->actingAs($buyer)
            ->patch(route('buyer.orders.cancel', $order))
            ->assertRedirect(route('buyer.orders.index'));

        $order->refresh();
        $product->refresh();

        $this->assertSame('cancelled', $order->status);
        $this->assertSame('refunded', $order->payment_status);
        $this->assertSame(750.0, (float) $order->refund_amount);
        $this->assertSame(5, (int) $product->stock);
        $this->assertSame(0, (int) $product->sales_count);

        $this->actingAs($seller)->get(route('seller.payouts.index'))
            ->assertOk()
            ->assertViewHas('totalSales', fn ($v) => (float) $v === 0.0);
    }
}
