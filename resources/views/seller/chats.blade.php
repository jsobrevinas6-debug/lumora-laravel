@extends('layouts.seller')

@section('title', 'Chats')

@push('styles')
<style>
    .chat-subtitle { margin:-20px 0 24px; color:var(--text-muted); font-size:14px; }
    .chat-layout { min-height:calc(100vh - 170px); display:grid; grid-template-columns:300px minmax(0,1fr) 260px; gap:0; overflow:hidden; border:1px solid var(--border); border-radius:20px; background:#FFFDFC; box-shadow:0 4px 18px rgba(91,26,53,.04); }
    .chat-panel { background:#FFFDFC; overflow:hidden; }
    .conversation-panel { border-right:1px solid var(--border); }
    .context-panel { border-left:1px solid var(--border); }
    .conversation-panel { display:flex; flex-direction:column; min-height:620px; }
    .conversation-tabs { display:flex; gap:8px; padding:14px; border-bottom:1px solid var(--border); }
    .conversation-tab { flex:1; min-height:36px; display:grid; place-items:center; border-radius:10px; color:var(--text-muted); text-decoration:none; font-size:12px; font-weight:700; }
    .conversation-tab.active { background:var(--maroon); color:#fff; }
    .conversation-search { padding:14px; border-bottom:1px solid var(--border); }
    .conversation-search input { width:100%; height:40px; border:1px solid var(--border); border-radius:12px; padding:0 12px; font:inherit; color:var(--text-dark); }
    .conversation-list { flex:1; overflow-y:auto; padding:8px; }
    .conversation-row { display:grid; grid-template-columns:42px minmax(0,1fr) auto; gap:10px; padding:12px; border-radius:14px; color:inherit; text-decoration:none; }
    .conversation-row:hover, .conversation-row.active { background:var(--bg); }
    .chat-avatar { width:42px; height:42px; display:grid; place-items:center; border-radius:50%; background:#F7EAE2; color:var(--maroon); font-weight:800; overflow:hidden; }
    .chat-avatar img { width:100%; height:100%; object-fit:cover; }
    .conversation-name { font-size:13.5px; font-weight:800; white-space:nowrap; overflow:hidden; text-overflow:ellipsis; }
    .conversation-preview { margin-top:3px; color:var(--text-muted); font-size:12px; white-space:nowrap; overflow:hidden; text-overflow:ellipsis; }
    .conversation-meta { display:grid; justify-items:end; gap:7px; color:var(--text-muted); font-size:11px; }
    .unread-pill { min-width:20px; height:20px; display:grid; place-items:center; padding:0 6px; border-radius:999px; background:var(--coral); color:#fff; font-size:11px; font-weight:800; }
    .chat-main { display:flex; flex-direction:column; min-height:620px; }
    .chat-header { display:flex; align-items:center; gap:12px; padding:16px 18px; border-bottom:1px solid var(--border); }
    .chat-header h2 { margin:0; font-size:16px; font-weight:800; }
    .chat-header span { color:var(--text-muted); font-size:12px; }
    .messages { flex:1; overflow-y:auto; display:flex; flex-direction:column; gap:12px; padding:20px; background:#FFFDFC; }
    .message-row { display:flex; }
    .message-row.mine { justify-content:flex-end; }
    .message-bubble { max-width:70%; padding:11px 13px; border-radius:14px 14px 14px 4px; background:#F7F1EC; color:var(--text-dark); font-size:13.5px; line-height:1.55; }
    .message-row.mine .message-bubble { background:var(--maroon); color:#fff; border-radius:14px 14px 4px 14px; }
    .message-time { margin-top:5px; color:rgba(139,122,128,.85); font-size:10.5px; }
    .message-row.mine .message-time { color:rgba(255,255,255,.72); text-align:right; }
    .composer { display:flex; align-items:flex-end; gap:10px; padding:14px; border-top:1px solid var(--border); background:#fff; }
    .composer textarea { flex:1; min-height:48px; max-height:120px; resize:vertical; border:1px solid var(--border); border-radius:14px; padding:13px 14px; font:inherit; }
    .send-btn { width:48px; height:48px; display:grid; place-items:center; border:0; border-radius:14px; background:var(--maroon); color:#fff; cursor:pointer; }
    .send-btn svg { width:19px; height:19px; }
    .context-panel { padding:18px; overflow-y:auto; }
    .context-panel h3 { margin:0 0 14px; font-size:15px; font-weight:800; }
    .context-product { border:1px solid var(--border); border-radius:14px; overflow:hidden; }
    .context-product img { width:100%; aspect-ratio:4/3; object-fit:cover; background:var(--bg); }
    .context-product-body { padding:12px; }
    .context-product-title { font-size:13px; font-weight:800; }
    .context-product-price { margin-top:5px; color:var(--coral); font-size:13px; font-weight:800; }
    .context-link { min-height:38px; display:flex; align-items:center; justify-content:center; margin-top:10px; border-radius:10px; background:var(--maroon); color:#fff; text-decoration:none; font-size:12px; font-weight:800; }
    .customer-card { display:flex; align-items:center; gap:11px; border:1px solid var(--border); border-radius:14px; padding:12px; }
    .customer-card + .customer-card { margin-top:12px; }
    .customer-name { color:var(--maroon); font-size:13px; font-weight:800; }
    .customer-meta { margin-top:4px; color:var(--text-muted); font-size:12px; line-height:1.45; overflow-wrap:anywhere; }
    .empty-chat { height:100%; display:grid; place-items:center; padding:32px; color:var(--text-muted); text-align:center; }
    @media (max-width:1200px) { .chat-layout { grid-template-columns:300px minmax(0,1fr); } .context-panel { display:none; } }
    @media (max-width:820px) { .chat-layout { grid-template-columns:1fr; } .conversation-panel, .chat-main { min-height:auto; } }
</style>
@endpush

@section('content')
    <p class="chat-subtitle">Manage your conversations with customers.</p>

    <div class="chat-layout">
        <aside class="chat-panel conversation-panel">
            <div class="conversation-tabs">
                <a class="conversation-tab {{ $tab === 'all' ? 'active' : '' }}" href="{{ route('seller.chats.index', ['tab' => 'all']) }}">All</a>
                <a class="conversation-tab {{ $tab === 'unread' ? 'active' : '' }}" href="{{ route('seller.chats.index', ['tab' => 'unread']) }}">Unread</a>
            </div>
            <form class="conversation-search" method="GET" action="{{ route('seller.chats.index') }}">
                <input type="hidden" name="tab" value="{{ $tab }}">
                <input type="search" name="search" value="{{ $search }}" placeholder="Search conversations..." aria-label="Search conversations">
            </form>
            <div class="conversation-list">
                @forelse ($conversations as $conversation)
                    @php
                        $buyer = $conversation->buyer;
                        $name = $buyer?->name ?? 'Lumora customer';
                        $initial = strtoupper(substr($name, 0, 1));
                        $last = $conversation->latestMessage;
                    @endphp
                    <a class="conversation-row {{ $activeConversation?->id === $conversation->id ? 'active' : '' }}" href="{{ route('seller.chats.show', $conversation) }}">
                        <div class="chat-avatar">@if ($buyer?->avatar)<img src="{{ $buyer->avatar }}" alt="">@else{{ $initial }}@endif</div>
                        <div>
                            <div class="conversation-name">{{ $name }}</div>
                            <div class="conversation-preview">{{ $last?->body ?? 'No messages yet.' }}</div>
                        </div>
                        <div class="conversation-meta">
                            <span>{{ $last?->created_at?->diffForHumans(null, true) ?? '' }}</span>
                            @if ((int) $conversation->unread_count > 0)
                                <span class="unread-pill">{{ $conversation->unread_count }}</span>
                            @endif
                        </div>
                    </a>
                @empty
                    <div class="empty-chat"><div><strong>No conversations yet.</strong><br>Customer messages will appear here.</div></div>
                @endforelse
            </div>
        </aside>

        <section class="chat-panel chat-main">
            @if ($activeConversation)
                @php
                    $buyer = $activeConversation->buyer;
                    $name = $buyer?->name ?? 'Lumora customer';
                    $initial = strtoupper(substr($name, 0, 1));
                @endphp
                <div class="chat-header">
                    <div class="chat-avatar">@if ($buyer?->avatar)<img src="{{ $buyer->avatar }}" alt="">@else{{ $initial }}@endif</div>
                    <div>
                        <h2>{{ $name }}</h2>
                        <span>Customer</span>
                    </div>
                </div>
                <div class="messages" data-message-list>
                    @forelse ($activeConversation->messages->sortBy('created_at') as $message)
                        <div class="message-row {{ (int) $message->sender_id === (int) Auth::id() ? 'mine' : '' }}">
                            <div class="message-bubble">
                                <div>{{ $message->body }}</div>
                                <div class="message-time">{{ $message->created_at?->format('M d, g:i A') }}</div>
                            </div>
                        </div>
                    @empty
                    <div class="empty-chat">No messages yet. Reply when your customer starts the conversation.</div>
                    @endforelse
                </div>
                <form class="composer" method="POST" action="{{ route('seller.chats.messages.store', $activeConversation) }}">
                    @csrf
                    <textarea name="message" placeholder="Type a message..." required maxlength="2000">{{ old('message') }}</textarea>
                    <button class="send-btn" type="submit" aria-label="Send message"><svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8"><path d="m22 2-7 20-4-9-9-4 20-7Z"/><path d="M22 2 11 13"/></svg></button>
                </form>
            @else
                <div class="empty-chat">Select a conversation to start messaging.</div>
            @endif
        </section>

        <aside class="chat-panel context-panel">
            <h3>Order / Product Context</h3>
            @if ($activeConversation?->product)
                @php $product = $activeConversation->product; @endphp
                <div class="context-product">
                    <img src="{{ $product->image_url }}" alt="{{ $product->name }}" onerror="this.onerror=null;this.src='{{ asset('images/product-placeholder.png') }}';">
                    <div class="context-product-body">
                        <div class="context-product-title">{{ $product->name }}</div>
                        <div class="context-product-price">&#8369;{{ number_format((float) $product->price, 2) }}</div>
                        <a class="context-link" href="{{ route('shop.product', ['id' => $product->id]) }}">View Product</a>
                    </div>
                </div>
            @else
                <p style="color:var(--text-muted);font-size:13px;line-height:1.6;">No product was attached to this conversation.</p>
            @endif

            <h3 style="margin-top:22px;">Customer Information</h3>
            @if ($activeConversation?->buyer)
                @php
                    $buyer = $activeConversation->buyer;
                    $buyerName = $buyer->name ?? 'Lumora customer';
                    $buyerInitial = strtoupper(substr($buyerName, 0, 1));
                @endphp
                <div class="customer-card">
                    <div class="chat-avatar">@if ($buyer->avatar)<img src="{{ $buyer->avatar }}" alt="">@else{{ $buyerInitial }}@endif</div>
                    <div>
                        <div class="customer-name">{{ $buyerName }}</div>
                        <div class="customer-meta">{{ $buyer->email }}</div>
                        <div class="customer-meta">Joined {{ $buyer->created_at?->format('M Y') ?? 'recently' }}</div>
                    </div>
                </div>
            @else
                <p style="color:var(--text-muted);font-size:13px;line-height:1.6;">Select a conversation to view customer details.</p>
            @endif
        </aside>
    </div>
@endsection

@push('scripts')
<script>
    const messageList = document.querySelector('[data-message-list]');
    if (messageList) {
        messageList.scrollTop = messageList.scrollHeight;
    }
</script>
@endpush
