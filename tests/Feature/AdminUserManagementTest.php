<?php

namespace Tests\Feature;

use App\Models\Product;
use App\Models\User;
use App\Notifications\UserDeactivatedNotification;
use App\Notifications\UserReactivatedNotification;
use App\Notifications\UserSuspendedNotification;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Notification;
use Tests\TestCase;

class AdminUserManagementTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();
        $this->withoutVite();
    }

    public function test_non_admins_cannot_open_users_or_change_an_account(): void
    {
        $buyer = User::factory()->create(['role' => 'buyer']);
        $target = User::factory()->create(['role' => 'buyer']);

        $this->actingAs($buyer)->get(route('admin.users'))->assertForbidden();
        $this->post(route('admin.users.suspend', $target), [
            'reason' => 'other', 'message' => 'Please review the community rules.', 'duration' => '7',
        ])->assertForbidden();
        $this->assertDatabaseHas('users', ['id' => $target->id, 'status' => 'active']);
    }

    public function test_user_list_search_filters_roles_sorts_and_paginates(): void
    {
        $admin = User::factory()->create(['role' => 'admin']);
        User::factory()->create(['role' => 'buyer', 'name' => 'Zoe Buyer', 'email' => 'zoe@example.test', 'email_verified' => 1]);
        User::factory()->create(['role' => 'seller', 'name' => 'Able Seller', 'shop_name' => 'Able Beauty', 'email' => 'able@example.test', 'contact_number' => '+63 (912) 345-6789', 'email_verified' => 1]);
        User::factory()->create(['role' => 'buyer', 'name' => 'Unverified Buyer', 'email' => 'unverified@example.test', 'email_verified' => 0, 'email_verified_at' => null]);
        User::factory()->create(['role' => 'buyer', 'name' => 'Same Name']);
        User::factory()->create(['role' => 'buyer', 'name' => 'same-name']);
        User::factory()->create(['role' => 'buyer', 'name' => 'Suspended Buyer', 'status' => 'suspended']);
        User::factory()->create(['role' => 'buyer', 'name' => 'Deactivated Buyer', 'status' => 'deactivated']);
        foreach (range(1, 16) as $number) User::factory()->create(['role' => 'buyer', 'name' => 'Paged '.$number]);

        $this->actingAs($admin)->get(route('admin.users', ['role' => 'seller', 'q' => 'Able', 'sort' => 'name']))
            ->assertOk()->assertSee('Able Beauty')->assertDontSee('Zoe Buyer')->assertSee('Export CSV');
        $this->get(route('admin.users', ['status' => 'email-unverified']))
            ->assertOk()->assertSee('Unverified Buyer')->assertDontSee('Able Beauty');
        $this->get(route('admin.users', ['q' => 'able@example.test']))->assertOk()->assertSee('Able Seller');
        $this->get(route('admin.users', ['q' => '9123456789']))->assertOk()->assertSee('Able Seller');
        $this->get(route('admin.users', ['status' => 'suspended']))->assertOk()->assertSee('Suspended Buyer');
        $this->get(route('admin.users', ['status' => 'deactivated']))->assertOk()->assertSee('Deactivated Buyer');
        $this->get(route('admin.users', ['q' => 'Same Name']))->assertOk()->assertSee('Possible duplicate');
        $this->get(route('admin.users', ['sort' => 'name']))
            ->assertOk()->assertSeeInOrder(['Able Seller', 'Paged 1']);
        $this->get(route('admin.users', ['sort' => 'name', 'page' => 2]))
            ->assertOk()->assertSee('page=2');
    }

    public function test_suspend_deactivate_and_reactivate_audit_and_queue_user_emails(): void
    {
        Notification::fake();
        $admin = User::factory()->create(['role' => 'admin']);
        $user = User::factory()->create(['role' => 'buyer']);
        $this->actingAs($admin);

        $this->post(route('admin.users.suspend', $user), [
            'reason' => 'policy_violation', 'message' => 'Please contact support to discuss the policy issue.', 'duration' => '7',
        ])->assertRedirect(route('admin.users', ['user' => $user->id]));
        $this->assertDatabaseHas('users', ['id' => $user->id, 'status' => 'suspended']);
        $this->assertDatabaseHas('user_status_logs', ['user_id' => $user->id, 'admin_id' => $admin->id, 'action' => 'suspended', 'reason' => 'policy_violation']);
        Notification::assertSentTo($user, UserSuspendedNotification::class);

        $this->post(route('admin.users.deactivate', $user), [
            'reason' => 'terms_violation', 'message' => 'Please contact support about this decision.', 'confirmation' => 'DEACTIVATE',
        ])->assertRedirect(route('admin.users', ['user' => $user->id]));
        $this->assertDatabaseHas('users', ['id' => $user->id, 'status' => 'deactivated']);
        $this->assertDatabaseHas('user_status_logs', ['user_id' => $user->id, 'action' => 'deactivated', 'reason' => 'terms_violation']);
        Notification::assertSentTo($user, UserDeactivatedNotification::class);

        $this->patch(route('admin.users.reactivate', $user))->assertRedirect(route('admin.users', ['user' => $user->id]));
        $this->assertDatabaseHas('users', ['id' => $user->id, 'status' => 'active', 'suspended_until' => null]);
        $this->assertDatabaseHas('user_status_logs', ['user_id' => $user->id, 'action' => 'reactivated']);
        Notification::assertSentTo($user, UserReactivatedNotification::class);
    }

    public function test_deactivation_requires_confirmation_and_admins_cannot_suspend_or_deactivate_any_admin(): void
    {
        Notification::fake();
        $admin = User::factory()->create(['role' => 'admin']);
        $otherAdmin = User::factory()->create(['role' => 'admin']);
        $user = User::factory()->create(['role' => 'buyer']);
        $this->actingAs($admin);

        $this->post(route('admin.users.deactivate', $user), ['reason' => 'fraud', 'message' => 'Please contact support.', 'confirmation' => 'no'])
            ->assertSessionHasErrors('confirmation');
        $this->post(route('admin.users.suspend', $admin), ['reason' => 'other', 'message' => 'Please contact support.', 'duration' => '7'])->assertForbidden();
        $this->post(route('admin.users.deactivate', $admin), ['reason' => 'fraud', 'message' => 'Please contact support.', 'confirmation' => 'DEACTIVATE'])->assertForbidden();
        $this->post(route('admin.users.deactivate', $otherAdmin), ['reason' => 'fraud', 'message' => 'Please contact support.', 'confirmation' => 'DEACTIVATE'])->assertForbidden();
        $this->post(route('admin.users.suspend', $otherAdmin), ['reason' => 'other', 'message' => 'Please contact support.', 'duration' => '7'])->assertForbidden();
        $this->assertDatabaseHas('users', ['id' => $admin->id, 'status' => 'active']);
        $this->assertDatabaseHas('users', ['id' => $otherAdmin->id, 'status' => 'active']);
    }

    public function test_suspended_or_deactivated_users_cannot_log_in_and_receive_a_reason_message(): void
    {
        $user = User::factory()->create(['role' => 'buyer', 'status' => 'suspended', 'password' => bcrypt('secret-password')]);
        DB::table('user_status_logs')->insert([
            'user_id' => $user->id, 'admin_id' => null, 'action' => 'suspended', 'reason' => 'policy_violation',
            'note' => 'Please contact support.', 'until' => now()->addDays(7), 'created_at' => now(),
        ]);

        $this->from('/login')->post('/login', ['email' => $user->email, 'password' => 'secret-password'])
            ->assertRedirect('/login')->assertSessionHasErrors('email');
        $suspensionErrors = session('errors')->get('email');
        $this->assertStringContainsString('Policy violation', $suspensionErrors[0]);
        $this->assertStringContainsString('Please contact support.', $suspensionErrors[0]);
        $this->assertGuest();

        $user->forceFill(['status' => 'deactivated'])->save();
        $this->from('/login')->post('/login', ['email' => $user->email, 'password' => 'secret-password'])
            ->assertSessionHasErrors('email');
        $this->assertStringContainsString('deactivated', session('errors')->get('email')[0]);
    }

    public function test_suspended_sellers_products_are_hidden_and_visible_after_reactivation(): void
    {
        $seller = User::factory()->create(['role' => 'seller', 'status' => 'active']);
        DB::table('products')->insert([
            'seller_id' => $seller->id, 'name' => 'Visible item', 'category' => 'cosmetics', 'price' => 10, 'stock' => 2,
            'status' => 'active', 'approval_status' => 'approved', 'created_at' => now(), 'updated_at' => now(),
        ]);
        $this->assertSame(1, Product::approved()->count());
        $seller->forceFill(['status' => 'suspended'])->save();
        $this->assertSame(0, Product::approved()->count());
        $seller->forceFill(['status' => 'deactivated'])->save();
        $this->assertSame(0, Product::approved()->count());
        $seller->forceFill(['status' => 'active'])->save();
        $this->assertSame(1, Product::approved()->count());
    }

    public function test_auto_lift_only_reactivates_expired_timed_suspensions(): void
    {
        Notification::fake();
        $expired = User::factory()->create(['status' => 'suspended', 'suspended_until' => now()->subMinute()]);
        $future = User::factory()->create(['status' => 'suspended', 'suspended_until' => now()->addDay()]);
        $indefinite = User::factory()->create(['status' => 'suspended', 'suspended_until' => null]);

        $this->artisan('users:lift-suspensions')->assertSuccessful();
        $this->assertDatabaseHas('users', ['id' => $expired->id, 'status' => 'active']);
        $this->assertDatabaseHas('user_status_logs', ['user_id' => $expired->id, 'action' => 'auto_lifted']);
        $this->assertDatabaseHas('users', ['id' => $future->id, 'status' => 'suspended']);
        $this->assertDatabaseHas('users', ['id' => $indefinite->id, 'status' => 'suspended']);
    }

    public function test_csv_export_uses_the_same_filters_and_never_contains_credentials(): void
    {
        $admin = User::factory()->create(['role' => 'admin']);
        User::factory()->create(['name' => 'Matching Buyer', 'role' => 'buyer', 'email' => 'match@example.test']);
        User::factory()->create(['name' => 'Other Seller', 'role' => 'seller', 'email' => 'other@example.test']);

        $response = $this->actingAs($admin)->get(route('admin.users.export', ['role' => 'buyer', 'q' => 'Matching']));
        $response->assertOk()->assertHeader('content-type', 'text/csv; charset=UTF-8');
        $csv = $response->streamedContent();
        $this->assertStringContainsString('Matching Buyer', $csv);
        $this->assertStringNotContainsString('Other Seller', $csv);
        $this->assertStringNotContainsString('password', strtolower($csv));
        $this->assertStringNotContainsString('remember_token', strtolower($csv));
    }

    public function test_successful_web_login_updates_last_login_timestamp(): void
    {
        $user = User::factory()->create(['role' => 'buyer', 'password' => bcrypt('secret-password'), 'last_login_at' => null]);

        $this->post('/login', ['email' => $user->email, 'password' => 'secret-password'])
            ->assertRedirect(route('dashboard', absolute: false));

        $this->assertNotNull($user->fresh()->last_login_at);
    }

    public function test_suspension_invalidates_database_sessions_and_api_tokens(): void
    {
        Notification::fake();
        config(['session.driver' => 'database']);
        $admin = User::factory()->create(['role' => 'admin']);
        $user = User::factory()->create(['role' => 'seller']);
        $user->createToken('test-device');
        DB::table('sessions')->insert([
            'id' => 'target-session', 'user_id' => $user->id, 'ip_address' => '127.0.0.1',
            'user_agent' => 'test', 'payload' => 'test', 'last_activity' => now()->timestamp,
        ]);

        $this->actingAs($admin)->post(route('admin.users.suspend', $user), [
            'reason' => 'suspicious_activity', 'message' => 'Please contact Lumora support for assistance.', 'duration' => '30',
        ])->assertRedirect();

        $this->assertDatabaseMissing('sessions', ['id' => 'target-session']);
        $this->assertDatabaseMissing('personal_access_tokens', ['tokenable_id' => $user->id]);
    }
}
