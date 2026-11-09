@php
    $buyer = $order->user;
    $cartCount = collect(session('lumora_cart', []))->sum('quantity');
    $currentStatus = (string) $order->status;
    $isCancelled = in_array($currentStatus, ['cancelled', 'returned'], true);
    $isDelivered = $currentStatus === 'delivered';
    $isActive = ! $isCancelled && ! $isDelivered;
    $statusTone = match ($currentStatus) {
        'pending' => 'pending',
        'processing', 'packed' => 'packed',
        'shipped' => 'shipped',
        'out_for_delivery' => 'out-for-delivery',
        'delivered' => 'delivered',
        'cancelled', 'returned' => 'cancelled',
        default => 'pending',
    };
    $deliveredHistory = $order->statusHistories->first(fn ($event) => in_array(strtolower((string) ($event->tracking_status ?: $event->status)), ['delivered', 'completed'], true));
    $deliveredDate = $order->delivered_at ?: $deliveredHistory?->created_at;
    $statusHeadline = match ($currentStatus) {
        'pending' => 'Your order is being prepared',
        'processing', 'packed' => 'Your order is being prepared',
        'shipped' => 'Your order is on its way',
        'out_for_delivery' => 'Your order is out for delivery',
        'delivered' => 'Delivered'.($deliveredDate ? ' on '.$deliveredDate->timezone('Asia/Manila')->format('M j') : ''),
        'cancelled' => 'Order cancelled',
        'returned' => 'Order returned',
        default => $order->status_label,
    };
    $statusExplanation = match ($currentStatus) {
        'pending' => 'The seller is getting your order ready.',
        'processing', 'packed' => 'Your order is being prepared for handoff to Lumora Logistics.',
        'shipped' => 'Lumora Logistics is moving your parcel toward its destination.',
        'out_for_delivery' => 'Your parcel is with the courier and should arrive soon.',
        'delivered' => 'Your parcel has been delivered to the address on your order.',
        'cancelled' => 'This order has been cancelled.',
        'returned' => 'This order has been returned.',
        default => 'We will keep your order status up to date here.',
    };
    $progressRank = match ($currentStatus) {
        'processing', 'packed' => 1,
        'shipped' => 2,
        'out_for_delivery' => 3,
        'delivered' => 4,
        'cancelled', 'returned' => -1,
        default => 0,
    };
    $steps = [
        ['label' => 'Placed', 'statuses' => ['pending']],
        ['label' => 'Packed', 'statuses' => ['packed', 'sorted', 'assigned']],
        ['label' => 'Shipped', 'statuses' => ['shipped', 'rider_received', 'in_transit']],
        ['label' => 'Out for delivery', 'statuses' => ['out_for_delivery']],
        ['label' => 'Delivered', 'statuses' => ['delivered', 'completed']],
    ];
    $latestUpdate = $order->statusHistories->first();
    $estimatedDelivery = $order->estimated_delivery;
    $addressLines = collect([
        trim(implode(' ', array_filter([$buyer?->house_number, $buyer?->street]))),
        $buyer?->barangay,
        trim(implode(', ', array_filter([$buyer?->municipality, $buyer?->province]))),
        $buyer?->postal_code,
    ])->filter()->values();
    $phone = preg_replace('/\D+/', '', (string) ($buyer?->contact_number ?? ''));
    $maskedPhone = $phone !== '' ? str_repeat('�', max(strlen($phone) - 4, 0)).substr($phone, -4) : null;
    $paymentLabel = match (strtolower((string) $order->payment_method)) {
        'cod' => 'Cash on delivery',
        'gcash' => 'GCash',
        'maya', 'paymaya' => 'Maya',
        'bank_transfer' => 'Bank transfer',
        default => filled($order->payment_method) ? \Illuminate\Support\Str::headline($order->payment_method) : 'Payment method unavailable',
    };
    $returnCanBeRequested = $returnRequestsEnabled && $isDelivered && ! $order->returnRequest;
@endphp
<!doctype html>
<html lang="en">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <meta name="csrf-token" content="{{ csrf_token() }}">
    <title>Track order #{{ $order->order_number ?: $order->id }} | Lumora</title>
    @vite(['resources/css/app.css', 'resources/js/app.js'])
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&family=Playfair+Display:wght@500;600;700&display=swap" rel="stylesheet">
    <style>
        :root{--cream:#f5f1ec;--white:#fff;--maroon:#4a1233;--rose:#c98b6b;--text:#3d3437;--muted:#6f6265;--line:#e8ddd6;--green:#2f754c;--amber:#8a5a00;--blue:#315a91;--teal:#17675f;--red:#a8323b}
        *{box-sizing:border-box}body{margin:0;background:var(--cream);color:var(--text);font:14px/1.55 Inter,system-ui,sans-serif}a{color:inherit;text-decoration:none}button,input{font:inherit}a:focus-visible,button:focus-visible,input:focus-visible{outline:3px solid var(--rose);outline-offset:3px}
        .site-header{position:sticky;top:0;z-index:20;background:var(--white);border-bottom:1px solid var(--line)}.site-header-inner{max-width:1480px;min-height:78px;margin:auto;padding:12px 32px;display:flex;align-items:center;gap:28px}.brand{width:205px;flex:0 0 205px;display:grid;justify-items:center;color:var(--maroon)}.brand-name{font:500 29px/.95 'Playfair Display',Georgia,serif;letter-spacing:.32em;text-transform:uppercase}.brand-name span{color:var(--rose)}.brand-tagline{margin-top:5px;font-size:8px;letter-spacing:.42em;text-transform:uppercase;color:#72656a}.header-search{flex:1;max-width:560px;min-height:42px;display:flex;align-items:center;gap:10px;padding:0 15px;border:1px solid var(--line);border-radius:999px;color:var(--muted)}.header-search svg,.header-action svg{width:18px;height:18px;flex:none}.header-search input{width:100%;border:0;background:transparent;color:var(--text);outline:none}.header-search input:focus-visible{outline:none}.header-actions{margin-left:auto;display:flex;align-items:center;gap:12px}.header-action{position:relative;width:42px;height:42px;display:grid;place-items:center;border-radius:50%;color:var(--maroon)}.header-action:hover{background:#f8f2ef}.cart-count{position:absolute;top:0;right:-1px;min-width:18px;height:18px;padding:0 4px;display:grid;place-items:center;border-radius:999px;background:var(--maroon);color:#fff;font-size:10px;font-weight:700}
        .page{max-width:1240px;margin:auto;padding:28px 30px 55px}.breadcrumb{display:flex;flex-wrap:wrap;align-items:center;gap:9px;margin:0 0 22px;color:var(--muted);font-size:12px}.breadcrumb a{color:var(--maroon);font-weight:600}.breadcrumb [aria-current]{color:var(--text)}.heading-row{display:flex;align-items:flex-end;justify-content:space-between;gap:18px;margin-bottom:20px}.eyebrow{margin:0 0 5px;color:var(--rose);font-size:11px;font-weight:700;letter-spacing:.16em}.page-title{margin:0;color:var(--maroon);font:600 clamp(29px,4vw,38px)/1.15 'Playfair Display',Georgia,serif}.order-ref{margin:6px 0 0;color:var(--muted);font-size:12px}.refresh-row{display:flex;align-items:center;gap:12px;color:var(--muted);font-size:12px}.refresh-button{min-height:40px;padding:0 15px;border:1px solid var(--maroon);border-radius:999px;background:var(--white);color:var(--maroon);font-size:12px;font-weight:700;cursor:pointer}.refresh-button:hover{background:#f8f2ef}.top-details-button{min-height:40px;white-space:nowrap}.top-nav-links{display:flex;align-items:center;gap:12px;flex-wrap:wrap}.top-back-link{white-space:nowrap}
        .card{border:1px solid var(--line);border-radius:20px;background:var(--white);box-shadow:0 8px 26px rgba(74,18,51,.045)}.status-card{padding:23px 25px;margin-bottom:18px}.status-overview{display:flex;align-items:flex-start;justify-content:space-between;gap:20px}.status-copy{min-width:0}.status-badge{display:inline-flex;align-items:center;min-height:28px;padding:4px 12px;border-radius:999px;font-size:11px;font-weight:700;letter-spacing:.03em}.status-pending{background:#fff1d1;color:var(--amber)}.status-packed{background:#e8f0fb;color:var(--blue)}.status-shipped,.status-out-for-delivery{background:#e0f2ef;color:var(--teal)}.status-delivered{background:#e5f2e9;color:var(--green)}.status-cancelled{background:#fbe8e8;color:var(--red)}.status-headline{margin:10px 0 3px;color:var(--maroon);font:600 23px/1.25 'Playfair Display',Georgia,serif}.status-explanation{margin:0;color:var(--muted);font-size:12px}.estimate-box{min-width:185px;padding:12px 15px;border:1px solid #ead8ce;border-radius:14px;background:#fffaf7}.estimate-label{display:block;color:var(--muted);font-size:10px;font-weight:700;letter-spacing:.08em;text-transform:uppercase}.estimate-date{display:block;margin-top:3px;color:var(--maroon);font:600 17px/1.3 'Playfair Display',Georgia,serif}
        .progress-wrap{margin-top:25px}.progress{display:grid;grid-template-columns:repeat(5,minmax(0,1fr));list-style:none;margin:0;padding:0}.progress-step{position:relative;min-width:0;text-align:center}.progress-step:not(:last-child)::after{position:absolute;top:13px;left:calc(50% + 16px);right:calc(-50% + 16px);height:2px;background:#ded8d5;content:''}.progress-step.is-complete:not(:last-child)::after{background:var(--rose)}.step-dot{position:relative;z-index:1;width:28px;height:28px;margin:0 auto 7px;display:grid;place-items:center;border:2px solid #d8d0cc;border-radius:50%;background:var(--white);color:#786e70;font-size:12px;font-weight:700}.is-complete .step-dot{border-color:var(--rose);background:var(--rose);color:#fff}.is-current .step-dot{border-color:var(--maroon);background:var(--maroon);color:#fff;box-shadow:0 0 0 5px rgba(74,18,51,.12)}.step-label{display:block;color:#55494c;font-size:11px;font-weight:600}.step-date{display:block;min-height:16px;margin-top:3px;color:var(--muted);font-size:10px}.cancelled-notice{margin:24px 0 0;padding:12px 15px;border:1px solid #efc4c6;border-radius:12px;background:#fff3f3;color:var(--red);font-weight:700}
        .content-grid{display:grid;grid-template-columns:minmax(0,1.35fr) minmax(300px,.85fr);align-items:start;gap:20px}.left-column,.right-column{display:grid;gap:18px;min-width:0}.panel{padding:22px 23px}.panel-title{margin:0 0 17px;color:var(--maroon);font:600 21px/1.25 'Playfair Display',Georgia,serif}.tracking-list{display:grid;list-style:none;margin:0;padding:0}.tracking-event{position:relative;display:grid;grid-template-columns:22px minmax(0,1fr);column-gap:13px;min-height:94px}.tracking-event:not(:last-child)::before{position:absolute;top:20px;bottom:-1px;left:9px;width:2px;background:#e7ddd7;content:''}.event-marker{position:relative;z-index:1;width:20px;height:20px;display:grid;place-items:center;border:1.5px solid #d8c1b5;border-radius:50%;background:var(--white);color:var(--rose);font-size:10px}.tracking-event.is-complete .event-marker{border-color:var(--rose);background:#f8e9e1;color:var(--maroon)}.tracking-event.is-latest .event-marker{border-color:var(--maroon);background:var(--maroon);color:#fff;box-shadow:0 0 0 5px rgba(74,18,51,.12)}.event-body{padding-bottom:19px}.event-heading{display:flex;align-items:center;flex-wrap:wrap;gap:8px}.event-title{margin:0;color:var(--maroon);font-size:13px;font-weight:700;line-height:1.45}.latest-chip{padding:2px 8px;border-radius:999px;background:#f1e7ed;color:var(--maroon);font-size:9px;font-weight:700}.event-note,.event-location,.event-courier{margin:4px 0 0;color:#53494b;font-size:11px;line-height:1.55}.event-time{margin:7px 0 0;color:var(--muted);font-size:10px}.expected-event{margin:2px 0 0 35px;padding:10px 12px;border:1px dashed #d6ccca;border-radius:12px;background:#faf8f6;color:#756c6d;font-size:11px}.empty-state{margin:0;color:#62575a;font-size:13px}
        .item-list{display:grid;gap:14px}.order-item{display:grid;grid-template-columns:58px minmax(0,1fr) auto;align-items:center;gap:11px}.product-image{width:58px;height:58px;display:grid;place-items:center;overflow:hidden;border-radius:12px;background:#f7f0eb;color:var(--muted);font-size:10px}.product-image img{width:100%;height:100%;object-fit:cover}.item-name{margin:0;color:var(--maroon);font-size:12px;font-weight:700}.item-meta{margin:3px 0 0;color:var(--muted);font-size:10px;line-height:1.5}.item-price{color:var(--maroon);font-size:12px;font-weight:700;white-space:nowrap}.summary-lines{display:grid;gap:9px;margin-top:17px;padding-top:14px;border-top:1px solid var(--line)}.summary-line{display:flex;justify-content:space-between;gap:14px;color:#55494c;font-size:11px}.summary-line strong{color:var(--maroon);font-weight:600;text-align:right}.payment-tag{display:inline-flex;padding:3px 9px;border-radius:999px;background:#f2ece8;color:var(--maroon);font-size:10px;font-weight:700}.summary-total{display:flex;justify-content:space-between;align-items:baseline;gap:12px;margin-top:13px;color:var(--maroon);font-size:13px;font-weight:700}.summary-total strong{font:700 22px/1.2 'Playfair Display',Georgia,serif}.cod-notice{margin:14px 0 0;padding:11px 12px;border-radius:12px;background:#fff5e3;color:#654b24;font-size:11px;line-height:1.5}
        .tracking-number{display:flex;align-items:center;justify-content:space-between;gap:12px}.tracking-code{overflow-wrap:anywhere;color:var(--maroon);font-weight:700;letter-spacing:.04em}.copy-button{flex:none;padding:7px 10px;border:1px solid var(--line);border-radius:999px;background:var(--white);color:var(--maroon);font-size:10px;font-weight:700;cursor:pointer}.copy-status{min-height:16px;margin:5px 0 0;color:var(--green);font-size:10px}.small-label{display:block;margin:12px 0 3px;color:var(--muted);font-size:10px;font-weight:700;letter-spacing:.06em;text-transform:uppercase}.address-copy{margin:0;color:#51474a;font-size:11px;line-height:1.7}.help-actions{display:grid;justify-items:center;gap:12px;max-width:360px;margin:0 auto}.help-actions form{width:100%}.help-button{width:100%;min-height:50px;display:flex;align-items:center;justify-content:center;padding:10px 16px;border:1px solid var(--maroon);border-radius:999px;color:var(--maroon);font-size:12px;font-weight:700}.help-button.primary{background:var(--maroon);color:#fff}.help-button:hover{background:#f8f2ef}.help-button.primary:hover{background:#641f47}.problem-link{justify-self:center;margin-top:4px;color:var(--maroon);font-size:11px;font-weight:600;text-decoration:underline;text-underline-offset:3px}.bottom-actions{display:flex;align-items:center;gap:18px;margin-top:21px}.outline-button{min-height:43px;display:inline-flex;align-items:center;justify-content:center;padding:8px 16px;border:1px solid var(--maroon);border-radius:999px;background:transparent;color:var(--maroon);font-size:11px;font-weight:700}.back-link{color:var(--maroon);font-size:11px;font-weight:600}.sr-only{position:absolute;width:1px;height:1px;padding:0;margin:-1px;overflow:hidden;clip:rect(0,0,0,0);white-space:nowrap;border:0}
        @media(max-width:1000px){.site-header-inner{gap:18px;padding-right:22px;padding-left:22px}.brand{width:180px;flex-basis:180px}.content-grid{grid-template-columns:minmax(0,1.15fr) minmax(280px,.85fr)}}
        @media(max-width:859px){.page{padding:22px 22px 44px}.heading-row{align-items:flex-start;flex-direction:column}.refresh-row{width:100%;justify-content:space-between}.content-grid{grid-template-columns:1fr}.right-column{grid-row:2}.step-date{visibility:hidden}.site-header-inner{min-height:70px}.brand{width:155px;flex-basis:155px}.brand-name{font-size:24px}.header-search{min-height:38px}}
        @media(max-width:600px){.site-header-inner{min-height:64px;padding:9px 15px;gap:12px}.brand{width:136px;flex-basis:136px}.brand-name{font-size:21px}.brand-tagline{font-size:7px;letter-spacing:.28em}.header-search{display:none}.header-actions{gap:5px}.header-action{width:38px;height:38px}.page{padding:18px 14px 36px}.breadcrumb{font-size:10px;gap:6px;margin-bottom:17px}.page-title{font-size:30px}.status-card,.panel{padding:18px 16px;border-radius:17px}.status-overview{flex-direction:column;gap:13px}.estimate-box{width:100%;min-width:0}.status-headline{font-size:20px}.progress-wrap{margin-top:21px}.progress-step:not(:last-child)::after{left:calc(50% + 13px);right:calc(-50% + 13px);top:11px}.step-dot{width:24px;height:24px;margin-bottom:6px;font-size:10px}.step-label{font-size:9px;line-height:1.3}.content-grid{gap:14px}.left-column,.right-column{gap:14px}.panel-title{font-size:19px}.order-item{grid-template-columns:50px minmax(0,1fr) auto;gap:9px}.product-image{width:50px;height:50px}.bottom-actions{gap:13px}.outline-button{padding:8px 12px;font-size:10px}}
        @media(prefers-reduced-motion:reduce){*{scroll-behavior:auto!important;transition:none!important}}
    </style>
</head>
<body>
    <header class="site-header">
        <div class="site-header-inner">
            <a href="{{ route('shop.index') }}" class="brand" aria-label="Lumora shop">
                <span class="brand-name">LUM<span>O</span>RA</span>
                <span class="brand-tagline">Beauty lives here</span>
            </a>
            <form action="{{ route('shop.index') }}" method="GET" class="header-search" role="search">
                <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" aria-hidden="true"><circle cx="11" cy="11" r="7"/><path d="m20 20-4-4"/></svg>
                <input type="search" name="search" placeholder="Search Lumora" aria-label="Search Lumora">
            </form>
            <nav class="header-actions" aria-label="Shop links">
                <a href="{{ route('profile.edit') }}#wishlist" class="header-action" aria-label="Wishlist">
                    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.7" aria-hidden="true"><path d="M20.8 4.6a5.5 5.5 0 0 0-7.8 0L12 5.6l-1-1a5.5 5.5 0 0 0-7.8 7.8l1 1L12 21l7.8-7.6 1-1a5.5 5.5 0 0 0 0-7.8Z"/></svg>
                </a>
                <a href="{{ route('buyer.cart') }}" class="header-action" aria-label="Cart">
                    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.7" aria-hidden="true"><circle cx="8" cy="21" r="1"/><circle cx="19" cy="21" r="1"/><path d="M2 3h3l2.6 12.4a2 2 0 0 0 2 1.6h8a2 2 0 0 0 2-1.6L21 7H6"/></svg>
                    @if ($cartCount > 0)<span class="cart-count">{{ $cartCount }}</span>@endif
                </a>
            </nav>
        </div>
    </header>

    <main class="page">
        <nav class="breadcrumb" aria-label="Breadcrumb">
            <a href="{{ route('buyer.orders.index') }}">My Orders</a><span aria-hidden="true">›</span>
            <a href="{{ route('buyer.orders.show', $order) }}">{{ $order->order_number ?: 'Order '.$order->id }}</a><span aria-hidden="true">›</span>
            <span aria-current="page">Track</span>
        </nav>

        <div class="heading-row">
            <div>
                <p class="eyebrow">ORDER TRACKING</p>
                <h1 class="page-title">Track your order</h1>
                <p class="order-ref">Order #{{ $order->order_number ?: $order->id }} � Placed {{ $order->created_at?->timezone('Asia/Manila')->format('M j, Y') ?? 'Date unavailable' }}</p>
            </div>
            <div class="refresh-row">
                <span>Last updated {{ $latestUpdate?->created_at?->timezone('Asia/Manila')->diffForHumans() ?? '—' }}</span>
                <div class="top-nav-links">
                    <a class="back-link top-back-link" href="{{ route('buyer.orders.index') }}">← Back to my orders</a>
                    <a class="outline-button top-details-button" href="{{ route('buyer.orders.show', $order) }}">View order details</a>
                </div>
                <button type="button" class="refresh-button" onclick="window.location.reload()" aria-label="Refresh tracking updates">↻ Refresh</button>
            </div>
        </div>

        <section class="card status-card" aria-labelledby="current-status-title">
            <div class="status-overview">
                <div class="status-copy">
                    <span class="status-badge status-{{ $statusTone }}">{{ $order->status_label }}</span>
                    <h2 class="status-headline" id="current-status-title">{{ $statusHeadline }}</h2>
                    <p class="status-explanation">{{ $statusExplanation }}</p>
                </div>
                @if ($isActive && $estimatedDelivery)
                    <div class="estimate-box" aria-label="Estimated delivery date">
                        <span class="estimate-label">Estimated delivery</span>
                        <strong class="estimate-date">{{ $estimatedDelivery->timezone('Asia/Manila')->format('M j, Y') }}</strong>
                    </div>
                @endif
            </div>

            @if ($isCancelled)
                <p class="cancelled-notice">{{ $currentStatus === 'returned' ? 'This order has been returned.' : 'This order was cancelled.' }}</p>
            @else
                <div class="progress-wrap">
                    <ol class="progress" aria-label="Order delivery progress">
                        @foreach ($steps as $index => $step)
                            @php
                                $stepState = $index < $progressRank ? 'is-complete' : ($index === $progressRank ? ($progressRank === 4 ? 'is-complete' : 'is-current') : '');
                                $stepEvent = $order->statusHistories->first(fn ($event) => in_array(strtolower((string) ($event->tracking_status ?: $event->status)), $step['statuses'], true));
                            @endphp
                            <li class="progress-step {{ $stepState }}" @if($index === $progressRank) aria-current="step" @endif>
                                <span class="step-dot" aria-hidden="true">{{ $index < $progressRank || ($progressRank === 4 && $index === 4) ? '?' : $index + 1 }}</span>
                                <span class="step-label">{{ $step['label'] }}</span>
                                <span class="step-date">{{ $stepEvent ? $stepEvent->created_at?->timezone('Asia/Manila')->format('M j') : '' }}</span>
                            </li>
                        @endforeach
                    </ol>
                </div>
            @endif
        </section>

        <div class="content-grid">
            <div class="left-column">
                <section class="card panel" aria-labelledby="timeline-title">
                    <h2 class="panel-title" id="timeline-title">Delivery updates</h2>
                    @if ($order->statusHistories->isNotEmpty())
                        <ol class="tracking-list" aria-label="Order status history">
                            @foreach ($order->statusHistories as $event)
                                @php
                                    $eventStatus = strtolower((string) ($event->tracking_status ?: $event->status));
                                    $eventLabel = $event->tracking_label ?: match ($eventStatus) {
                                        'pending', 'created' => 'Order placed',
                                        'received' => 'Received by Lumora Logistics',
                                        'scanned' => 'Scanned at logistics hub',
                                        'sorted' => 'Sorted at logistics hub',
                                        'assigned' => 'Assigned to courier',
                                        'rider_received' => 'Received by courier',
                                        'in_transit' => 'In Transit',
                                        'out_for_delivery' => 'Out for delivery',
                                        'delivered', 'completed' => 'Delivered',
                                        'cancelled' => 'Order cancelled',
                                        'returned' => 'Order returned',
                                        'failed', 'exception' => 'Delivery exception',
                                        default => \Illuminate\Support\Str::headline($eventStatus),
                                    };
                                @endphp
                                <li class="tracking-event {{ $loop->first ? 'is-latest' : 'is-complete' }}">
                                    <span class="event-marker" aria-hidden="true">{{ $loop->first ? '?' : '�' }}</span>
                                    <div class="event-body">
                                        <div class="event-heading"><h3 class="event-title">{{ $eventLabel }}</h3>@if($loop->first)<span class="latest-chip">Latest update</span>@endif</div>
                                        @if ($event->note)<p class="event-note">{{ $event->note }}</p>@endif
                                        @if ($event->location)<p class="event-location">{{ $event->location }}</p>@endif
                                        @if ($event->courier_name)<p class="event-courier">Courier {{ $event->courier_name }}</p>@endif
                                        <p class="event-time">{{ $event->created_at?->timezone('Asia/Manila')->format('M j, Y � g:i A') ?? 'Time unavailable' }} PHT</p>
                                    </div>
                                </li>
                            @endforeach
                        </ol>
                    @else
                        <p class="empty-state">No tracking updates yet. We'll notify you when your order is packed.</p>
                    @endif

                    @if ($isActive && $estimatedDelivery && $progressRank < 4)
                        @php
                            $expectedDate = $estimatedDelivery->timezone('Asia/Manila');
                        @endphp
                        <p class="expected-event">Next expected step: {{ $expectedDate->isToday() ? 'Expected today' : 'Expected '.$expectedDate->format('M j') }} � {{ $steps[min($progressRank + 1, 4)]['label'] }}</p>
                    @endif
                </section>
            </div>

            <aside class="right-column" aria-label="Order and delivery information">
                <section class="card panel" aria-labelledby="summary-title">
                    <h2 class="panel-title" id="summary-title">Order summary</h2>
                    <div class="item-list">
                        @foreach ($order->items as $item)
                            @php
                                $product = $item->product;
                                $imageUrl = $product && filled($product->image) ? \App\Models\Product::resolveImageUrl($product->image) : null;
                            @endphp
                            <article class="order-item">
                                <div class="product-image">
                                    @if ($imageUrl)<img src="{{ $imageUrl }}" alt="{{ $product->name }}" loading="lazy">@else<span>Image</span>@endif
                                </div>
                                <div>
                                    <h3 class="item-name">{{ $product?->name ?? 'Product details unavailable' }}</h3>
                                    <p class="item-meta">
                                        @if (filled($product?->variant_type)){{ \Illuminate\Support\Str::headline($product->variant_type) }} � @endif
                                        Qty {{ $item->quantity }} � {{ $item->seller?->name ?? $order->seller?->name ?? 'Lumora seller' }}
                                    </p>
                                </div>
                                <span class="item-price">₱{{ number_format((float) $item->subtotal, 2) }}</span>
                            </article>
                        @endforeach
                    </div>
                    <div class="summary-lines">
                        <div class="summary-line"><span>Subtotal</span><strong>₱{{ number_format((float) $order->subtotal, 2) }}</strong></div>
                        <div class="summary-line"><span>Shipping</span><strong>₱{{ number_format((float) $order->shipping_fee, 2) }}</strong></div>
                        @if ((float) $order->discount > 0)<div class="summary-line"><span>Discount</span><strong>−₱{{ number_format((float) $order->discount, 2) }}</strong></div>@endif
                        <div class="summary-line"><span>Payment</span><strong><span class="payment-tag">{{ $paymentLabel }}</span></strong></div>
                    </div>
                    <div class="summary-total"><span>Total</span><strong>₱{{ number_format((float) $order->total, 2) }}</strong></div>
                    @if (strtolower((string) $order->payment_method) === 'cod' && ! $isDelivered && ! $isCancelled)
                        <p class="cod-notice">Please prepare ₱{{ number_format((float) $order->total, 2) }} in cash. You pay upon delivery.</p>
                    @endif
                </section>

                @if ($order->tracking_number || $order->courier)
                    <section class="card panel" aria-labelledby="tracking-number-title">
                        <h2 class="panel-title" id="tracking-number-title">Shipment details</h2>
                        @if ($order->tracking_number)
                            <span class="small-label">Tracking number</span>
                            <div class="tracking-number"><strong class="tracking-code" id="tracking-code">{{ $order->tracking_number }}</strong><button type="button" class="copy-button" data-copy-tracking>Copy</button></div>
                            <p class="copy-status" id="copy-status" role="status" aria-live="polite"></p>
                        @endif
                        @if ($order->courier)<span class="small-label">Courier</span><p class="address-copy">{{ $order->courier }}</p>@endif
                    </section>
                @endif

                <section class="card panel" aria-labelledby="address-title">
                    <h2 class="panel-title" id="address-title">Delivery address</h2>
                    @if ($buyer?->name)<p class="address-copy"><strong>{{ $buyer->name }}</strong></p>@endif
                    @if ($maskedPhone)<p class="address-copy">{{ $maskedPhone }}</p>@endif
                    @forelse ($addressLines as $line)<p class="address-copy">{{ $line }}</p>@empty<p class="address-copy">Delivery address unavailable.</p>@endforelse
                </section>

                <section class="card panel" aria-labelledby="help-title">
                    <h2 class="panel-title" id="help-title">Need help?</h2>
                    <div class="help-actions">
                        @if ($order->seller)
                            <form method="POST" action="{{ route('buyer.chats.start-seller', $order->seller) }}">@csrf<button class="help-button primary" type="submit">Chat with seller</button></form>
                        @endif
                        <a class="help-button" href="{{ route('help.center', 'contact') }}">Contact support</a>
                        @if ($returnCanBeRequested)
                            <a class="problem-link" href="{{ route('buyer.orders.show', $order) }}#return-request">Report a problem with this order</a>
                        @endif
                    </div>
                </section>
            </aside>
        </div>

    </main>
    <script>
        document.querySelector('[data-copy-tracking]')?.addEventListener('click', async () => {
            const code = document.getElementById('tracking-code')?.textContent?.trim();
            const status = document.getElementById('copy-status');
            if (!code || !status) return;
            try {
                await navigator.clipboard.writeText(code);
                status.textContent = 'Tracking number copied.';
            } catch (_) {
                status.textContent = 'Copy is unavailable in this browser.';
            }
        });
    </script>
</body>
</html>
