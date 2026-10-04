<!DOCTYPE html>
<html lang="{{ str_replace('_', '-', app()->getLocale()) }}">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <meta name="csrf-token" content="{{ csrf_token() }}">
    <title>Messages with {{ $sellerProfile['name'] }} &middot; {{ config('app.name', 'Lumora') }}</title>
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Playfair+Display:wght@500;600;700&family=Inter:wght@400;500;600;700;800&display=swap" rel="stylesheet">
    @vite(['resources/css/app.css', 'resources/js/app.js'])
    <style>
        :root { --cream:#F7F1EC; --paper:#FFFDFC; --plum:#3B1E34; --rose:#C98F72; --line:#EAE3DD; --text:#2F2528; --muted:#8B7B78; --green:#6F8F78; }
        * { box-sizing:border-box; }
        body { margin:0; background:var(--cream); color:var(--text); font-family:'Inter',ui-sans-serif,system-ui,sans-serif; }
        a { color:inherit; text-decoration:none; }
        .topbar { min-height:78px; display:flex; align-items:center; border-bottom:1px solid var(--line); background:rgba(255,253,252,.96); }
        .topbar-inner, .chat-shell { width:min(980px,calc(100% - 48px)); margin:0 auto; }
        .topbar-inner { display:flex; align-items:center; justify-content:space-between; gap:18px; }
        .cart-link { width:42px; height:42px; display:grid; place-items:center; border:1px solid var(--line); border-radius:50%; background:var(--paper); color:var(--plum); }
        .chat-shell { padding:30px 0 70px; }
        .back-link { display:inline-flex; margin-bottom:18px; color:var(--rose); font-size:13px; font-weight:800; }
        .chat-card { min-height:calc(100vh - 190px); display:flex; flex-direction:column; overflow:hidden; border:1px solid var(--line); border-radius:24px; background:var(--paper); box-shadow:0 10px 30px rgba(59,30,52,.05); }
        .chat-header { display:flex; align-items:center; gap:14px; padding:18px 20px; border-bottom:1px solid var(--line); }
        .seller-avatar { width:54px; height:54px; display:grid; place-items:center; overflow:hidden; border:1px solid var(--line); border-radius:50%; background:#F8EEE9; color:var(--plum); font-family:'Playfair Display',Georgia,serif; font-size:20px; font-weight:700; }
        .seller-avatar img { width:100%; height:100%; object-fit:cover; }
        .chat-header h1 { display:flex; align-items:center; gap:9px; flex-wrap:wrap; margin:0; color:var(--plum); font-family:'Playfair Display',Georgia,serif; font-size:26px; font-weight:600; }
        .verified { display:inline-flex; min-height:23px; align-items:center; padding:5px 9px; border-radius:999px; background:rgba(111,143,120,.14); color:var(--green); font-size:10px; font-weight:800; text-transform:uppercase; }
        .chat-header span { color:var(--muted); font-size:12px; }
        .messages { flex:1; min-height:430px; overflow-y:auto; display:flex; flex-direction:column; gap:12px; padding:22px; background:#FFFDFC; }
        .message-row { display:flex; }
        .message-row.mine { justify-content:flex-end; }
        .message-bubble { max-width:min(560px,78%); padding:11px 13px; border-radius:16px; background:#F8F4F1; color:var(--text); font-size:14px; line-height:1.55; border-bottom-left-radius:6px; }
        .message-row.mine .message-bubble { background:var(--plum); color:white; border-bottom-right-radius:6px; border-bottom-left-radius:16px; }
        .message-time { margin-top:5px; color:var(--muted); font-size:11px; }
        .message-row.mine .message-time { color:rgba(255,255,255,.72); text-align:right; }
        .composer { display:flex; align-items:flex-end; gap:10px; padding:15px; border-top:1px solid var(--line); background:var(--paper); }
        .composer textarea { flex:1; min-height:48px; max-height:130px; resize:vertical; border:1px solid var(--line); border-radius:14px; padding:13px 14px; color:var(--text); font:inherit; }
        .send-btn { width:48px; height:48px; display:grid; place-items:center; border:0; border-radius:14px; background:var(--plum); color:white; cursor:pointer; }
        .send-btn svg { width:19px; height:19px; }
        .product-context { display:flex; align-items:center; gap:12px; padding:12px 20px; border-bottom:1px solid var(--line); background:#F8F4F1; }
        .product-context img { width:54px; height:54px; border-radius:10px; object-fit:cover; background:#F8EEE9; }
        .product-context strong { display:block; color:var(--plum); font-size:13px; }
        .product-context span { color:var(--rose); font-size:12px; font-weight:800; }
        @media (max-width:680px) { .topbar-inner,.chat-shell { width:min(100% - 28px,980px); } .chat-header { align-items:flex-start; } .chat-header h1 { font-size:23px; } .message-bubble { max-width:88%; } }
    </style>
</head>
<body>
<header class="topbar">
    <div class="topbar-inner">
        <x-logo :href="route('shop.index')" aria-label="Lumora shop" />
        <a class="cart-link" href="{{ route('buyer.cart') }}" aria-label="View cart"><svg viewBox="0 0 24 24" width="19" height="19" fill="none" stroke="currentColor" stroke-width="1.8"><path d="M3 4h2l2.2 11.2a2 2 0 0 0 2 1.6h7.9a2 2 0 0 0 1.9-1.4L21 8H7"/><circle cx="10" cy="20" r="1"/><circle cx="18" cy="20" r="1"/></svg></a>
    </div>
</header>

<main class="chat-shell">
    <a class="back-link" href="{{ $conversation->product ? route('shop.product', ['id' => $conversation->product->id]) : route('shop.seller', ['seller' => $conversation->seller_id]) }}">&larr; Back to shop</a>
    <section class="chat-card">
        <div class="chat-header">
            <div class="seller-avatar" aria-hidden="true">
                @if ($sellerProfile['avatar'])
                    <img src="{{ $sellerProfile['avatar'] }}" alt="">
                @else
                    {{ $sellerProfile['initials'] }}
                @endif
            </div>
            <div>
                <h1>{{ $sellerProfile['name'] }} @if ($sellerProfile['verified'])<span class="verified">Verified Seller</span>@endif</h1>
                <span>Seller conversation</span>
            </div>
        </div>

        @if ($conversation->product)
            <a class="product-context" href="{{ route('shop.product', ['id' => $conversation->product->id]) }}">
                <img src="{{ $conversation->product->image_url }}" alt="{{ $conversation->product->name }}" onerror="this.onerror=null;this.src='{{ asset('images/product-placeholder.png') }}';">
                <div>
                    <strong>{{ $conversation->product->name }}</strong>
                    <span>&#8369;{{ number_format((float) $conversation->product->price, 2) }}</span>
                </div>
            </a>
        @endif

        <div class="messages" data-message-list>
            @forelse ($conversation->messages->sortBy('created_at') as $message)
                <div class="message-row {{ (int) $message->sender_id === (int) Auth::id() ? 'mine' : '' }}">
                    <div class="message-bubble">
                        <div>{{ $message->body }}</div>
                        <div class="message-time">{{ $message->created_at?->format('M d, g:i A') }}</div>
                    </div>
                </div>
            @empty
                <p style="margin:auto;color:var(--muted);">Send a message to start this conversation.</p>
            @endforelse
        </div>

        <form class="composer" method="POST" action="{{ route('buyer.chats.messages.store', $conversation) }}">
            @csrf
            <textarea name="message" placeholder="Type a message..." required maxlength="2000">{{ old('message') }}</textarea>
            <button class="send-btn" type="submit" aria-label="Send message"><svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8"><path d="m22 2-7 20-4-9-9-4 20-7Z"/><path d="M22 2 11 13"/></svg></button>
        </form>
    </section>
</main>

<script>
    const messageList = document.querySelector('[data-message-list]');
    if (messageList) messageList.scrollTop = messageList.scrollHeight;
</script>
</body>
</html>
