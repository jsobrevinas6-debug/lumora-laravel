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
        .search { flex:1; height:44px; padding:0 19px; border:1px solid var(--line); border-radius:25px; background:white; font:inherit; color:var(--plum); }
        .top-action { width:42px; height:42px; display:grid; place-items:center; border:1px solid var(--line); border-radius:50%; background:white; color:var(--plum); }
        .top-action svg { width:20px; height:20px; }
        .product-shell { width:min(1380px,calc(100% - 48px)); margin:0 auto; padding:22px 0 70px; }
        .flash { margin:0 0 18px; padding:12px 15px; border:1px solid var(--line); border-radius:8px; background:var(--paper); color:var(--rose); font-size:13px; }
        .flash.success { color:#6F8F78; }
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
        .rating-link { display:inline-flex; align-items:center; gap:8px; color:inherit; }
        .stars { letter-spacing:1px; white-space:nowrap; }
        .stars .filled { color:#C98F72; }
        .stars .empty { color:#EAE3DD; }
        .sold-by { display:flex; align-items:center; gap:9px; flex-wrap:wrap; margin:-3px 0 15px; color:var(--muted); font-size:13px; }
        .sold-by strong { color:var(--plum); }
        .sold-by a { color:var(--rose); font-weight:800; }
        .seller-badge { display:inline-flex; align-items:center; gap:5px; min-height:22px; padding:0 8px; border-radius:999px; background:rgba(102,148,94,.13); color:var(--green); font-size:10px; font-weight:900; text-transform:uppercase; }
        .purchase-row form { flex:1; display:flex; margin:0; }
        .purchase-row .button.primary { width:100%; }
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
        .shop-profile { padding:24px 22px 26px; border-top:1px solid var(--line); }
        .shop-profile h2 { margin:0 0 16px; font-family:Georgia,serif; font-size:24px; font-weight:500; }
        .shop-box { display:grid; grid-template-columns:minmax(240px,.52fr) minmax(280px,.48fr); gap:22px; align-items:start; }
        .shop-head { display:grid; grid-template-columns:72px 1fr; gap:15px; align-items:center; margin-bottom:15px; }
        .shop-avatar { width:72px; height:72px; display:grid; place-items:center; overflow:hidden; border:1px solid var(--line); border-radius:50%; background:#f6eee9; color:var(--plum); font-family:Georgia,serif; font-size:24px; }
        .shop-avatar img { width:100%; height:100%; object-fit:cover; }
        .shop-name { display:flex; align-items:center; gap:8px; flex-wrap:wrap; color:var(--plum); font-family:Georgia,serif; font-size:24px; }
        .shop-location { margin-top:6px; color:var(--muted); font-size:13px; }
        .shop-description { margin:0; color:var(--muted); font-size:13px; line-height:1.7; }
        .shop-stats { display:grid; grid-template-columns:repeat(2,minmax(0,1fr)); gap:10px; }
        .shop-stat { min-height:78px; padding:14px; border:1px solid var(--line); border-radius:8px; background:#FFFDFC; }
        .shop-stat strong { display:block; color:var(--plum); font-size:20px; }
        .shop-stat span { color:var(--muted); font-size:11px; font-weight:800; text-transform:uppercase; }
        .shop-actions { display:flex; gap:10px; flex-wrap:wrap; margin-top:14px; }
        .shop-action { min-height:42px; padding:0 15px; display:inline-flex; align-items:center; justify-content:center; border:1px solid var(--plum); border-radius:8px; background:var(--plum); color:white; font-size:12px; font-weight:800; cursor:pointer; }
        .shop-action.secondary { background:white; color:var(--plum); }
        .shop-action[disabled] { border-color:var(--line); background:#f6eee9; color:#9d8e93; cursor:not-allowed; }
        .shop-products { margin-top:24px; }
        .shop-products h3 { margin:0 0 13px; font-family:Georgia,serif; font-size:19px; font-weight:500; }
        .shop-empty { margin:0; color:var(--muted); font-size:13px; }
        #reviews.tab-panel { white-space:normal; }
        .reviews-summary { display:grid; grid-template-columns:minmax(180px,.4fr) minmax(260px,.6fr); gap:24px; margin-bottom:24px; padding-bottom:22px; border-bottom:1px solid var(--line); }
        .reviews-score { color:var(--plum); font-family:Georgia,serif; font-size:46px; line-height:1; }
        .reviews-based { margin-top:8px; color:var(--muted); }
        .rating-breakdown { display:grid; gap:8px; }
        .rating-bar { display:grid; grid-template-columns:58px 1fr 34px; gap:10px; align-items:center; color:var(--muted); font-size:12px; }
        .rating-track { height:8px; overflow:hidden; border-radius:999px; background:#EAE3DD; }
        .rating-fill { height:100%; border-radius:999px; background:#C98F72; }
        .review-list { display:grid; gap:16px; margin-top:22px; }
        .review-card { padding:16px; border:1px solid var(--line); border-radius:10px; background:#FFFDFC; }
        .review-head { display:flex; justify-content:space-between; gap:14px; margin-bottom:8px; }
        .review-name { color:var(--plum); font-weight:700; }
        .review-date { color:var(--muted); font-size:12px; }
        .verified-badge { display:inline-flex; margin-top:6px; padding:3px 8px; border-radius:999px; background:rgba(111,143,120,.13); color:#6F8F78; font-size:10px; font-weight:800; text-transform:uppercase; }
        .review-text { margin:10px 0 0; color:var(--muted); line-height:1.65; }
        .review-form { margin-top:24px; padding:18px; border:1px solid var(--line); border-radius:10px; background:#FFFDFC; }
        .review-form h3 { margin:0 0 14px; font-family:Georgia,serif; color:var(--plum); font-size:22px; font-weight:500; }
        .star-input { display:inline-flex; flex-direction:row-reverse; gap:4px; margin-bottom:14px; }
        .star-input input { position:absolute; opacity:0; pointer-events:none; }
        .star-input label { color:#EAE3DD; font-size:28px; line-height:1; cursor:pointer; transition:color .2s ease; }
        .star-input input:checked ~ label, .star-input label:hover, .star-input label:hover ~ label { color:#C98F72; }
        .review-textarea { width:100%; min-height:110px; padding:13px; border:1px solid var(--line); border-radius:8px; background:white; color:var(--plum); font:inherit; resize:vertical; }
        .review-actions { display:flex; align-items:center; gap:10px; flex-wrap:wrap; margin-top:12px; }
        .review-submit, .review-delete { min-height:42px; padding:0 18px; border-radius:8px; font:inherit; font-size:12px; font-weight:800; cursor:pointer; }
        .review-submit { border:1px solid var(--plum); background:var(--plum); color:white; }
        .review-delete { border:1px solid var(--line); background:white; color:var(--muted); }
        .review-note { margin:18px 0 0; color:var(--muted); }
        .related { padding:0 22px 24px; }
        .related h2 { margin:18px 0 14px; font-family:Georgia,serif; font-size:20px; font-weight:500; }
        .related-grid { display:grid; grid-template-columns:repeat(4,minmax(0,1fr)); gap:14px; }
        .related-card { min-width:0; }
        .related-image { height:135px; display:grid; place-items:center; overflow:hidden; border-radius:9px; background:linear-gradient(135deg,#f2dfd8,#e8c8be); }
        .related-image img { width:100%; height:100%; object-fit:cover; }
        .related-image span { color:rgba(61,27,61,.4); font-family:Georgia,serif; font-size:22px; }
        .related-name { margin-top:8px; font-family:Georgia,serif; font-size:13px; }
        .related-price { margin-top:4px; color:var(--rose); font-size:12px; font-weight:700; }
        @media (max-width:1050px) { .product-detail { grid-template-columns:minmax(0,1fr) minmax(300px,.9fr); } .service-stack { grid-column:1 / -1; display:grid; grid-template-columns:repeat(3,1fr); } .shop-box { grid-template-columns:1fr; } }
        @media (max-width:720px) { .topbar-inner,.product-shell { width:min(100% - 28px,1380px); } .product-detail { display:block; } .gallery { margin-bottom:30px; } .main-photo,.main-photo img { min-height:420px; } .service-stack { display:grid; grid-template-columns:1fr; margin-top:30px; } h1 { font-size:37px; } .tabs { gap:18px; overflow-x:auto; } .tabs .tab { white-space:nowrap; } .related-grid { grid-template-columns:repeat(2,1fr); } .shop-stats { grid-template-columns:1fr; } }
    </style>
</head>
<body>
<div class="product-page">
    <header class="topbar">
        <div class="topbar-inner">
            <x-logo :href="route('shop.index')" aria-label="Lumora shop" />
            <input class="search" type="search" placeholder="Search skincare, makeup, fragrance..." aria-label="Search products">
            <button class="top-action" type="button" aria-label="Add to wishlist"><svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.7"><path d="M20.8 4.6a5.5 5.5 0 0 0-7.8 0L12 5.6l-1-1a5.5 5.5 0 0 0-7.8 7.8l1 1L12 21l7.8-7.6 1-1a5.5 5.5 0 0 0 0-7.8Z"/></svg></button>
            <a class="top-action" href="{{ route('buyer.cart') }}" aria-label="View cart"><svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.7"><path d="M3 4h2l2.2 11.2a2 2 0 0 0 2 1.6h7.9a2 2 0 0 0 1.9-1.4L21 8H7"/><circle cx="10" cy="20" r="1"/><circle cx="18" cy="20" r="1"/></svg><span data-cart-count>{{ session('lumora_cart') ? collect(session('lumora_cart'))->sum('quantity') : 0 }}</span></a>
        </div>
    </header>

    <main class="product-shell">
        @if (session('success'))
            <div class="flash success">{{ session('success') }}</div>
        @endif
        @if (session('error') || $errors->any())
            <div class="flash">{{ session('error') ?: $errors->first() }}</div>
        @endif
        <div class="breadcrumb"><a href="{{ route('shop.index') }}">Home</a> <span>&rsaquo;</span> <a href="{{ route('shop.index', ['category' => $product->category]) }}">{{ $categoryTitle }}</a> <span>&rsaquo;</span> <strong>{{ $product->name }}</strong></div>
        <section class="product-detail">
            <div class="gallery">
                <div class="thumbs">
                    <button class="thumb active" type="button" aria-label="Product image">
                        <img src="{{ $product->image_url }}" alt="{{ $product->name }}" loading="lazy" onerror="this.onerror=null;this.src='{{ asset('images/product-placeholder.png') }}';">
                    </button>
                </div>
                <div class="main-photo">
                    <img src="{{ $product->image_url }}" alt="{{ $product->name }}" loading="lazy" onerror="this.onerror=null;this.src='{{ asset('images/product-placeholder.png') }}';">
                    <button class="zoom" type="button" aria-label="Zoom image"><svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.7"><circle cx="10.8" cy="10.8" r="6.8"/><path d="m16 16 5 5M10.8 7.8v6M7.8 10.8h6"/></svg></button>
                </div>
            </div>

            <div class="product-copy">
                @php
                    $averageRating = round((float) ($product->reviews_avg_rating ?? 0), 1);
                    $reviewCount = (int) ($product->reviews_count ?? 0);
                    $roundedRating = (int) round($averageRating);
                    $salesCount = (int) ($product->sales_count ?? 0);
                    $discountPercent = (float) ($product->discount_percent ?? 0);
                    $originalPrice = (float) $product->price;
                    $finalPrice = $discountPercent > 0 ? $originalPrice * (1 - ($discountPercent / 100)) : $originalPrice;
                    $shopProfile = $shopProfile ?? [];
                    $sellerName = $shopProfile['name'] ?? ($product->seller?->shop_name ?: ($product->seller?->name ?: 'Lumora seller'));
                    $stock = (int) ($product->stock ?? 0);
                @endphp
                <div class="eyebrow">{{ $sellerName }}</div>
                <h1>{{ $product->name }}</h1>
                @if (! empty($shopProfile['seller']))
                    <div class="sold-by">
                        <span>Sold by</span>
                        <strong>{{ $sellerName }}</strong>
                        @if (! empty($shopProfile['verified']))
                            <span class="seller-badge">Verified Seller</span>
                        @endif
                        @if (! empty($shopProfile['url']))
                            <a href="{{ $shopProfile['url'] }}">View Shop</a>
                        @endif
                    </div>
                @endif
                <div class="rating">
                    <a href="#reviews" class="rating-link" data-open-reviews>
                        <span class="stars" aria-label="{{ number_format($averageRating, 1) }} out of 5 stars">
                            @for ($star = 1; $star <= 5; $star++)
                                <span class="{{ $star <= $roundedRating ? 'filled' : 'empty' }}">★</span>
                            @endfor
                        </span>
                        <span>{{ number_format($averageRating, 1) }} ({{ $reviewCount }} {{ $reviewCount === 1 ? 'review' : 'reviews' }})</span>
                    </a>
                    @if ($salesCount > 0)<span class="muted"> &middot; {{ number_format($salesCount) }} sold</span>@endif
                </div>
                <div class="price-row"><span class="price">&#8369;{{ number_format($finalPrice, 2) }}</span>@if ($discountPercent > 0)<span class="old-price">&#8369;{{ number_format($originalPrice, 2) }}</span><span class="sale-badge">{{ rtrim(rtrim(number_format($discountPercent, 1), '0'), '.') }}% OFF</span>@endif</div>
                <div class="description">{{ $product->description ?: 'Discover more details about this Lumora product.' }}</div>
                <div class="stock {{ $stock < 1 ? 'out' : '' }}">{{ $stock > 0 ? $stock . ' available' : 'Out of stock' }} @if ($stock > 0)<span class="muted"> &middot; In stock and ready to ship</span>@endif</div>
                <label class="quantity-label" for="quantityOutput">Quantity</label>
                <div class="purchase-row">
                    <div class="quantity"><button type="button" id="quantityMinus" aria-label="Decrease quantity">&#8722;</button><output id="quantityOutput">1</output><button type="button" id="quantityPlus" aria-label="Increase quantity">+</button></div>
                    <form method="POST" action="{{ route('buyer.cart.add', ['product' => $product->id]) }}" id="detailCartForm" class="lumora-cart-form" data-cart-product-name="{{ $product->name }}" data-cart-product-price="{{ $finalPrice }}" data-cart-product-image="{{ $product->image_url }}">
                        @csrf
                        <input type="hidden" name="quantity" id="quantityInput" value="1">
                        <button type="submit" class="button primary add-detail-cart" @disabled($stock < 1)>Add to cart</button>
                    </form>
                </div>
                <form method="POST" action="{{ route('buyer.buy-now', ['product' => $product->id]) }}" id="buyNowForm">
                    @csrf
                    <input type="hidden" name="quantity" id="buy-now-quantity" value="1">
                    <button type="submit" class="button wishlist buy-now" id="buyNowButton" @disabled($stock < 1)>Buy now</button>
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
            <div class="tab-panel" id="reviews">
                <div class="reviews-summary">
                    <div>
                        <div class="reviews-score">{{ number_format($averageRating, 1) }}</div>
                        <div class="stars" aria-label="{{ number_format($averageRating, 1) }} out of 5 stars">
                            @for ($star = 1; $star <= 5; $star++)
                                <span class="{{ $star <= $roundedRating ? 'filled' : 'empty' }}">★</span>
                            @endfor
                        </div>
                        <div class="reviews-based">Based on {{ $reviewCount }} {{ $reviewCount === 1 ? 'review' : 'reviews' }}</div>
                    </div>
                    <div class="rating-breakdown">
                        @for ($star = 5; $star >= 1; $star--)
                            @php
                                $starTotal = (int) ($ratingBreakdown->get($star, 0));
                                $starPercent = $reviewCount > 0 ? ($starTotal / $reviewCount) * 100 : 0;
                            @endphp
                            <div class="rating-bar">
                                <span>{{ $star }} stars</span>
                                <span class="rating-track"><span class="rating-fill" style="width: {{ $starPercent }}%"></span></span>
                                <span>{{ $starTotal }}</span>
                            </div>
                        @endfor
                    </div>
                </div>

                @if ($reviews->count())
                    <div class="review-list">
                        @foreach ($reviews as $review)
                            <article class="review-card">
                                <div class="review-head">
                                    <div>
                                        <div class="review-name">{{ $review->user?->name ?? 'Lumora buyer' }}</div>
                                        <div class="stars" aria-label="{{ $review->rating }} out of 5 stars">
                                            @for ($star = 1; $star <= 5; $star++)
                                                <span class="{{ $star <= $review->rating ? 'filled' : 'empty' }}">★</span>
                                            @endfor
                                        </div>
                                        @if ($review->order_id)
                                            <span class="verified-badge">Verified Purchase</span>
                                        @endif
                                    </div>
                                    <time class="review-date" datetime="{{ $review->created_at?->toDateString() }}">{{ $review->created_at?->format('M d, Y') }}</time>
                                </div>
                                @if ($review->review)
                                    <p class="review-text">{{ $review->review }}</p>
                                @endif
                            </article>
                        @endforeach
                    </div>
                    <div class="pagination">{{ $reviews->links() }}</div>
                @else
                    <p class="review-note">No reviews yet. Be the first to review this product after purchase.</p>
                @endif

                @if ($userReview)
                    <form class="review-form" method="POST" action="{{ route('buyer.products.reviews.update', ['product' => $product->id, 'review' => $userReview->id]) }}">
                        @csrf
                        @method('PATCH')
                        <h3>Edit Review</h3>
                        <div class="star-input" aria-label="Choose a rating">
                            @for ($star = 5; $star >= 1; $star--)
                                <input type="radio" id="rating-edit-{{ $star }}" name="rating" value="{{ $star }}" @checked((int) old('rating', $userReview->rating) === $star)>
                                <label for="rating-edit-{{ $star }}">★</label>
                            @endfor
                        </div>
                        <textarea class="review-textarea" name="review" maxlength="2000" placeholder="Share your experience with this product...">{{ old('review', $userReview->review) }}</textarea>
                        <div class="review-actions">
                            <button class="review-submit" type="submit">Update Review</button>
                        </div>
                    </form>
                    <form method="POST" action="{{ route('buyer.products.reviews.destroy', ['product' => $product->id, 'review' => $userReview->id]) }}" class="review-actions">
                        @csrf
                        @method('DELETE')
                        <button class="review-delete" type="submit">Delete Review</button>
                    </form>
                @elseif ($canReview)
                    <form class="review-form" method="POST" action="{{ route('buyer.products.reviews.store', ['product' => $product->id]) }}">
                        @csrf
                        <h3>Write a Review</h3>
                        <div class="star-input" aria-label="Choose a rating">
                            @for ($star = 5; $star >= 1; $star--)
                                <input type="radio" id="rating-{{ $star }}" name="rating" value="{{ $star }}" @checked((int) old('rating') === $star)>
                                <label for="rating-{{ $star }}">★</label>
                            @endfor
                        </div>
                        <textarea class="review-textarea" name="review" maxlength="2000" placeholder="Share your experience with this product...">{{ old('review') }}</textarea>
                        <div class="review-actions">
                            <button class="review-submit" type="submit">Submit Review</button>
                        </div>
                    </form>
                @else
                    <p class="review-note">Only buyers who have received this product can leave a review.</p>
                @endif
            </div>
            <div class="tab-panel" id="shipping">Shipping and return information will be shown according to the seller and checkout options.</div>
            @if (! empty($shopProfile['seller']))
                <section class="shop-profile" aria-labelledby="shopProfileTitle">
                    <h2 id="shopProfileTitle">Shop Profile</h2>
                    <div class="shop-box">
                        <div>
                            <div class="shop-head">
                                <div class="shop-avatar" aria-hidden="true">
                                    @if (! empty($shopProfile['avatar']))
                                        <img src="{{ $shopProfile['avatar'] }}" alt="">
                                    @else
                                        <span>{{ $shopProfile['initials'] }}</span>
                                    @endif
                                </div>
                                <div>
                                    <div class="shop-name">
                                        <span>{{ $shopProfile['name'] }}</span>
                                        @if (! empty($shopProfile['verified']))
                                            <span class="seller-badge">Verified Seller</span>
                                        @endif
                                    </div>
                                    @if (! empty($shopProfile['location']))
                                        <div class="shop-location">{{ $shopProfile['location'] }}</div>
                                    @endif
                                </div>
                            </div>
                            <p class="shop-description">{{ $shopProfile['description'] }}</p>
                            <div class="shop-actions">
                                @if (! empty($shopProfile['url']))
                                    <a class="shop-action" href="{{ $shopProfile['url'] }}">Visit Shop</a>
                                @endif
                                <button class="shop-action secondary" type="button" disabled title="Buyer-to-seller chat is not available yet.">Chat Seller</button>
                                <button class="shop-action secondary" type="button" disabled title="Shop following is not available yet.">Follow Shop</button>
                            </div>
                        </div>
                        <div class="shop-stats" aria-label="Shop statistics">
                            <div class="shop-stat">
                                <strong>{{ $shopProfile['rating_average'] !== null ? number_format($shopProfile['rating_average'], 1) : 'No ratings' }}</strong>
                                <span>{{ number_format((int) $shopProfile['review_count']) }} {{ (int) $shopProfile['review_count'] === 1 ? 'review' : 'reviews' }}</span>
                            </div>
                            <div class="shop-stat">
                                <strong>{{ number_format((int) $shopProfile['active_products']) }}</strong>
                                <span>Active products</span>
                            </div>
                            <div class="shop-stat">
                                <strong>{{ number_format((int) $shopProfile['sold_count']) }}</strong>
                                <span>Products sold</span>
                            </div>
                            <div class="shop-stat">
                                <strong>{{ $shopProfile['joined'] ?? 'Not available' }}</strong>
                                <span>Seller since</span>
                            </div>
                        </div>
                    </div>
                    <div class="shop-products">
                        <h3>More from this shop</h3>
                        @if (($moreFromSeller ?? collect())->count())
                            <div class="related-grid">
                                @foreach ($moreFromSeller as $sellerProduct)
                                    @php
                                        $sellerProductRating = round((float) ($sellerProduct->reviews_avg_rating ?? 0), 1);
                                        $sellerProductCount = (int) ($sellerProduct->reviews_count ?? 0);
                                        $sellerProductDiscount = (float) ($sellerProduct->discount_percent ?? 0);
                                        $sellerProductPrice = (float) $sellerProduct->price;
                                        $sellerProductFinalPrice = $sellerProductDiscount > 0 ? $sellerProductPrice * (1 - ($sellerProductDiscount / 100)) : $sellerProductPrice;
                                    @endphp
                                    <a class="related-card" href="{{ route('shop.product', ['id' => $sellerProduct->id]) }}">
                                        <div class="related-image"><img src="{{ $sellerProduct->image_url }}" alt="{{ $sellerProduct->name }}" loading="lazy" onerror="this.onerror=null;this.src='{{ asset('images/product-placeholder.png') }}';"></div>
                                        <div class="related-name">{{ $sellerProduct->name }}</div>
                                        <div class="rating"><span class="stars">@for ($star = 1; $star <= 5; $star++)<span class="{{ $star <= (int) round($sellerProductRating) ? 'filled' : 'empty' }}">&#9733;</span>@endfor</span> <span>{{ number_format($sellerProductRating, 1) }} ({{ $sellerProductCount }})</span></div>
                                        <div class="related-price">&#8369;{{ number_format($sellerProductFinalPrice, 2) }}</div>
                                    </a>
                                @endforeach
                            </div>
                        @else
                            <p class="shop-empty">No other active products from this shop yet.</p>
                        @endif
                    </div>
                </section>
            @endif
            @if ($relatedProducts->count())
                <div class="related"><h2>You may also like</h2><div class="related-grid">
                    @foreach ($relatedProducts as $related)
                        @php
                            $relatedRating = round((float) ($related->reviews_avg_rating ?? 0), 1);
                            $relatedCount = (int) ($related->reviews_count ?? 0);
                        @endphp
                        <a class="related-card" href="{{ route('shop.product', ['id' => $related->id]) }}"><div class="related-image"><img src="{{ $related->image_url }}" alt="{{ $related->name }}" loading="lazy" onerror="this.onerror=null;this.src='{{ asset('images/product-placeholder.png') }}';"></div><div class="related-name">{{ $related->name }}</div><div class="rating"><span class="stars">@for ($star = 1; $star <= 5; $star++)<span class="{{ $star <= (int) round($relatedRating) ? 'filled' : 'empty' }}">★</span>@endfor</span> <span>{{ number_format($relatedRating, 1) }} ({{ $relatedCount }})</span></div><div class="related-price">&#8369;{{ number_format((float) $related->price, 2) }}</div></a>
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
    const buyNowQuantityInput = document.getElementById('buy-now-quantity');
    const maxStock = {{ max(1, (int) ($product->stock ?? 0)) }};
    function setQuantity(value) {
        const quantity = Math.max(1, Math.min(maxStock, Number(value) || 1));
        output.textContent = String(quantity);
        quantityInput.value = String(quantity);
        if (buyNowQuantityInput) buyNowQuantityInput.value = String(quantity);
    }
    document.getElementById('quantityMinus')?.addEventListener('click', () => setQuantity(Number(output.textContent) - 1));
    document.getElementById('quantityPlus')?.addEventListener('click', () => setQuantity(Number(output.textContent) + 1));
    document.querySelectorAll('[data-tab]').forEach(tab => tab.addEventListener('click', () => {
        document.querySelectorAll('[data-tab], .tab-panel').forEach(item => item.classList.remove('active'));
        tab.classList.add('active');
        document.getElementById(tab.dataset.tab)?.classList.add('active');
    }));
    document.querySelectorAll('[data-open-reviews]').forEach(link => link.addEventListener('click', event => {
        event.preventDefault();
        document.querySelector('[data-tab="reviews"]')?.click();
        document.getElementById('reviews')?.scrollIntoView({ behavior: 'smooth', block: 'start' });
    }));
</script>
</body>
</html>
