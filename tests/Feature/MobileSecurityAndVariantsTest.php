<?php

namespace Tests\Feature;

use App\Models\Conversation;
use App\Models\Message;
use App\Models\Product;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Mail;
use Illuminate\Support\Facades\Storage;
use Tests\TestCase;

class MobileSecurityAndVariantsTest extends TestCase
{
    use RefreshDatabase;

    public function test_products_api_returns_real_product_variants_and_stock(): void
    {
        $seller = User::factory()->create(['role' => 'seller']);
        $product = Product::create([
            'seller_id' => $seller->id,
            'name' => 'Gothic Silver Cross Drop Earrings',
            'category' => 'womens-accessories',
            'description' => 'Sterling silver drop earrings',
            'price' => 899,
            'discount_percent' => 10,
            'stock' => 14,
            'variant_type' => 'Style',
            'status' => 'active',
            'approval_status' => 'approved',
        ]);

        $v1Id = DB::table('product_variants')->insertGetId([
            'product_id' => $product->id,
            'name' => 'Oxidized Silver Pair',
            'stock' => 9,
            'created_at' => now(),
            'updated_at' => now(),
        ]);
        $v2Id = DB::table('product_variants')->insertGetId([
            'product_id' => $product->id,
            'name' => 'Mirror Polish Pair',
            'stock' => 0,
            'created_at' => now(),
            'updated_at' => now(),
        ]);

        $response = $this->getJson("/api/products/{$product->id}");

        $response->assertOk()
            ->assertJsonPath('data.variant_type', 'Style')
            ->assertJsonPath('data.stock', 9)
            ->assertJsonCount(2, 'data.variants')
            ->assertJsonPath('data.variants.0.id', $v1Id)
            ->assertJsonPath('data.variants.0.name', 'Oxidized Silver Pair')
            ->assertJsonPath('data.variants.0.stock', 9)
            ->assertJsonPath('data.variants.1.id', $v2Id)
            ->assertJsonPath('data.variants.1.stock', 0);
    }

    public function test_mobile_order_validates_and_decrements_variant_stock_and_restores_on_cancel(): void
    {
        $buyer = User::factory()->create(['role' => 'buyer', 'approval_status' => 'approved']);
        $seller = User::factory()->create(['role' => 'seller']);
        $product = Product::create([
            'seller_id' => $seller->id,
            'name' => 'Diamond Solitaire Stud Earrings',
            'category' => 'womens-accessories',
            'description' => 'Classic solitaire studs',
            'price' => 1299,
            'stock' => 5,
            'variant_type' => 'Size',
            'status' => 'active',
            'approval_status' => 'approved',
        ]);

        $variantId = DB::table('product_variants')->insertGetId([
            'product_id' => $product->id,
            'name' => '4mm Classic',
            'stock' => 3,
            'created_at' => now(),
            'updated_at' => now(),
        ]);

        $token = $buyer->createToken('test-device')->plainTextToken;

        // Excess variant quantity should fail cleanly
        $this->withToken($token)->postJson('/api/orders', [
            'payment_method' => 'cod',
            'shipping_address' => 'Cabuyao, Laguna',
            'items' => [
                ['product_id' => $product->id, 'variant_id' => $variantId, 'quantity' => 4],
            ],
        ])->assertStatus(422);

        // Valid variant order succeeds & decrements variant + product stock
        $placeRes = $this->withToken($token)->postJson('/api/orders', [
            'payment_method' => 'cod',
            'shipping_address' => 'Cabuyao, Laguna',
            'items' => [
                ['product_id' => $product->id, 'variant_id' => $variantId, 'quantity' => 2],
            ],
        ]);

        $placeRes->assertCreated()
            ->assertJsonPath('data.items.0.variant_id', $variantId)
            ->assertJsonPath('data.items.0.variant_name', '4mm Classic');

        $this->assertSame(1, (int) DB::table('product_variants')->where('id', $variantId)->value('stock'));
        $this->assertSame(3, (int) Product::findOrFail($product->id)->stock);

        // Cancelling order restores variant stock cleanly
        $orderNumber = $placeRes->json('data.id');
        $this->withToken($token)->postJson("/api/buyer/orders/{$orderNumber}/cancel", [
            'reason' => 'Changed size',
        ])->assertOk();

        $this->assertSame(3, (int) DB::table('product_variants')->where('id', $variantId)->value('stock'));
    }

    public function test_profile_update_validates_age_and_requires_otp_for_email_change(): void
    {
        $buyer = User::factory()->create([
            'role' => 'buyer',
            'approval_status' => 'approved',
            'email' => 'buyer@lumora.test',
        ]);
        $token = $buyer->createToken('iphone')->plainTextToken;

        // Reject under-18 DOB
        $this->withToken($token)->putJson('/api/auth/profile', [
            'date_of_birth' => now()->subYears(15)->toDateString(),
        ])->assertStatus(422);

        // Reject email change without verified OTP
        $this->withToken($token)->putJson('/api/auth/profile', [
            'email' => 'newbuyer@lumora.test',
        ])->assertStatus(422);

        // Seed verified OTP for new email -> update succeeds
        DB::table('email_verification_codes')->insert([
            'email' => 'newbuyer@lumora.test',
            'code' => '654321',
            'verified' => true,
            'expires_at' => now()->addMinutes(10),
            'created_at' => now(),
            'updated_at' => now(),
        ]);

        $this->withToken($token)->putJson('/api/auth/profile', [
            'first_name' => 'Justin',
            'last_name' => 'Sobrevinias',
            'date_of_birth' => '2001-05-15',
            'email' => 'newbuyer@lumora.test',
        ])->assertOk()
            ->assertJsonPath('user.email', 'newbuyer@lumora.test')
            ->assertJsonPath('user.date_of_birth', '2001-05-15');
    }

    public function test_password_update_sessions_management_reset_and_account_deletion(): void
    {
        $buyer = User::factory()->create([
            'role' => 'buyer',
            'approval_status' => 'approved',
            'email' => 'security@lumora.test',
            'password' => Hash::make('OldPass@123'),
        ]);

        $token1 = $buyer->createToken('Old Phone')->plainTextToken;
        $token2 = $buyer->createToken('Current Phone')->plainTextToken;

        // Session list shows 2 tokens
        $this->withToken($token2)->getJson('/api/auth/sessions')
            ->assertOk()
            ->assertJsonCount(2, 'data');

        // Wrong current password rejected
        $this->withToken($token2)->putJson('/api/auth/profile/password', [
            'current_password' => 'WrongPass!',
            'new_password' => 'NewPass@456',
        ])->assertStatus(422);

        // Correct password updates & revokes token1
        $this->withToken($token2)->putJson('/api/auth/profile/password', [
            'current_password' => 'OldPass@123',
            'new_password' => 'NewPass@456',
        ])->assertOk()
            ->assertJsonPath('revoked_sessions', 1);

        $this->assertSame(1, $buyer->tokens()->count());
        $this->assertTrue(Hash::check('NewPass@456', $buyer->fresh()->password));

        // Account deletion rejects wrong password & succeeds with correct password
        $this->withToken($token2)->deleteJson('/api/auth/profile', [
            'password' => 'OldPass@123',
        ])->assertStatus(422);

        $this->withToken($token2)->deleteJson('/api/auth/profile', [
            'password' => 'NewPass@456',
        ])->assertOk();

        $this->assertDatabaseMissing('users', ['id' => $buyer->id]);
    }

    public function test_avatar_upload_and_removal_endpoints(): void
    {
        $buyer = User::factory()->create([
            'role' => 'buyer',
            'approval_status' => 'approved',
            'email' => 'avatar@lumora.test',
        ]);
        $token = $buyer->createToken('Mobile App')->plainTextToken;
        $tinyPng = 'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=';

        $upload = $this->withToken($token)->postJson('/api/auth/avatar', [
            'avatar_data' => $tinyPng,
        ])->assertOk();

        $avatarUrl = $upload->json('avatar_url');
        $this->assertNotEmpty($avatarUrl);
        $this->assertSame($avatarUrl, $upload->json('avatar'));
        $this->assertSame($avatarUrl, $upload->json('user.avatar'));
        $this->assertStringContainsString('/avatars/', $avatarUrl);

        // DELETE /api/auth/avatar clears avatar & cleans stored file
        $this->withToken($token)->deleteJson('/api/auth/avatar')
            ->assertOk()
            ->assertJsonPath('avatar', null)
            ->assertJsonPath('avatar_url', null)
            ->assertJsonPath('user.avatar', null);
        $this->assertNull($buyer->fresh()->avatar);

        // POST /api/auth/avatar with remove=true also clears avatar cleanly
        $this->withToken($token)->postJson('/api/auth/avatar', [
            'avatar_data' => $tinyPng,
        ])->assertOk();
        $this->withToken($token)->postJson('/api/auth/avatar', [
            'remove' => true,
        ])->assertOk()
            ->assertJsonPath('avatar', null)
            ->assertJsonPath('avatar_url', null);
        $this->assertNull($buyer->fresh()->avatar);
    }

    public function test_phone_change_requires_and_consumes_email_otp(): void
    {
        Mail::fake();

        $buyer = User::factory()->create([
            'role' => 'buyer',
            'approval_status' => 'approved',
            'email' => 'phonebuyer@lumora.test',
            'contact_number' => '09171234567',
        ]);
        $token = $buyer->createToken('Mobile App')->plainTextToken;

        // Same normalized number in +63 format saves without requiring OTP
        $this->withToken($token)->putJson('/api/auth/profile', [
            'contact_number' => '+63 917 123 4567',
        ])->assertOk();

        // Changing to a different mobile number without verified OTP fails (422)
        $this->withToken($token)->putJson('/api/auth/profile', [
            'contact_number' => '09998887777',
        ])->assertStatus(422);

        // Send & verify real phone_change OTP to buyer's email
        $this->postJson('/api/auth/otp/send', [
            'email' => 'phonebuyer@lumora.test',
            'type' => 'phone_change',
        ])->assertOk();

        $code = DB::table('email_verification_codes')
            ->where('email', 'phonebuyer@lumora.test')
            ->value('code');
        $this->assertNotEmpty($code);

        $this->postJson('/api/auth/otp/verify', [
            'email' => 'phonebuyer@lumora.test',
            'code' => $code,
        ])->assertOk();

        $this->withToken($token)->putJson('/api/auth/profile', [
            'contact_number' => '09998887777',
            'otp_code' => $code,
        ])->assertOk()
            ->assertJsonPath('user.contact_number', '09998887777');

        $this->assertSame('09998887777', $buyer->fresh()->contact_number);
        $this->assertDatabaseMissing('email_verification_codes', [
            'email' => 'phonebuyer@lumora.test',
        ]);
    }

    public function test_buyer_seller_chat_and_support_chat_endpoints(): void
    {
        Storage::fake('public');

        $buyer = User::factory()->create([
            'role' => 'buyer',
            'approval_status' => 'approved',
            'email' => 'chatbuyer@lumora.test',
            'name' => 'Elena Buyer',
        ]);
        $otherBuyer = User::factory()->create([
            'role' => 'buyer',
            'approval_status' => 'approved',
            'email' => 'otherbuyer@lumora.test',
        ]);
        $seller = User::factory()->create([
            'role' => 'seller',
            'approval_status' => 'approved',
            'shop_name' => 'Atelier Luxe',
        ]);
        $product = Product::create([
            'seller_id' => $seller->id,
            'name' => 'Vermeil Signet Ring',
            'category' => 'rings',
            'description' => '18k gold vermeil ring',
            'price' => 2450,
            'stock' => 5,
            'status' => 'active',
            'approval_status' => 'approved',
        ]);

        $token = $buyer->createToken('Mobile App')->plainTextToken;
        $otherToken = $otherBuyer->createToken('Other App')->plainTextToken;

        // Start Seller chat with product context & first message
        $start = $this->withToken($token)->postJson('/api/buyer/chats/start', [
            'product_id' => $product->id,
            'seller_id' => (string) $seller->id,
            'message' => 'Is size 7 available in stock?',
        ])->assertStatus(201);

        $conversationId = (int) $start->json('conversation.id');
        $this->assertSame('Atelier Luxe', $start->json('conversation.seller_name'));
        $this->assertSame((string) $product->id, $start->json('conversation.product_id'));

        // Simulate incoming seller reply
        Message::create([
            'conversation_id' => $conversationId,
            'sender_id' => $seller->id,
            'body' => 'Yes, Size 7 ships tomorrow morning.',
            'is_bot' => false,
            'is_read' => false,
        ]);
        Conversation::where('id', $conversationId)->update(['last_message_at' => now()]);

        // Inbox reflects unread seller reply
        $this->withToken($token)->getJson('/api/buyer/chats')
            ->assertOk()
            ->assertJsonPath('conversations.0.unread_count', 1)
            ->assertJsonPath('total_unread', 1);

        // Other buyer cannot read or post to this thread
        $this->app['auth']->forgetGuards();
        $this->withToken($otherToken)->getJson("/api/buyer/chats/{$conversationId}")
            ->assertStatus(403);
        $this->app['auth']->forgetGuards();

        // Opening thread returns ordered messages and marks seller reply as read
        $this->withToken($token)->getJson("/api/buyer/chats/{$conversationId}")
            ->assertOk()
            ->assertJsonCount(2, 'conversation.messages')
            ->assertJsonPath('conversation.messages.1.body', 'Yes, Size 7 ships tomorrow morning.');

        $this->withToken($token)->getJson('/api/buyer/chats')
            ->assertOk()
            ->assertJsonPath('total_unread', 0);

        // Buyer sends image attachment
        $tinyPng = 'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=';
        $msgRes = $this->withToken($token)->postJson("/api/buyer/chats/{$conversationId}/messages", [
            'message' => 'Here is my ring size reference',
            'attachment_data' => $tinyPng,
            'attachment_name' => 'ring-size.png',
        ])->assertStatus(201);

        $attachmentUrl = $msgRes->json('message_item.attachment_url');
        $this->assertNotEmpty($attachmentUrl);
        $this->assertStringContainsString('/chat-attachments/', $attachmentUrl);
        $attachmentFilename = basename(parse_url($attachmentUrl, PHP_URL_PATH));
        $this->get('/chat-attachments/'.$attachmentFilename)->assertOk();
        @unlink(storage_path('app/public/chat-attachments/'.$attachmentFilename));

        // Support concierge chat with Gemini AI reply and [Product report] bypass
        config(['services.gemini.key' => 'fake-test-gemini-key']);
        Http::fake([
            'generativelanguage.googleapis.com/*' => Http::response([
                'candidates' => [[
                    'content' => ['parts' => [['text' => 'I can help track your Lumora order or escrow status.']]],
                ]],
            ], 200),
        ]);

        $this->withToken($token)->getJson('/api/support/chat')
            ->assertOk()
            ->assertJsonPath('conversation.seller_id', 'support');

        $this->withToken($token)->postJson('/api/support/chat/send', [
            'message' => 'How long is buyer escrow protection?',
        ])->assertStatus(201)
            ->assertJsonPath('message_item.is_from_user', true)
            ->assertJsonPath('bot_message.is_bot', true)
            ->assertJsonPath('bot_message.body', 'I can help track your Lumora order or escrow status.');

        // Product report skips AI bot and leaves for human admin review
        $this->withToken($token)->postJson('/api/support/chat/send', [
            'message' => '[Product report] Product #'.$product->id.' suspicious listing.',
        ])->assertStatus(201)
            ->assertJsonPath('bot_message', null);
    }
}
