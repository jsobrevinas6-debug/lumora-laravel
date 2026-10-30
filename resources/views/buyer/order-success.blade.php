@php
    $buyer = $order->user;
    $addressLines = collect([
        trim(implode(' ', array_filter([$buyer?->house_number, $buyer?->street]))),
        $buyer?->barangay,
        trim(implode(', ', array_filter([$buyer?->municipality, $buyer?->province]))),
        $buyer?->postal_code,
    ])->filter(fn ($line) => filled($line))->values();

    $paymentLabel = match (strtolower((string) $order->payment_method)) {
        'cod' => 'Cash on Delivery',
        'gcash' => 'GCash',
        'maya', 'paymaya' => 'Maya',
        'bank_transfer' => 'Bank transfer',
        default => filled($order->payment_method) ? \Illuminate\Support\Str::headline($order->payment_method) : null,
    };

    $progressSteps = ['Order placed', 'Processing', 'Shipped', 'Delivered'];
    $progressIndex = match ($order->status) {
        'processing', 'packed' => 1,
        'shipped', 'out_for_delivery' => 2,
        'delivered', 'returned' => 3,
        default => 0,
    };
    $isCancelled = in_array($order->status, ['cancelled', 'returned'], true);
    $itemCount = $order->items->sum('quantity');
    $paymentDue = $order->payment_status === 'pending' ? (float) $order->total : 0;
@endphp
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <meta name="csrf-token" content="{{ csrf_token() }}">
    <title>Lumora | Order #{{ $order->id }}</title>
    @vite(['resources/css/app.css', 'resources/js/app.js'])
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Fraunces:opsz,wght@9..144,500;9..144,600;9..144,700&family=Inter:wght@400;500;600;700&display=swap" rel="stylesheet">
    <style>
        :root {
            --background: #F7F1EC;
            --card: #FFFDFC;
            --primary: #3B1E34;
            --accent: #C98F72;
            --border: #EAE3DD;
            --text: #2F2528;
            --muted: #6E5E61;
            --success: #6F8F78;
            --hover: #F8F4F1;
            --active: #F5ECE6;
            --page-bg: var(--background);
            --accent-strong: var(--primary);
            --accent-hover: #29152A;
            --pink: var(--active);
            --pink-deep: var(--border);
            --ink: var(--text);
            --body: #4A3A3D;
            --pending-bg: #FFF1D6;
            --pending-text: #7A4F00;
            --pending-dot: #C98A12;
            --success-bg: rgba(111, 143, 120, .14);
            --success-icon: #416A54;
            --help-bg: var(--active);
            --shadow: 0 10px 30px rgba(74, 42, 46, .045);
        }
        * { box-sizing: border-box; }
        html { scroll-behavior: smooth; }
        body { margin: 0; background: var(--page-bg); color: var(--ink); font-family: Inter, system-ui, sans-serif; font-size: 15px; line-height: 1.55; }
        a { color: inherit; text-decoration: none; }
        a:focus-visible { outline: 2px solid var(--accent-strong); outline-offset: 3px; }
        button:focus-visible { outline: 2px solid var(--accent-strong); outline-offset: 3px; }
        .site-header { min-height: 76px; display: flex; align-items: center; justify-content: space-between; gap: 24px; padding: 12px max(24px, calc((100% - 1180px) / 2)); background: var(--card); border-bottom: 1px solid var(--border); }
        .wordmark { color: var(--accent-strong); font: 600 28px/1 Fraunces, Georgia, serif; letter-spacing: .19em; }
        .header-nav { display: flex; align-items: center; gap: 8px; }
        .header-nav a { min-height: 44px; display: inline-flex; align-items: center; padding: 0 15px; border-radius: 999px; color: var(--body); font-size: 14px; font-weight: 600; }
        .header-nav a:hover { color: var(--accent-strong); background: var(--hover); }
        .header-nav a.active { color: var(--accent-strong); background: var(--pink); }
        .page { width: min(1120px, calc(100% - 48px)); margin: 0 auto; padding: 52px 0 34px; }
        .hero { display: grid; justify-items: center; text-align: center; margin-bottom: 32px; }
        .success-icon { width: 58px; height: 58px; display: grid; place-items: center; margin-bottom: 15px; border-radius: 50%; background: var(--success-bg); color: var(--success-icon); }
        .success-icon svg { width: 27px; height: 27px; }
        h1, h2, h3 { font-family: Fraunces, Georgia, serif; }
        .hero h1 { margin: 0; color: var(--ink); font-size: clamp(32px, 5vw, 44px); font-weight: 600; line-height: 1.16; }
        .hero-copy { max-width: 560px; margin: 11px 0 18px; color: var(--muted); font-size: 15px; }
        .order-pills { display: flex; align-items: center; justify-content: center; flex-wrap: wrap; gap: 9px; }
        .pill { min-height: 36px; display: inline-flex; align-items: center; gap: 7px; padding: 5px 13px; border: 1px solid var(--border); border-radius: 999px; background: var(--card); color: var(--body); font-size: 12px; font-weight: 600; }
        .pill-order { color: var(--accent-strong); }
        .status-dot { width: 7px; height: 7px; border-radius: 50%; background: currentColor; }
        .status-pending { border-color: #F0D9A9; background: var(--pending-bg); color: var(--pending-text); }
        .status-pending .status-dot { background: var(--pending-dot); }
        .status-paid, .status-delivered { border-color: rgba(111,143,120,.4); background: var(--success-bg); color: #355B46; }
        .status-cancelled, .status-failed, .status-refunded, .status-returned { background: #F2E8E7; color: #6B3C43; }
        .card { border: 1px solid var(--border); border-radius: 16px; background: var(--card); box-shadow: var(--shadow); }
        .progress-card { margin-bottom: 22px; padding: 24px 28px 21px; }
        .progress-card h2 { margin: 0 0 19px; color: var(--ink); font-size: 20px; font-weight: 600; }
        .progress-steps { display: grid; grid-template-columns: repeat(4, minmax(0, 1fr)); gap: 12px; }
        .progress-step { min-width: 0; }
        .step-bar { height: 6px; margin-bottom: 10px; border-radius: 999px; background: var(--border); }
        .progress-step.complete .step-bar { background: var(--ink); }
        .progress-step.current .step-bar { background: var(--pink-deep); }
        .step-label { display: block; color: var(--ink); font-size: 13px; font-weight: 700; }
        .step-caption { display: block; margin-top: 2px; color: var(--muted); font-size: 11px; }
        .step-marker { display: none; }
        .progress-note { margin: 15px 0 0; color: var(--muted); font-size: 12px; }
        .content-grid { display: grid; grid-template-columns: minmax(0, 1fr) 340px; align-items: start; gap: 22px; }
        .main-column, .side-column { display: grid; gap: 18px; min-width: 0; }
        .items-card, .details-card, .summary-card { padding: 23px; }
        .card-heading { display: flex; align-items: center; justify-content: space-between; gap: 12px; margin: 0 0 17px; color: var(--ink); font-size: 21px; font-weight: 600; }
        .item-count { padding: 5px 10px; border-radius: 999px; background: #F8E9E5; color: var(--accent); font: 600 12px Inter, sans-serif; white-space: nowrap; }
        .item-list { display: grid; }
        .order-item { display: grid; grid-template-columns: 82px minmax(0, 1fr) auto; align-items: center; gap: 15px; padding: 15px 0; border-top: 1px solid #F0E4E0; }
        .order-item:first-child { padding-top: 0; border-top: 0; }
        .product-thumb { width: 82px; height: 82px; overflow: hidden; display: grid; place-items: center; border-radius: 12px; background: var(--pink); }
        .product-thumb img { width: 100%; height: 100%; object-fit: cover; }
        .product-thumb svg { width: 32px; height: 32px; color: var(--accent-strong); }
        .item-name { margin: 0; color: var(--ink); font-size: 14px; font-weight: 700; line-height: 1.4; }
        .item-meta { display: flex; flex-wrap: wrap; gap: 4px 12px; margin-top: 5px; color: var(--muted); font-size: 12px; }
        .line-total { color: var(--ink); font-size: 14px; font-weight: 700; white-space: nowrap; }
        .detail-grid { display: grid; grid-template-columns: repeat(2, minmax(0, 1fr)); gap: 18px; }
        .detail-block + .detail-block { border-left: 1px solid var(--border); padding-left: 18px; }
        .detail-block h3 { margin: 0 0 9px; color: var(--ink); font-size: 17px; font-weight: 600; }
        .detail-block p { margin: 0; color: var(--body); font-size: 13px; line-height: 1.7; overflow-wrap: anywhere; }
        .detail-block .detail-label { display: block; margin-top: 9px; color: var(--muted); font-size: 11px; font-weight: 600; }
        .summary-card { position: sticky; top: 20px; }
        .summary-lines { display: grid; gap: 12px; padding-bottom: 16px; border-bottom: 1px solid var(--border); }
        .summary-line { display: flex; justify-content: space-between; gap: 16px; color: var(--body); font-size: 13px; }
        .summary-line strong { color: var(--ink); font-weight: 600; }
        .summary-total { display: flex; justify-content: space-between; align-items: baseline; gap: 12px; padding: 18px 0 16px; color: var(--ink); font-size: 14px; font-weight: 700; }
        .summary-total strong { color: var(--accent-strong); font: 700 27px/1.1 Fraunces, Georgia, serif; white-space: nowrap; }
        .action-links { display: grid; gap: 10px; }
        .action-button { min-height: 48px; display: inline-flex; align-items: center; justify-content: center; gap: 9px; padding: 10px 16px; border: 1px solid var(--accent); border-radius: 9px; color: var(--accent-strong); font-size: 13px; font-weight: 700; text-align: center; transition: background .15s ease, color .15s ease; }
        .action-button.primary { border-color: var(--primary); background: var(--primary); color: #fff; }
        .action-button.primary:hover { border-color: var(--accent-hover); background: var(--accent-hover); }
        .action-button.secondary:hover { background: var(--hover); }
        .help-card { padding: 19px 21px; border-radius: 16px; background: var(--help-bg); }
        .help-card h2 { margin: 0 0 6px; color: var(--ink); font-size: 18px; font-weight: 600; }
        .help-card p { margin: 0 0 12px; color: var(--body); font-size: 12px; }
        .help-link { min-height: 44px; display: inline-flex; align-items: center; gap: 7px; color: var(--accent-strong); font-size: 13px; font-weight: 700; }
        .help-link:hover { color: var(--accent-hover); text-decoration: underline; text-underline-offset: 3px; }
        .site-footer { padding: 22px 16px 30px; color: var(--muted); font-size: 12px; text-align: center; }
        @media (max-width: 760px) {
            .site-header { min-height: 68px; padding: 10px 18px; gap: 10px; }
            .wordmark { font-size: 23px; letter-spacing: .13em; }
            .header-nav { gap: 0; }
            .header-nav a { min-height: 44px; padding: 0 9px; font-size: 12px; }
            .page { width: min(100% - 32px, 560px); padding-top: 34px; }
            .hero { margin-bottom: 25px; }
            .hero-copy { max-width: 390px; font-size: 14px; }
            .content-grid { grid-template-columns: 1fr; }
            .side-column { grid-row: 1; }
            .summary-card { position: static; }
        }
        @media (max-width: 520px) {
            .site-header { align-items: flex-start; flex-direction: column; padding: 14px 16px 10px; gap: 6px; }
            .header-nav { width: 100%; justify-content: space-between; }
            .header-nav a { padding: 0 11px; }
            .page { width: calc(100% - 28px); padding-top: 30px; }
            .success-icon { width: 52px; height: 52px; margin-bottom: 13px; }
            .hero h1 { max-width: 350px; font-size: 34px; }
            .order-pills { gap: 7px; }
            .pill { min-height: 34px; padding: 4px 10px; font-size: 11px; }
            .progress-card { padding: 20px 18px; }
            .progress-card h2 { margin-bottom: 15px; }
            .progress-steps { display: grid; grid-template-columns: 1fr; gap: 0; }
            .progress-step { position: relative; display: grid; grid-template-columns: 18px minmax(0, 1fr); column-gap: 12px; min-height: 56px; }
            .progress-step:not(:last-child)::before { position: absolute; top: 15px; bottom: -1px; left: 7px; width: 3px; border-radius: 3px; background: var(--border); content: ''; }
            .progress-step.complete:not(:last-child)::before { background: var(--ink); }
            .step-bar { display: none; }
            .step-marker { position: relative; z-index: 1; width: 16px; height: 16px; display: block; margin-top: 2px; border: 2px solid var(--border); border-radius: 50%; background: var(--card); }
            .progress-step.complete .step-marker { border-color: var(--ink); background: var(--ink); }
            .progress-step.current .step-marker { border-color: var(--pink-deep); background: var(--pink); box-shadow: 0 0 0 3px rgba(230,180,186,.2); }
            .step-label { grid-column: 2; grid-row: 1; font-size: 13px; }
            .step-caption { grid-column: 2; grid-row: 2; margin: 1px 0 13px; }
            .items-card, .details-card, .summary-card { padding: 19px 17px; }
            .card-heading { font-size: 20px; }
            .order-item { grid-template-columns: 66px minmax(0, 1fr); gap: 11px; }
            .product-thumb { width: 66px; height: 66px; }
            .line-total { grid-column: 2; margin-top: -7px; font-size: 13px; }
            .detail-grid { grid-template-columns: 1fr; gap: 17px; }
            .detail-block + .detail-block { border-top: 1px solid var(--border); border-left: 0; padding: 15px 0 0; }
            .action-button { width: 100%; }
        }
        @media (prefers-reduced-motion: reduce) { html { scroll-behavior: auto; } *, *::before, *::after { transition-duration: .01ms !important; } }
    </style>
</head>
<body>
    <header class="site-header">
        <a class="wordmark" href="{{ route('shop.index') }}" aria-label="Lumora home">LUMORA</a>
        <nav class="header-nav" aria-label="Main navigation">
            <a href="{{ route('shop.index') }}">Shop</a>
            <a class="active" href="{{ route('buyer.orders.index') }}" aria-current="page">My orders</a>
            <a href="{{ route('buyer.cart') }}">Cart</a>
        </nav>
    </header>

    <main class="page">
        <section class="hero" aria-labelledby="page-title">
            <span class="success-icon" aria-hidden="true">
                <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round"><path d="m5 12 4 4L19 6"/></svg>
            </span>
            <h1 id="page-title">Thank you for your order</h1>
            <p class="hero-copy">Your order has been received. You can follow its progress here, and we’ll keep you posted as it moves along.</p>
            <div class="order-pills">
                <span class="pill pill-order">Order #{{ $order->id }}</span>
                <span class="pill status-{{ Illuminate\Support\Str::slug($order->status) }}"><span class="status-dot" aria-hidden="true"></span>{{ $order->status_label }}</span>
                <span class="pill">Placed {{ $order->created_at?->format('M j, Y') ?? 'Date unavailable' }}</span>
            </div>
        </section>

        <section class="card progress-card" id="order-progress" aria-labelledby="progress-heading">
            <h2 id="progress-heading">Order progress</h2>
            <div class="progress-steps" role="list" aria-label="Order status steps">
                @foreach ($progressSteps as $index => $step)
                    @php
                        $stepState = $isCancelled
                            ? ($index === 0 ? 'complete' : '')
                            : (($index === 0 || $order->status === 'delivered' || $index < $progressIndex)
                                ? 'complete'
                                : ($progressIndex > 0 && $index === $progressIndex ? 'current' : ''));
                        $caption = $isCancelled
                            ? ($index === 0 ? 'Completed' : 'Not applicable')
                            : ($stepState === 'complete' ? 'Completed' : ($stepState === 'current' ? 'In progress' : 'Up next'));
                    @endphp
                    <div class="progress-step {{ $stepState }}" role="listitem" @if($stepState === 'current') aria-current="step" @endif>
                        <div class="step-bar" aria-hidden="true"></div>
                        <span class="step-marker" aria-hidden="true"></span>
                        <span class="step-label">{{ $step }}</span>
                        <span class="step-caption">{{ $caption }}</span>
                    </div>
                @endforeach
            </div>
            @if ($isCancelled)
                <p class="progress-note">This order is {{ strtolower($order->status_label) }}.</p>
            @elseif ($order->tracking_number || $order->courier)
                <p class="progress-note">
                    @if ($order->courier) {{ $order->courier }} @endif
                    @if ($order->tracking_number) · Tracking number {{ $order->tracking_number }} @endif
                    @if ($order->estimated_delivery) · Estimated delivery {{ $order->estimated_delivery->format('M j, Y') }} @endif
                </p>
            @endif
        </section>

        <div class="content-grid">
            <div class="main-column">
                <section class="card items-card" aria-labelledby="items-heading">
                    <h2 class="card-heading" id="items-heading">Items in your order <span class="item-count">{{ $itemCount }} {{ \Illuminate\Support\Str::plural('item', $itemCount) }}</span></h2>
                    <div class="item-list">
                        @forelse ($order->items as $item)
                            @php
                                $product = $item->product;
                                $imageUrl = $product && filled($product->image) ? \App\Models\Product::resolveImageUrl($product->image) : null;
                                $variant = $product?->variant_type;
                            @endphp
                            <article class="order-item">
                                <div class="product-thumb">
                                    @if ($imageUrl)
                                        <img src="{{ $imageUrl }}" alt="{{ $product->name }}" loading="lazy">
                                    @else
                                        <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5" aria-hidden="true"><path d="M4 7.5 12 3l8 4.5v9L12 21l-8-4.5z"/><path d="m4.5 7.7 7.5 4.2 7.5-4.2M12 12v8.5"/></svg>
                                    @endif
                                </div>
                                <div>
                                    <h3 class="item-name">{{ $product?->name ?? 'Product details unavailable' }}</h3>
                                    <div class="item-meta">
                                        @if (filled($variant)) <span>Variant: {{ \Illuminate\Support\Str::headline($variant) }}</span> @endif
                                        <span>Qty {{ $item->quantity }}</span>
                                    </div>
                                </div>
                                <span class="line-total">₱{{ number_format((float) $item->subtotal, 2) }}</span>
                            </article>
                        @empty
                            <p class="progress-note">Item details are unavailable for this order.</p>
                        @endforelse
                    </div>
                </section>

                @php
                    $hasAddress = $buyer && ($addressLines->isNotEmpty() || filled($buyer->name) || filled($buyer->contact_number));
                    $hasPayment = filled($paymentLabel) || filled($order->payment_status);
                @endphp
                @if ($hasAddress || $hasPayment)
                    <section class="card details-card" aria-label="Delivery and payment details">
                        <div class="detail-grid">
                            @if ($hasAddress)
                                <div class="detail-block">
                                    <h3>Delivery address</h3>
                                    @if (filled($buyer->name)) <p><strong>{{ $buyer->name }}</strong></p> @endif
                                    @foreach ($addressLines as $line) <p>{{ $line }}</p> @endforeach
                                    @if (filled($buyer->contact_number)) <p>{{ $buyer->contact_number }}</p> @endif
                                </div>
                            @endif
                            @if ($hasPayment)
                                <div class="detail-block">
                                    <h3>Payment</h3>
                                    @if ($paymentLabel) <p>{{ $paymentLabel }}</p> @endif
                                    @if ($order->payment_status)
                                        <span class="detail-label">Payment status</span>
                                        <p>{{ \Illuminate\Support\Str::headline($order->payment_status) }}</p>
                                    @endif
                                    <span class="detail-label">Amount due</span>
                                    <p><strong>₱{{ number_format($paymentDue, 2) }}</strong></p>
                                </div>
                            @endif
                        </div>
                    </section>
                @endif
            </div>

            <aside class="side-column" aria-label="Order actions and summary">
                <section class="card summary-card" aria-labelledby="summary-heading">
                    <h2 class="card-heading" id="summary-heading">Order summary</h2>
                    <div class="summary-lines">
                        <div class="summary-line"><span>Subtotal</span><strong>₱{{ number_format((float) $order->subtotal, 2) }}</strong></div>
                        <div class="summary-line"><span>Shipping</span><strong>₱{{ number_format((float) $order->shipping_fee, 2) }}</strong></div>
                        @if ((float) $order->discount > 0)
                            <div class="summary-line"><span>Discount</span><strong>−₱{{ number_format((float) $order->discount, 2) }}</strong></div>
                        @endif
                    </div>
                    <div class="summary-total"><span>Total</span><strong>₱{{ number_format((float) $order->total, 2) }}</strong></div>
                    <div class="action-links">
                        <a class="action-button primary" href="#order-progress">
                            <svg aria-hidden="true" viewBox="0 0 24 24" width="17" height="17" fill="none" stroke="currentColor" stroke-width="1.8"><path d="M3 12h17M13 5l7 7-7 7"/></svg>
                            Track order
                        </a>
                        <a class="action-button secondary" href="{{ route('shop.index') }}">Continue shopping</a>
                    </div>
                </section>

                <section class="help-card" aria-labelledby="help-heading">
                    <h2 id="help-heading">Need to change something?</h2>
                    <p>Message our team if you need help with this order.</p>
                    <a class="help-link" href="{{ route('buyer.chats.index') }}">
                        Contact support
                        <svg aria-hidden="true" viewBox="0 0 24 24" width="16" height="16" fill="none" stroke="currentColor" stroke-width="1.8"><path d="M5 12h14M13 6l6 6-6 6"/></svg>
                    </a>
                </section>
            </aside>
        </div>
    </main>

    <footer class="site-footer">Lumora · lumora.party</footer>
</body>
</html>
