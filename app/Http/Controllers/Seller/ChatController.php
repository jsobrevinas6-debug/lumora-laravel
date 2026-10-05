<?php

namespace App\Http\Controllers\Seller;

use App\Http\Controllers\Controller;
use App\Models\Conversation;
use App\Models\Message;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Validation\ValidationException;
use Illuminate\View\View;

class ChatController extends Controller
{
    public function index(Request $request): View
    {
        [$conversations, $activeConversation] = $this->conversationData($request);

        if ($activeConversation) {
            $this->markConversationRead($activeConversation);
            [$conversations, $activeConversation] = $this->conversationData($request, $activeConversation);
        }

        return view('seller.chats', [
            'conversations' => $conversations,
            'activeConversation' => $activeConversation,
            'tab' => $this->tab($request),
            'search' => trim((string) $request->query('search', '')),
        ]);
    }

    public function show(Request $request, Conversation $conversation): View
    {
        $this->authorizeConversation($conversation);
        $this->markConversationRead($conversation);

        [$conversations] = $this->conversationData($request, $conversation);

        return view('seller.chats', [
            'conversations' => $conversations,
            'activeConversation' => $conversation->load(['buyer', 'product', 'messages.sender']),
            'tab' => $this->tab($request),
            'search' => trim((string) $request->query('search', '')),
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

        return redirect()->route('seller.chats.show', $conversation);
    }

    public function read(Conversation $conversation): RedirectResponse
    {
        $this->authorizeConversation($conversation);
        $this->markConversationRead($conversation);

        return back();
    }

    private function conversationData(Request $request, ?Conversation $preferred = null): array
    {
        $sellerId = (int) Auth::id();
        $tab = $this->tab($request);
        $search = trim((string) $request->query('search', ''));

        $query = Conversation::query()
            ->where('seller_id', $sellerId)
            ->with(['buyer', 'product', 'latestMessage.sender'])
            ->withCount([
                'messages as unread_count' => fn ($messages) => $messages
                    ->where('sender_id', '!=', $sellerId)
                    ->whereNull('read_at'),
            ])
            ->orderByDesc('last_message_at')
            ->orderByDesc('updated_at');

        if ($tab === 'unread') {
            $query->whereHas('messages', fn ($messages) => $messages
                ->where('sender_id', '!=', $sellerId)
                ->whereNull('read_at'));
        }

        if ($search !== '') {
            $query->whereHas('buyer', fn ($buyer) => $buyer->where('name', 'like', "%{$search}%"));
        }

        $conversations = $query->get();
        $activeConversation = $preferred ?: $conversations->first();

        if ($activeConversation) {
            $activeConversation->load(['buyer', 'product', 'messages.sender']);
        }

        return [$conversations, $activeConversation];
    }

    private function authorizeConversation(Conversation $conversation): void
    {
        abort_unless((int) $conversation->seller_id === (int) Auth::id(), 403);
    }

    private function tab(Request $request): string
    {
        $tab = $request->query('tab', 'all');

        return in_array($tab, ['all', 'unread'], true) ? $tab : 'all';
    }

    private function markConversationRead(Conversation $conversation): void
    {
        $conversation->messages()
            ->where('sender_id', '!=', Auth::id())
            ->whereNull('read_at')
            ->update(['read_at' => now(), 'is_read' => true]);
    }
}
