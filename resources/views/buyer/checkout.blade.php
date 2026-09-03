<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <meta name="csrf-token" content="{{ csrf_token() }}">
    <title>Lumora | Checkout</title>
    @vite(['resources/css/app.css', 'resources/js/app.js'])
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&family=Playfair+Display:wght@500;600;700&display=swap" rel="stylesheet">
    <style>
        :root {
            --plum: #3d1b3d;
            --plum-dark: #2c102c;
            --rose: #b96562;
            --rose-soft: #d99a96;
            --gold: #c9972b;
            --cream: #fffdfb;
            --blush: #fbefea;
            --blush-deep: #f3d8de;
            --ink: #3a2e30;
            --muted: #8a7b7e;
            --line: #ebddd8;
        }

        * { box-sizing: border-box; }
        html, body { min-height: 100%; }
        body {
            margin: 0;
            color: var(--ink);
            font-family: Inter, Arial, sans-serif;
            background: linear-gradient(135deg, #fffdfb 0%, #fbefea 44%, #f3d8de 100%);
        }
        a { color: inherit; text-decoration: none; }
        h1, h2, h3 { margin: 0; color: var(--plum); font-family: 'Playfair Display', Georgia, serif; font-weight: 600; }

        .checkout-header {
            height: 106px;
            background: rgba(255, 253, 251, .96);
            border-bottom: 1px solid var(--line);
        }
        .header-inner {
            width: min(1380px, calc(100% - 96px));
            height: 100%;
            margin: 0 auto;
            display: flex;
            align-items: center;
            justify-content: space-between;
        }
        .brand {
            color: var(--plum);
            font: 700 31px/1 'Playfair Display', Georgia, serif;
            letter-spacing: 3px;
        }
        .brand span { color: var(--rose); }
        .steps {
            display: flex;
            align-items: center;
            gap: 23px;
            color: var(--muted);
            font-size: 15px;
        }
        .step { display: flex; align-items: center; gap: 18px; white-space: nowrap; }
        .step.active { color: var(--plum); font-weight: 600; }
        .step.active::after {
            content: '';
            position: absolute;
            margin-top: 55px;
            margin-left: 10px;
            width: 58px;
            height: 2px;
            background: var(--gold);
        }
        .chevron { color: #b9a7a7; font-size: 25px; font-weight: 300; }
        .secure { display: flex; align-items: center; gap: 10px; color: var(--ink); font-size: 14px; }
        .lock { display: inline-flex; color: var(--gold); }

        .page {
            width: min(1380px, calc(100% - 96px));
            margin: 0 auto;
            padding: 54px 0 100px;
        }
        .page-title { margin-bottom: 29px; font-size: 47px; line-height: 1; }
        .layout {
            display: grid;
            grid-template-columns: minmax(0, 1.55fr) minmax(360px, .85fr);
            gap: 62px;
            align-items: start;
        }
        .left-column { min-width: 0; }
        .card {
            background: rgba(255, 253, 251, .91);
            border: 1px solid var(--line);
            border-radius: 13px;
            box-shadow: 0 8px 30px rgba(61, 27, 61, .035);
        }
        .delivery-card { padding: 29px 34px 27px; }
        .card-title { font-size: 29px; line-height: 1; margin-bottom: 25px; }
        .address-row { display: flex; align-items: center; gap: 31px; }
        .pin {
            width: 90px;
            height: 90px;
            flex: 0 0 90px;
            display: grid;
            place-items: center;
            color: var(--rose);
            background: #fcedeb;
            border-radius: 50%;
            font-size: 38px;
        }
        .address-copy {
            min-height: 90px;
            padding-left: 31px;
            border-left: 1px solid var(--line);
            font-size: 15px;
            line-height: 1.52;
        }
        .address-name { margin-bottom: 4px; color: var(--ink); font-weight: 600; font-size: 16px; }
        .contact { margin-top: 6px; color: var(--rose); }
        .items-card { margin-top: 16px; padding: 27px 34px 17px; }
        .items-card .card-title { margin-bottom: 14px; }
        .item {
            min-height: 113px;
            display: flex;
            align-items: center;
            gap: 29px;
            border-top: 1px solid var(--line);
        }
        .item-image {
            width: 160px;
            height: 96px;
            flex: 0 0 160px;
            border-radius: 8px;
            object-fit: cover;
            background: #f2e8e3;
        }
        .item-details { flex: 1; min-width: 0; }
        .item-name { color: var(--ink); font: 600 17px/1.2 Inter, Arial, sans-serif; }
        .item-meta { margin-top: 8px; color: var(--muted); font-size: 14px; }
        .item-qty { width: 75px; color: var(--ink); font-size: 14px; white-space: nowrap; }
        .item-price { width: 117px; color: var(--plum); font-size: 16px; font-weight: 600; text-align: right; white-space: nowrap; }
        .return-link { display: inline-flex; gap: 11px; margin-top: 24px; color: var(--rose); font-size: 14px; text-decoration: underline; text-underline-offset: 3px; }

        .summary-card {
            position: sticky;
            top: 25px;
            min-height: 610px;
            padding: 34px 42px 31px;
            overflow: hidden;
        }
        .summary-card::after {
            content: '';
            position: absolute;
            width: 250px;
            height: 180px;
            right: -88px;
            bottom: -55px;
            border: 1px solid rgba(201, 151, 43, .45);
            border-radius: 50% 40% 0 50%;
            transform: rotate(-24deg);
            opacity: .45;
        }
        .summary-title { padding-bottom: 23px; border-bottom: 1px solid #d8c9bd; font-size: 30px; }
        .summary-title::after { content: '✦'; float: right; color: var(--gold); font: 20px Georgia, serif; }
        .summary-row { display: flex; justify-content: space-between; gap: 20px; margin-top: 23px; color: var(--ink); font-size: 15px; }
        .summary-row strong { font-weight: 500; }
        .summary-row.discount strong { color: var(--rose); }
        .summary-total { display: flex; justify-content: space-between; margin-top: 26px; padding-top: 29px; border-top: 1px solid #d8c9bd; color: var(--plum); font: 600 29px 'Playfair Display', Georgia, serif; }
        .payment-label { display: block; margin-top: 39px; margin-bottom: 14px; color: var(--plum); font: 600 21px 'Playfair Display', Georgia, serif; }
        .payment-option {
            display: flex;
            align-items: center;
            gap: 15px;
            min-height: 61px;
            padding: 0 17px;
            border: 1px solid var(--rose-soft);
            border-radius: 8px;
            color: var(--ink);
            font-size: 15px;
        }
        .payment-option input { width: 21px; height: 21px; accent-color: var(--plum); }
        .place-order {
            width: 100%;
            height: 69px;
            margin-top: 31px;
            border: 0;
            border-radius: 8px;
            background: var(--plum);
            color: white;
            font: 500 20px 'Playfair Display', Georgia, serif;
            cursor: pointer;
            transition: background .2s ease, transform .2s ease;
        }
        .place-order:hover { background: var(--plum-dark); transform: translateY(-1px); }
        .error { margin-bottom: 18px; padding: 12px 15px; border-radius: 8px; color: var(--rose); background: #fff3e9; font-size: 13px; }

        @media (max-width: 1050px) {
            .header-inner, .page { width: min(100% - 44px, 850px); }
            .steps { display: none; }
            .layout { grid-template-columns: 1fr; gap: 24px; }
            .summary-card { position: static; min-height: auto; }
        }
        @media (max-width: 620px) {
            .checkout-header { height: 78px; }
            .header-inner, .page { width: calc(100% - 32px); }
            .brand { font-size: 24px; }
            .secure { font-size: 12px; }
            .page { padding-top: 31px; }
            .page-title { font-size: 38px; }
            .delivery-card, .items-card, .summary-card { padding: 22px 18px; }
            .card-title, .summary-title { font-size: 25px; }
            .address-row { gap: 16px; align-items: flex-start; }
            .pin { width: 58px; height: 58px; flex-basis: 58px; font-size: 25px; }
            .address-copy { padding-left: 16px; font-size: 12px; }
            .item { gap: 12px; }
            .item-image { width: 76px; height: 68px; flex-basis: 76px; }
            .item-name { font-size: 13px; }
            .item-meta, .item-qty, .item-price { font-size: 11px; }
            .item-qty { width: 45px; }
            .item-price { width: 73px; }
        }
    </style>
</head>
<body>
<header class="checkout-header">
    <div class="header-inner">
        <a class="brand" href="{{ route('shop.index') }}">LUM<span>O</span>RA</a>
        <nav class="steps" aria-label="Checkout progress">
            <span class="step">Cart <span class="chevron">›</span></span>
            <span class="step active">Checkout <span class="chevron">›</span></span>
            <span class="step">Confirmation</span>
        </nav>
        <div class="secure"><span class="lock" aria-hidden="true"><svg viewBox="0 0 24 24" width="20" height="20" fill="none" stroke="currentColor" stroke-width="1.8"><rect x="5" y="10" width="14" height="11" rx="2"></rect><path d="M8 10V7a4 4 0 0 1 8 0v3"></path></svg></span> Secure checkout</div>
    </div>
</header>

<main class="page">
    <h1 class="page-title">Checkout</h1>

    @if($errors->any())
        <div class="error">{{ $errors->first() }}</div>
    @endif

    <div class="layout">
        <section class="left-column">
            <div class="card delivery-card">
                <h2 class="card-title">Delivery information</h2>
                <div class="address-row">
                    <div class="pin" aria-hidden="true"><svg viewBox="0 0 24 24" width="38" height="38" fill="none" stroke="currentColor" stroke-width="1.5"><path d="M20 10c0 5-8 11-8 11S4 15 4 10a8 8 0 1 1 16 0Z"></path><circle cx="12" cy="10" r="2.7"></circle></svg></div>
                    <div class="address-copy">
                        <div class="address-name">{{ $buyer->name }}</div>
                        @if($buyer->house_number || $buyer->street)
                            {{ $buyer->house_number }} {{ $buyer->street }}<br>
                        @endif
                        {{ $buyer->barangay }}@if($buyer->barangay && $buyer->municipality), @endif{{ $buyer->municipality }}<br>
                        {{ $buyer->province }}<br>
                        <div class="contact">☎ {{ $buyer->contact_number }}</div>
                    </div>
                </div>
            </div>

            <div class="card items-card">
                <h2 class="card-title">Items to purchase</h2>
                @foreach($cartItems as $item)
                    @php($product = $item['product'])
                    <div class="item">
                        @if($product->image)
                            <img class="item-image" src="{{ Storage::url($product->image) }}" alt="{{ $product->name }}">
                        @else
                            <div class="item-image"></div>
                        @endif
                        <div class="item-details">
                            <div class="item-name">{{ $product->name }}</div>
                            <div class="item-meta">Quantity: {{ $item['quantity'] }}</div>
                        </div>
                        <div class="item-qty">Qty: {{ $item['quantity'] }}</div>
                        <div class="item-price">₱{{ number_format($item['line_total'], 2) }}</div>
                    </div>
                @endforeach
            </div>
            <a class="return-link" href="{{ route('buyer.cart') }}">← &nbsp;Return to cart</a>
        </section>

        <aside class="card summary-card">
            <h2 class="summary-title">Order summary</h2>
            <div class="summary-row"><span>Subtotal</span><strong>₱{{ number_format($summary['subtotal'], 2) }}</strong></div>
            <div class="summary-row discount"><span>Discount</span><strong>- ₱{{ number_format($summary['discount'], 2) }}</strong></div>
            <div class="summary-row"><span>Shipping</span><strong>₱{{ number_format($summary['shipping'], 2) }}</strong></div>
            <div class="summary-total"><span>Total</span><strong>₱{{ number_format($summary['total'], 2) }}</strong></div>

            <form method="POST" action="{{ route('buyer.checkout.store') }}">
                @csrf
                <label class="payment-label" for="payment_method">Payment method</label>
                <label class="payment-option">
                    <input id="payment_method" type="radio" name="payment_method" value="cod" checked>
                    <span>Cash on Delivery</span>
                </label>
                <button class="place-order" type="submit">Place order</button>
            </form>
        </aside>
    </div>
</main>
</body>
</html>
