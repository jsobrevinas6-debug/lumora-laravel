<!DOCTYPE html>
<html lang="{{ str_replace('_', '-', app()->getLocale()) }}">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <meta name="csrf-token" content="{{ csrf_token() }}">
    <title>{{ $product->name }} &middot; {{ config('app.name', 'Lumora') }}</title>
    @vite(['resources/css/app.css', 'resources/js/app.js'])
    <style>
        :root { --cream:#fffaf7; --paper:#fffdfb; --line:#eadfe0; --plum:#3d1b3d; --rose:#b96562; --muted:#766a70; --green:#66945e; }
        * { box-sizing:border-box; }
        body { margin:0; background:var(--cream); color:var(--plum); font-family:Inter,ui-sans-serif,system-ui,sans-serif; }
        a { color:inherit; text-decoration:none; }
        .product-page { min-height:100vh; }
        .topbar { min-height:78px; display:flex; align-items:center; background:rgba(255,253,251,.98); border-bottom:1px solid var(--line); }
        .topbar-inner { width:min(1380px,calc(100% - 48px)); margin:auto; display:flex; align-items:center; gap:20px; }
        .brand { display:flex; align-items:center; gap:8px; min-width:210px; font-family:Georgia,serif; font-size:23px; font-weight:700; letter-spacing:.3px; }
        .brand-mark { width:27px; height:27px; color:#cf744d; }
        .search { flex:1; height:44px; padding:0 19px; border:1px solid var(--line); border-radius:25px; background:white; font:inherit; color:var(--plum); }
        .top-action { width:42px; height:42px; display:grid; place-items:center; border:1px solid var(--line); border-radius:50%; background:white; color:var(--plum); }
        .top-action svg { width:20px; height:20px; }
        .product-shell { width:min(1380px,calc(100% - 48px)); margin:0 auto; padding:22px 0 70px; }
        .breadcrumb { margin-bottom:25px; color:var(--muted); font-size:13px; }
        .breadcrumb a:hover { color:var(--rose); }
        .breadcrumb strong { color:var(--plum); }
        .product-detail { display:grid; grid-template-columns:minmax(0,1.18fr) minmax(330px,.92fr) minmax(220px,.55fr); gap:42px; align-items:start; }
        .gallery { display:grid; grid-template-columns:86px minmax(0,1fr); gap:14px; }
        .thumbs { display:flex; flex-direction:column; gap:12px; }
        .thumb { width:86px; height:86px; display:grid; place-items:center; overflow:hidden; border:1px solid var(--line); border-radius:10px; background:#f6eee9; }
        .thumb.active { border:2px solid var(--plum); box-shadow:0 0 0 3px #f2dcd4; }
        .thumb img { width:100%; height:100%; object-fit:cover; }
        .thumb-placeholder { color:#cbbcb8; font-size:23px; }
        .main-photo { position:relative; min-height:560px; display:grid; place-items:center; overflow:hidden; border-radius:16px; background:linear-gradient(135deg,#f1ddd5,#e5c4ba); }
        .main-photo img { width:100%; height:100%; min-height:560px; object-fit:cover; }
        .photo-placeholder { color:rgba(61,27,61,.42); font-family:Georgia,serif; font-size:52px; }
        .zoom { position:absolute; right:16px; bottom:16px; width:38px; height:38px; display:grid; place-items:center; border:0; border-radius:50%; background:rgba(255,253,251,.85); color:var(--plum); }
        .zoom svg { width:19px; height:19px; }
        .eyebrow { color:var(--rose); font-size:11px; font-weight:700; letter-spacing:.15em; text-transform:uppercase; }
        h1 { margin:9px 0 12px; font-family:Georgia,serif; font-size:43px; font-weight:500; line-height:1.05; }
        .rating { margin:0 0 22px; color:var(--plum); font-size:13px; }
        .muted { color:var(--muted); }
        .price-row { display:flex; align-items:center; gap:12px; flex-wrap:wrap; margin:18px 0 21px; }
        .price { color:var(--rose); font-size:27px; font-weight:700; }
        .old-price { color:#a99b9f; font-size:14px; text-decoration:line-through; }
        .sale-badge { padding:5px 9px; border-radius:999px; background:#b85c3b; color:white; font-size:10px; font-weight:800; }
        .description { padding:18px 0; border-top:1px solid var(--line); color:var(--muted); line-height:1.7; white-space:pre-line; }
        .stock { margin:17px 0 19px; color:var(--green); font-size:13px; font-weight:700; }
        .stock.out { color:#b85c3b; }
        .quantity-label { display:block; margin-bottom:8px; color:var(--plum); font-size:12px; font-weight:600; }
        .purchase-row { display:flex; gap:14px; align-items:center; }
        .quantity { height:48px; display:flex; align-items:center; border:1px solid var(--line); border-radius:9px; background:white; }
        .quantity button { width:40px; height:100%; border:0; background:transparent; color:var(--plum); font-size:20px; cursor:pointer; }
        .quantity output { min-width:38px; text-align:center; font-size:13px; }
        .button { min-height:46px; padding:0 22px; display:inline-flex; align-items:center; justify-content:center; gap:8px; border:1px solid var(--plum); border-radius:8px; background:white; color:var(--plum); font:inherit; font-weight:700; cursor:pointer; }
        .button.primary { flex:1; background:var(--green); border-color:var(--green); color:white; }
        .button.primary:hover { background:#567f50; }
        .button.added { background:#4f8050; border-color:#4f8050; }
        .wishlist { width:100%; margin-top:12px; }
        .service-stack { display:flex; flex-direction:column; gap:14px; }
        .service-card { display:grid; grid-template-columns:34px 1fr; gap:12px; padding:22px 18px; border-radius:10px; background:#fff3ed; }
        .service-card svg { width:28px; height:28px; color:var(--rose); }
        .service-card strong { display:block; margin-bottom:5px; font-size:13px; }
        .service-card span { color:var(--muted); font-size:11px; line-height:1.45; }
        .info-panel { margin-top:42px; border:1px solid var(--line); border-radius:14px; background:var(--paper); overflow:hidden; }
        .tabs { display:flex; gap:35px; padding:0 22px; border-bottom:1px solid var(--line); }
        .tab { padding:18px 0 14px; border:0; border-bottom:2px solid transparent; background:transparent; color:var(--muted); font:inherit; font-size:12px; cursor:pointer; }
        .tab.active { border-bottom-color:var(--rose); color:var(--plum); font-weight:700; }
        .tab-panel { display:none; min-height:130px; padding:22px; color:var(--muted); font-size:13px; line-height:1.7; white-space:pre-line; }
        .tab-panel.active { display:block; }
        .related { padding:0 22px 24px; }
        .related h2 { margin:18px 0 14px; font-family:Georgia,serif; font-size:20px; font-weight:500; }
        .related-grid { display:grid; grid-template-columns:repeat(4,minmax(0,1fr)); gap:14px; }
        .related-card { min-width:0; }
        .related-image { height:135px; display:grid; place-items:center; overflow:hidden; border-radius:9px; background:linear-gradient(135deg,#f2dfd8,#e8c8be); }
        .related-image img { width:100%; height:100%; object-fit:cover; }
        .related-image span { color:rgba(61,27,61,.4); font-family:Georgia,serif; font-size:22px; }
        .related-name { margin-top:8px; font-family:Georgia,serif; font-size:13px; }
        .related-price { margin-top:4px; color:var(--rose); font-size:12px; font-weight:700; }
        @media (max-width:1050px) { .product-detail { grid-template-columns:minmax(0,1fr) minmax(300px,.9fr); } .service-stack { grid-column:1 / -1; display:grid; grid-template-columns:repeat(3,1fr); } }
        @media (max-width:720px) { .topbar-inner,.product-shell { width:min(100% - 28px,1380px); } .brand { min-width:auto; } .brand span { display:none; } .product-detail { display:block; } .gallery { margin-bottom:30px; } .main-photo,.main-photo img { min-height:420px; } .service-stack { display:grid; grid-template-columns:1fr; margin-top:30px; } h1 { font-size:37px; } .tabs { gap:18px; overflow-x:auto; } .tabs .tab { white-space:nowrap; } .related-grid { grid-template-columns:repeat(2,1fr); } }
    </style>
</head>
<body>
<div class="product-page">
    <header class="topbar">
        <div class="topbar-inner">
            <a class="brand" href="{{ route('shop.index') }}" aria-label="Lumora shop">
                <svg class="brand-mark" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.6"><path d="M5 21V9a7 7 0 0 1 14 0v12"/><path d="M9 21v-6a3 3 0 0 1 6 0v6"/></svg><span>LUMORA</span>
            </a>
            <input class="search" type="search" placeholder="Search skincare, makeup, fragrance..." aria-label="Search products">
            <button class="top-action" type="button" aria-label="Add to wishlist"><svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.7"><path d="M20.8 4.6a5.5 5.5 0 0 0-7.8 0L12 5.6l-1-1a5.5 5.5 0 0 0-7.8 7.8l1 1L12 21l7.8-7.6 1-1a5.5 5.5 0 0 0 0-7.8Z"/></svg></button>
            <a class="top-action" href="{{ route('buyer.cart') }}" aria-label="View cart"><svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.7"><path d="M3 4h2l2.2 11.2a2 2 0 0 0 2 1.6h7.9a2 2 0 0 0 1.9-1.4L21 8H7"/><circle cx="10" cy="20" r="1"/><circle cx="18" cy="20" r="1"/></svg><span data-cart-count>{{ session('lumora_cart') ? collect(session('lumora_cart'))->sum('quantity') : 0 }}</span></a>
        </div>
    </header>

    <main class="product-shell">
        <div class="breadcrumb"><a href="{{ route('shop.index') }}">Home</a> <span>&rsaquo;</span> <a href="{{ route('shop.index', ['category' => $product->category]) }}">{{ $categoryTitle }}</a> <span>&rsaquo;</span> <strong>{{ $product->name }}</strong></div>
        <section class="product-detail">
            <div class="gallery">
                <div class="thumbs">
                    <button class="thumb active" type="button" aria-label="Product image">
                        @if (!empty($product->image))<img src="{{ Storage::url($product->image) }}" alt="{{ $product->name }}">@else<span class="thumb-placeholder">&#9671;</span>@endif
                    </button>
                </div>
                <div class="main-photo">
                    @if (!empty($product->image))<img src="{{ Storage::url($product->image) }}" alt="{{ $product->name }}">@else<span class="photo-placeholder">Lumora</span>@endif
                    <button class="zoom" type="button" aria-label="Zoom image"><svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.7"><circle cx="10.8" cy="10.8" r="6.8"/><path d="m16 16 5 5M10.8 7.8v6M7.8 10.8h6"/></svg></button>
                </div>
            </div>

            <div class="product-copy">
                @php
                    $rating = (float) ($product->rating ?? 0);
                    $salesCount = (int) ($product->sales_count ?? 0);
                    $discountPercent = (float) ($product->discount_percent ?? 0);
                    $originalPrice = (float) $product->price;
                    $finalPrice = $discountPercent > 0 ? $originalPrice * (1 - ($discountPercent / 100)) : $originalPrice;
                    $sellerName = $product->shop_name ?: ($product->seller_name ?: 'Lumora seller');
                    $stock = (int) ($product->stock ?? 0);
                @endphp
                <div class="eyebrow">{{ $sellerName }}</div>
                <h1>{{ $product->name }}</h1>
                <div class="rating">@if ($rating > 0){{ str_repeat('&#9733;', (int) round($rating)) }}{{ str_repeat('&#9734;', 5 - (int) round($rating)) }} <span>({{ number_format($rating, 2) }})</span>@else <span class="muted">No ratings yet</span>@endif @if ($salesCount > 0)<span class="muted"> &middot; {{ number_format($salesCount) }} sold</span>@endif</div>
                <div class="price-row"><span class="price">&#8369;{{ number_format($finalPrice, 2) }}</span>@if ($discountPercent > 0)<span class="old-price">&#8369;{{ number_format($originalPrice, 2) }}</span><span class="sale-badge">{{ rtrim(rtrim(number_format($discountPercent, 1), '0'), '.') }}% OFF</span>@endif</div>
                <div class="description">{{ $product->description ?: 'Discover more details about this Lumora product.' }}</div>
                <div class="stock {{ $stock < 1 ? 'out' : '' }}">{{ $stock > 0 ? $stock . ' available' : 'Out of stock' }} @if ($stock > 0)<span class="muted"> &middot; In stock and ready to ship</span>@endif</div>
                <label class="quantity-label" for="quantityOutput">Quantity</label>
                <form method="POST" action="{{ route('buyer.cart.add', ['product' => $product->id]) }}" id="detailCartForm" class="lumora-cart-form" data-cart-product-name="{{ $product->name }}" data-cart-product-price="{{ $finalPrice }}" data-cart-product-image="{{ !empty($product->image) ? Storage::url($product->image) : '' }}">
                    @csrf
                    <input type="hidden" name="quantity" id="quantityInput" value="1">
                    <div class="purchase-row">
                        <div class="quantity"><button type="button" id="quantityMinus" aria-label="Decrease quantity">&#8722;</button><output id="quantityOutput">1</output><button type="button" id="quantityPlus" aria-label="Increase quantity">+</button></div>
                        <button type="submit" class="button primary add-detail-cart" @disabled($stock < 1)>Add to cart</button>
                    </div>
                    <button type="submit" class="button wishlist buy-now" id="buyNowButton" name="buy_now" value="1" @disabled($stock < 1)>Buy now</button>
                </form>
            </div>

            <aside class="service-stack" aria-label="Shopping services">
                <div class="service-card"><svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.6"><path d="M3 6h11v10H3zM14 10h4l3 3v3h-7z"/><circle cx="7" cy="18" r="2"/><circle cx="18" cy="18" r="2"/></svg><div><strong>Free Shipping</strong><span>Shipping details are shown at checkout.</span></div></div>
                <div class="service-card"><svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.6"><path d="M3 6h11v10H3zM14 10h4l3 3v3h-7z"/><path d="M5 4h6"/></svg><div><strong>Fast Delivery</strong><span>Delivery options depend on your location.</span></div></div>
                <div class="service-card"><svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.6"><path d="M12 3 4 7v5c0 5 3.5 8 8 9 4.5-1 8-4 8-9V7l-8-4Z"/><path d="m8 12 2.5 2.5L16 9"/></svg><div><strong>Cash on Delivery</strong><span>Available methods appear at checkout.</span></div></div>
            </aside>
        </section>

        <section class="info-panel">
            <div class="tabs" role="tablist">
                <button class="tab active" type="button" data-tab="description">Description</button>
                <button class="tab" type="button" data-tab="details">Product Details</button>
                <button class="tab" type="button" data-tab="reviews">Reviews</button>
                <button class="tab" type="button" data-tab="shipping">Shipping &amp; Returns</button>
            </div>
            <div class="tab-panel active" id="description">{{ $product->description ?: 'No description has been added for this product yet.' }}</div>
            <div class="tab-panel" id="details">Category: {{ $categoryTitle }}<br>Seller: {{ $sellerName }}<br>Stock: {{ $stock > 0 ? $stock . ' available' : 'Out of stock' }}</div>
            <div class="tab-panel" id="reviews">@if ($rating > 0)Rated {{ number_format($rating, 2) }} out of 5.@else No reviews yet. Be the first to review this product after purchase.@endif</div>
            <div class="tab-panel" id="shipping">Shipping and return information will be shown according to the seller and checkout options.</div>
            @if ($relatedProducts->count())
                <div class="related"><h2>You may also like</h2><div class="related-grid">
                    @foreach ($relatedProducts as $related)
                        <a class="related-card" href="{{ route('shop.product', ['id' => $related->id]) }}"><div class="related-image">@if (!empty($related->image))<img src="{{ Storage::url($related->image) }}" alt="{{ $related->name }}">@else<span>Lumora</span>@endif</div><div class="related-name">{{ $related->name }}</div><div class="related-price">&#8369;{{ number_format((float) $related->price, 2) }}</div></a>
                    @endforeach
                </div></div>
            @endif
        </section>
    </main>
</div>

@if (view()->exists('components.chat-widget'))
    @include('components.chat-widget')
@endif

@include('components.add-to-cart-success-modal')

<script>
    const output = document.getElementById('quantityOutput');
    const quantityInput = document.getElementById('quantityInput');
    const maxStock = {{ max(1, (int) ($product->stock ?? 0)) }};
    function setQuantity(value) {
        const quantity = Math.max(1, Math.min(maxStock, Number(value) || 1));
        output.textContent = String(quantity);
        quantityInput.value = String(quantity);
    }
    document.getElementById('quantityMinus')?.addEventListener('click', () => setQuantity(Number(output.textContent) - 1));
    document.getElementById('quantityPlus')?.addEventListener('click', () => setQuantity(Number(output.textContent) + 1));
    document.querySelectorAll('[data-tab]').forEach(tab => tab.addEventListener('click', () => {
        document.querySelectorAll('[data-tab], .tab-panel').forEach(item => item.classList.remove('active'));
        tab.classList.add('active');
        document.getElementById(tab.dataset.tab)?.classList.add('active');
    }));
</script>
</body>
</html>
