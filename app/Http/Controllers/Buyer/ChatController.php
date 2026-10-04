<?php

namespace App\Http\Controllers\Buyer;

use App\Http\Controllers\Controller;
use App\Models\Conversation;
use App\Models\Message;
use App\Models\Product;
use App\Models\User;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Validation\ValidationException;
use Illuminate\View\View;

class ChatController extends Controller
{
    public function startSeller(User $seller): RedirectResponse
    {
        abort_unless($seller->role === 'seller' || $seller->approvedSellerApplication, 404);
        abort_if((int) Auth::id() === (int) $seller->id, 403, 'You cannot chat with your own shop.');

        $conversation = $this->findOrCreateConversation($seller);

        return redirect()->route('buyer.chats.show', $conversation);
    }

    public function startProduct(Product $product): RedirectResponse
    {
        abort_unless($product->status === 'active' && $product->seller, 404);
        abort_if((int) Auth::id() === (int) $product->seller_id, 403, 'You cannot chat with your own shop.');

        $conversation = $this->findOrCreateConversation($product->seller, $product);

        return redirect()->route('buyer.chats.show', $conversation);
    }

    public function show(Conversation $conversation): View
    {
        $this->authorizeConversation($conversation);
        $this->markConversationRead($conversation);

        $conversation->load(['seller.approvedSellerApplication', 'seller.sellerApplication', 'product', 'messages.sender']);

        return view('buyer.chats.show', [
            'conversation' => $conversation,
            'sellerProfile' => $this->sellerProfile($conversation->seller),
        ]);
    }

    public function store(Request $request, Conversation $conversation): RedirectResponse
    {
        $this->authorizeConversation($conversation);
        $body = trim((string) $request->input('message'));

        if ($body === '') {
            throw ValidationException::withMessages(['message' => 'Please enter a message.']);
        }

        $request->validate(['message' => ['required', 'string', 'max:2000']]);

        Message::create([
            'conversation_id' => $conversation->id,
            'sender_id' => Auth::id(),
            'body' => $body,
        ]);

        $conversation->update(['last_message_at' => now()]);

        return redirect()->route('buyer.chats.show', $conversation);
    }

    private function findOrCreateConversation(User $seller, ?Product $product = null): Conversation
    {
        $conversation = Conversation::firstOrCreate(
            [
                'buyer_id' => Auth::id(),
                'seller_id' => $seller->id,
            ],
            [
                'user_id' => Auth::id(),
                'product_id' => $product?->id,
                'last_message_at' => now(),
            ]
        );

        if ($product && ! $conversation->product_id) {
            $conversation->update(['product_id' => $product->id]);
        }

        return $conversation;
    }

    private function authorizeConversation(Conversation $conversation): void
    {
        abort_unless((int) $conversation->buyer_id === (int) Auth::id(), 403);
    }

    private function sellerProfile(User $seller): array
    {
        $seller->loadMissing(['approvedSellerApplication', 'sellerApplication']);

        $shopName = $seller->shop_name
            ?: ($seller->approvedSellerApplication?->business_name
                ?: ($seller->sellerApplication?->business_name ?: $seller->name));

        $initials = collect(preg_split('/\s+/', trim((string) $shopName)))
            ->filter()
            ->map(fn ($part) => mb_substr($part, 0, 1))
            ->take(2)
            ->implode('');

        return [
            'name' => $shopName ?: 'Lumora seller',
            'avatar' => $seller->avatar,
            'initials' => mb_strtoupper($initials ?: 'LS'),
            'verified' => (bool) $seller->approvedSellerApplication,
        ];
    }

    private function markConversationRead(Conversation $conversation): void
    {
        $conversation->messages()
            ->where('sender_id', '!=', Auth::id())
            ->whereNull('read_at')
            ->update(['read_at' => now(), 'is_read' => true]);
    }
}
