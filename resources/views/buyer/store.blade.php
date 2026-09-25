<!DOCTYPE html>
<html lang="{{ str_replace('_', '-', app()->getLocale()) }}">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <meta name="csrf-token" content="{{ csrf_token() }}">
    <title>{{ $shopProfile['name'] }} &middot; {{ config('app.name', 'Lumora') }}</title>
    @vite(['resources/css/app.css', 'resources/js/app.js'])
    <style>
        :root { --cream:#fffaf7; --paper:#fffdfb; --line:#eadfe0; --plum:#3d1b3d; --rose:#b96562; --muted:#766a70; --green:#66945e; }
        * { box-sizing:border-box; }
        body { margin:0; background:var(--cream); color:var(--plum); font-family:Inter,ui-sans-serif,system-ui,sans-serif; }
        a { color:inherit; text-decoration:none; }
        .store-page { min-height:100vh; }
        .topbar { min-height:78px; display:flex; align-items:center; background:rgba(255,253,251,.98); border-bottom:1px solid var(--line); }
        .topbar-inner, .store-shell { width:min(1180px,calc(100% - 48px)); margin:auto; }
        .topbar-inner { display:flex; align-items:center; gap:18px; }
        .nav-link { margin-left:auto; color:var(--muted); font-size:13px; font-weight:800; }
        .store-shell { padding:28px 0 72px; }
        .breadcrumb { margin-bottom:20px; color:var(--muted); font-size:13px; }
        .breadcrumb a:hover { color:var(--rose); }
        .store-hero { padding:24px; border:1px solid var(--line); border-radius:14px; background:var(--paper); }
        .store-head { display:grid; grid-template-columns:88px 1fr; gap:18px; align-items:center; }
        .store-avatar { width:88px; height:88px; display:grid; place-items:center; overflow:hidden; border:1px solid var(--line); border-radius:50%; background:#f6eee9; color:var(--plum); font-family:Georgia,serif; font-size:30px; }
        .store-avatar img { width:100%; height:100%; object-fit:cover; }
        h1 { margin:0; font-family:Georgia,serif; font-size:38px; font-weight:500; line-height:1.08; }
        .seller-badge { display:inline-flex; align-items:center; min-height:22px; margin-left:8px; padding:0 8px; border-radius:999px; background:rgba(102,148,94,.13); color:var(--green); font-size:10px; font-weight:900; text-transform:uppercase; vertical-align:middle; }
        .location { margin-top:8px; color:var(--muted); font-size:13px; }
        .description { max-width:760px; margin:18px 0 0; color:var(--muted); font-size:14px; line-height:1.7; }
        .stats { display:grid; grid-template-columns:repeat(4,minmax(0,1fr)); gap:12px; margin-top:22px; }
        .stat { min-height:80px; padding:14px; border:1px solid var(--line); border-radius:8px; background:#FFFDFC; }
        .stat strong { display:block; color:var(--plum); font-size:21px; }
        .stat span { color:var(--muted); font-size:11px; font-weight:800; text-transform:uppercase; }
        .actions { display:flex; gap:10px; flex-wrap:wrap; margin-top:18px; }
        .action { min-height:42px; padding:0 15px; display:inline-flex; align-items:center; justify-content:center; border:1px solid var(--plum); border-radius:8px; background:var(--plum); color:white; font-size:12px; font-weight:800; cursor:pointer; }
        .action.secondary { background:white; color:var(--plum); }
        .action[disabled] { border-color:var(--line); background:#f6eee9; color:#9d8e93; cursor:not-allowed; }
        .products { margin-top:30px; }
        .products h2 { margin:0 0 16px; font-family:Georgia,serif; font-size:24px; font-weight:500; }
        .grid { display:grid; grid-template-columns:repeat(4,minmax(0,1fr)); gap:18px; }
        .card { min-width:0; }
        .image { height:190px; display:grid; place-items:center; overflow:hidden; border-radius:10px; background:linear-gradient(135deg,#f2dfd8,#e8c8be); }
        .image img { width:100%; height:100%; object-fit:cover; }
        .name { margin-top:10px; font-family:Georgia,serif; font-size:15px; }
        .rating { margin-top:6px; color:var(--muted); font-size:12px; }
        .stars .filled { color:#C98F72; }
        .stars .empty { color:#EAE3DD; }
        .price { margin-top:6px; color:var(--rose); font-size:14px; font-weight:800; }
        .empty-state { padding:28px; border:1px solid var(--line); border-radius:10px; background:var(--paper); color:var(--muted); }
        .pagination { margin-top:24px; }
        @media (max-width:900px) { .stats, .grid { grid-template-columns:repeat(2,minmax(0,1fr)); } }
        @media (max-width:620px) { .topbar-inner, .store-shell { width:min(100% - 28px,1180px); } .store-head { grid-template-columns:1fr; } h1 { font-size:32px; } .stats, .grid { grid-template-columns:1fr; } }
    </style>
</head>
<body>
<div class="store-page">
    <header class="topbar">
        <div class="topbar-inner">
            <x-logo :href="route('shop.index')" aria-label="Lumora shop" />
            <a class="nav-link" href="{{ route('shop.index') }}">Back to Shop</a>
        </div>
    </header>

    <main class="store-shell">
        <div class="breadcrumb"><a href="{{ route('shop.index') }}">Home</a> <span>&rsaquo;</span> <strong>{{ $shopProfile['name'] }}</strong></div>

        <section class="store-hero" aria-labelledby="storeTitle">
            <div class="store-head">
                <div class="store-avatar" aria-hidden="true">
                    @if (! empty($shopProfile['avatar']))
                        <img src="{{ $shopProfile['avatar'] }}" alt="">
                    @else
                        <span>{{ $shopProfile['initials'] }}</span>
                    @endif
                </div>
                <div>
                    <h1 id="storeTitle">
                        {{ $shopProfile['name'] }}
                        @if (! empty($shopProfile['verified']))
                            <span class="seller-badge">Verified Seller</span>
                        @endif
                    </h1>
                    @if (! empty($shopProfile['location']))
                        <div class="location">{{ $shopProfile['location'] }}</div>
                    @endif
                </div>
            </div>

            <p class="description">{{ $shopProfile['description'] }}</p>

            <div class="stats" aria-label="Shop statistics">
                <div class="stat">
                    <strong>{{ $shopProfile['rating_average'] !== null ? number_format($shopProfile['rating_average'], 1) : 'No ratings' }}</strong>
                    <span>{{ number_format((int) $shopProfile['review_count']) }} {{ (int) $shopProfile['review_count'] === 1 ? 'review' : 'reviews' }}</span>
                </div>
                <div class="stat">
                    <strong>{{ number_format((int) $shopProfile['active_products']) }}</strong>
                    <span>Active products</span>
                </div>
                <div class="stat">
                    <strong>{{ number_format((int) $shopProfile['sold_count']) }}</strong>
                    <span>Products sold</span>
                </div>
                <div class="stat">
                    <strong>{{ $shopProfile['joined'] ?? 'Not available' }}</strong>
                    <span>Seller since</span>
                </div>
            </div>

            <div class="actions">
                <button class="action secondary" type="button" disabled title="Buyer-to-seller chat is not available yet.">Chat Seller</button>
                <button class="action secondary" type="button" disabled title="Shop following is not available yet.">Follow Shop</button>
            </div>
        </section>

        <section class="products" aria-labelledby="productsTitle">
            <h2 id="productsTitle">Products from this shop</h2>
            @if ($products->count())
                <div class="grid">
                    @foreach ($products as $storeProduct)
                        @php
                            $productRating = round((float) ($storeProduct->reviews_avg_rating ?? 0), 1);
                            $productCount = (int) ($storeProduct->reviews_count ?? 0);
                            $discountPercent = (float) ($storeProduct->discount_percent ?? 0);
                            $originalPrice = (float) $storeProduct->price;
                            $finalPrice = $discountPercent > 0 ? $originalPrice * (1 - ($discountPercent / 100)) : $originalPrice;
                        @endphp
                        <a class="card" href="{{ route('shop.product', ['id' => $storeProduct->id]) }}">
                            <div class="image"><img src="{{ $storeProduct->image_url }}" alt="{{ $storeProduct->name }}" loading="lazy" onerror="this.onerror=null;this.src='{{ asset('images/product-placeholder.png') }}';"></div>
                            <div class="name">{{ $storeProduct->name }}</div>
                            <div class="rating"><span class="stars">@for ($star = 1; $star <= 5; $star++)<span class="{{ $star <= (int) round($productRating) ? 'filled' : 'empty' }}">&#9733;</span>@endfor</span> <span>{{ number_format($productRating, 1) }} ({{ $productCount }})</span></div>
                            <div class="price">&#8369;{{ number_format($finalPrice, 2) }}</div>
                        </a>
                    @endforeach
                </div>
                <div class="pagination">{{ $products->links() }}</div>
            @else
                <div class="empty-state">This shop has no active products yet.</div>
            @endif
        </section>
    </main>
</div>

@if (view()->exists('components.chat-widget'))
    @include('components.chat-widget')
@endif
</body>
</html>
