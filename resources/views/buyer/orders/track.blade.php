@php
    $trackingLabel = fn ($event) => $event->tracking_label ?: match ($event->tracking_status) {
        'received' => 'Received by Lumora Logistics',
        'scanned' => 'Scanned at logistics hub',
        'sorted' => 'Sorted at logistics hub',
        'assigned' => 'Assigned to courier',
        'rider_received' => 'Received by courier',
        'in_transit' => 'In Transit',
        'out_for_delivery' => 'Out for Delivery',
        'delivered' => 'Delivered',
        'exception', 'failed' => 'Delivery exception',
        default => \Illuminate\Support\Str::headline($event->status),
    };
@endphp
<!doctype html>
<html lang="en">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Track order #{{ $order->order_number ?: $order->id }} | Lumora</title>
    @vite(['resources/css/app.css', 'resources/js/app.js'])
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Fraunces:opsz,wght@0,500;0,600;0,700&family=Inter:wght@400;500;600;700&display=swap" rel="stylesheet">
    <style>
        :root { --bg:#F7F1EC; --card:#FFFDFC; --ink:#3B1E34; --body:#4A3A3D; --muted:#8B7C7B; --border:#EAE3DD; --accent:#C98F72; }
        * { box-sizing:border-box; }
        body { margin:0; background:var(--bg); color:var(--body); font:14px/1.6 Inter,system-ui,sans-serif; }
        a { color:inherit; text-decoration:none; }
        .header { min-height:72px; display:flex; align-items:center; justify-content:space-between; gap:16px; padding:12px max(20px,calc((100% - 900px)/2)); background:var(--card); border-bottom:1px solid var(--border); }
        .brand { color:var(--ink); font:600 25px/1 Fraunces,Georgia,serif; letter-spacing:.2em; }
        .header a:last-child { color:var(--ink); font-size:13px; font-weight:600; }
        .page { width:min(900px,calc(100% - 32px)); margin:0 auto; padding:34px 0 56px; }
        .back { display:inline-block; margin-bottom:18px; color:#B96562; font-size:13px; font-weight:600; }
        .heading { margin-bottom:20px; }
        .eyebrow { color:#B96562; font-size:11px; font-weight:700; letter-spacing:.16em; text-transform:uppercase; }
        h1,h2,h3,p { margin-top:0; }
        h1 { margin:4px 0 8px; color:var(--ink); font:600 clamp(28px,5vw,40px)/1.15 Fraunces,Georgia,serif; }
        .subheading { margin:0; color:var(--muted); }
        .panel { margin-bottom:18px; padding:22px 24px; border:1px solid var(--border); border-radius:15px; background:var(--card); box-shadow:0 10px 30px rgba(74,42,46,.035); }
        .summary { display:grid; grid-template-columns:minmax(0,1fr) auto; align-items:center; gap:16px; }
        .summary h2 { margin:0; color:var(--ink); font-size:16px; }
        .summary p { margin:4px 0 0; color:var(--muted); font-size:12px; }
        .status { display:inline-flex; padding:7px 12px; border-radius:999px; background:#F8E9E5; color:var(--ink); font-size:12px; font-weight:700; white-space:nowrap; }
        .items { display:grid; gap:9px; margin:15px 0 0; padding-top:14px; border-top:1px solid var(--border); }
        .item { display:flex; justify-content:space-between; gap:12px; color:var(--body); font-size:12px; }
        .item strong { color:var(--ink); }
        .panel-title { margin:0 0 18px; color:var(--ink); font:600 23px/1.25 Fraunces,Georgia,serif; }
        .timeline { display:grid; }
        .event { position:relative; display:grid; grid-template-columns:20px minmax(0,1fr); column-gap:13px; min-height:92px; }
        .event:not(:last-child)::before { position:absolute; top:18px; bottom:-1px; left:8px; width:2px; background:var(--border); content:""; }
        .marker { position:relative; z-index:1; width:18px; height:18px; display:grid; place-items:center; border:1.5px solid var(--accent); border-radius:50%; background:var(--card); color:var(--ink); font-size:10px; }
        .event:first-child .marker { background:#F7E9E4; }
        .event-body { padding-bottom:20px; }
        .event h3 { margin:0; color:var(--ink); font-size:13px; font-weight:700; line-height:1.45; }
        .event p { margin:4px 0 0; color:var(--body); font-size:11px; line-height:1.55; }
        .event .time { margin-top:7px; color:var(--muted); font-size:10px; }
        .empty { margin:0; color:var(--muted); }
        .actions { display:flex; flex-wrap:wrap; gap:10px; }
        .button { min-height:44px; display:inline-flex; align-items:center; justify-content:center; padding:9px 15px; border:1px solid var(--ink); border-radius:8px; color:var(--ink); font-size:12px; font-weight:700; }
        .button.primary { background:var(--ink); color:#fff; }
        @media(max-width:540px) { .header{padding:12px 16px}.page{padding-top:24px}.panel{padding:18px 16px}.summary{grid-template-columns:1fr}.status{justify-self:start} }
    </style>
</head>
<body>
    <header class="header">
        <a class="brand" href="{{ route('shop.index') }}">LUMORA</a>
        <a href="{{ route('buyer.orders.index') }}">My orders</a>
    </header>
    <main class="page">
        <a class="back" href="{{ route('buyer.orders.show', $order) }}">← Back to order details</a>
        <section class="heading" aria-labelledby="track-title">
            <span class="eyebrow">Order tracking</span>
            <h1 id="track-title">Track your order</h1>
            <p class="subheading">Order #{{ $order->order_number ?: $order->id }} · Placed {{ $order->created_at?->timezone('Asia/Manila')->format('M j, Y') ?? 'date unavailable' }}</p>
        </section>

        <section class="panel" aria-label="Order summary">
            <div class="summary">
                <div>
                    <h2>{{ $order->items->count() === 1 ? ($order->items->first()->product?->name ?? 'Your order') : 'Your order' }}</h2>
                    <p>
                        @if ($order->tracking_number) Tracking number {{ $order->tracking_number }} · @endif
                        {{ $order->courier ?: 'Lumora Logistics' }}
                    </p>
                </div>
                <span class="status">{{ $order->status_label }}</span>
            </div>
            <div class="items">
                @foreach ($order->items as $item)
                    <div class="item"><span>{{ $item->product?->name ?? 'Product' }} × {{ $item->quantity }}</span><strong>₱{{ number_format((float) $item->subtotal, 2) }}</strong></div>
                @endforeach
            </div>
        </section>

        <section class="panel" aria-labelledby="timeline-title">
            <h2 class="panel-title" id="timeline-title">Delivery updates</h2>
            @if ($order->statusHistory->isNotEmpty())
                <div class="timeline" role="list" aria-label="Parcel tracking updates">
                    @foreach ($order->statusHistory as $event)
                        <article class="event" role="listitem">
                            <span class="marker" aria-hidden="true">{{ $loop->first ? '✓' : '·' }}</span>
                            <div class="event-body">
                                <h3>{{ $trackingLabel($event) }}</h3>
                                @if ($event->location)<p>{{ $event->location }}</p>@endif
                                @if ($event->remarks)<p>{{ $event->remarks }}</p>@endif
                                @if ($event->courier_name)<p>Courier {{ $event->courier_name }}</p>@endif
                                <p class="time">{{ $event->created_at?->timezone('Asia/Manila')->format('M j, Y · g:i A') ?? 'Time unavailable' }} PHT</p>
                            </div>
                        </article>
                    @endforeach
                </div>
            @else
                <p class="empty">Tracking updates will appear here after Lumora Logistics scans your parcel.</p>
            @endif
        </section>

        <nav class="actions" aria-label="Order actions">
            <a class="button primary" href="{{ route('buyer.orders.show', $order) }}">View order details</a>
            <a class="button" href="{{ route('buyer.orders.index') }}">Back to my orders</a>
        </nav>
    </main>
</body>
</html>
