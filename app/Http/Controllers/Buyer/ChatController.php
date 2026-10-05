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
    public function index(): View
    {
        $conversations = $this->conversationList();

        return view('buyer.chats.index', [
            'conversations' => $conversations,
        ]);
    }

    public function start(Request $request): View|RedirectResponse
    {
        [$seller, $product] = $this->sellerAndProductFromRequest($request);
        $this->authorizeStart($seller);

        $conversation = $this->findConversation($seller, $product);

        if ($conversation?->messages()->exists()) {
            return redirect()->route('buyer.chats.show', $conversation);
        }

        return view('buyer.chats.start', [
            'seller' => $seller,
            'product' => $product,
            'conversation' => $conversation,
            'sellerProfile' => $this->sellerProfile($seller),
        ]);
    }

    public function begin(Request $request): RedirectResponse
    {
        [$seller, $product] = $this->sellerAndProductFromRequest($request);
        $this->authorizeStart($seller);

        $body = trim((string) $request->input('message'));

        if ($body === '') {
            throw ValidationException::withMessages(['message' => 'Please enter a message.']);
        }

        $request->validate([
            'message' => ['required', 'string', 'max:2000'],
        ]);

        $conversation = $this->findOrCreateConversation($seller, $product);

        Message::create([
            'conversation_id' => $conversation->id,
            'sender_id' => Auth::id(),
            'body' => $body,
        ]);

        $conversation->update(['last_message_at' => now()]);

        return redirect()->route('buyer.chats.show', $conversation);
    }

    public function startSeller(User $seller): RedirectResponse
    {
        abort_unless($seller->role === 'seller' || $seller->approvedSellerApplication, 404);

        return redirect()->route('buyer.chats.start', ['seller' => $seller->id]);
    }

    public function startProduct(Product $product): RedirectResponse
    {
        abort_unless($product->status === 'active' && $product->seller, 404);

        return redirect()->route('buyer.chats.start', ['product' => $product->id]);
    }

    public function show(Conversation $conversation): View
    {
        $this->authorizeConversation($conversation);
        $this->markConversationRead($conversation);

        $conversation->load(['seller.approvedSellerApplication', 'seller.sellerApplication', 'product', 'messages.sender']);

        return view('buyer.chats.show', [
            'conversation' => $conversation,
            'conversations' => $this->conversationList(),
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
        return Conversation::firstOrCreate(
            [
                'buyer_id' => Auth::id(),
                'seller_id' => $seller->id,
                'product_id' => $product?->id,
            ],
            [
                'user_id' => Auth::id(),
                'last_message_at' => now(),
            ]
        );
    }

    private function findConversation(User $seller, ?Product $product = null): ?Conversation
    {
        return Conversation::query()
            ->where('buyer_id', Auth::id())
            ->where('seller_id', $seller->id)
            ->where('product_id', $product?->id)
            ->first();
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

    private function sellerAndProductFromRequest(Request $request): array
    {
        $request->validate([
            'seller' => ['nullable', 'integer', 'exists:users,id'],
            'seller_id' => ['nullable', 'integer', 'exists:users,id'],
            'product' => ['nullable', 'integer', 'exists:products,id'],
            'product_id' => ['nullable', 'integer', 'exists:products,id'],
        ]);

        $productId = $request->integer('product') ?: $request->integer('product_id');
        $sellerId = $request->integer('seller') ?: $request->integer('seller_id');
        $product = null;

        if ($productId) {
            $product = Product::query()
                ->with('seller.approvedSellerApplication', 'seller.sellerApplication')
                ->where('status', 'active')
                ->findOrFail($productId);
            $seller = $product->seller;
        } else {
            abort_unless($sellerId, 404);

            $seller = User::query()
                ->with(['approvedSellerApplication', 'sellerApplication'])
                ->findOrFail($sellerId);
        }

        abort_unless($seller && ($seller->role === 'seller' || $seller->approvedSellerApplication), 404);

        return [$seller, $product];
    }

    private function authorizeStart(User $seller): void
    {
        abort_if((int) Auth::id() === (int) $seller->id, 403, 'You cannot chat with your own shop.');
        abort_if(Auth::user()?->role === 'admin', 403);
    }

    private function conversationList()
    {
        return Conversation::query()
            ->where('buyer_id', Auth::id())
            ->with(['seller.approvedSellerApplication', 'seller.sellerApplication', 'product', 'latestMessage.sender'])
            ->withCount([
                'messages as unread_count' => fn ($messages) => $messages
                    ->where('sender_id', '!=', Auth::id())
                    ->whereNull('read_at'),
            ])
            ->orderByDesc('last_message_at')
            ->orderByDesc('updated_at')
            ->get();
    }
}
