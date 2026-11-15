@php
    $cartCount = session('lumora_cart') ? collect(session('lumora_cart'))->sum('quantity') : 0;
    $wishlistCount = $savedCount;
    $filtered = $filter !== 'all' || $selectedShop !== '';
@endphp
<!DOCTYPE html>
<html lang="{{ str_replace('_', '-', app()->getLocale()) }}">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <meta name="csrf-token" content="{{ csrf_token() }}">
    <title>Lumora | Wishlist</title>
    @vite(['resources/css/app.css', 'resources/js/app.js'])
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Playfair+Display:wght@500;600;700&family=Inter:wght@400;500;600;700&display=swap" rel="stylesheet">
</head>
<body class="wishlist-account-page">
<header class="profile-topbar">
    <div class="profile-topbar-inner">
        <button type="button" class="mobile-menu-button" data-profile-menu aria-label="Open account menu" aria-controls="wishlistAccountSidebar">
            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" aria-hidden="true"><path d="M4 6h16M4 12h16M4 18h16"/></svg>
        </button>
        <a href="{{ route('shop.index') }}" class="profile-logo" aria-label="Lumora shop"><span class="profile-logo-brand">LUM<span>O</span>RA</span><span class="profile-logo-tagline">Beauty lives here</span></a>
        <form action="{{ route('shop.index') }}" method="GET" class="topbar-search">
            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" aria-hidden="true"><circle cx="11" cy="11" r="7"/><path d="m21 21-4.3-4.3"/></svg>
            <input type="search" name="q" placeholder="Search Lumora" aria-label="Search Lumora">
        </form>
        <div class="topbar-actions">
            <a href="{{ route('buyer.wishlist.index') }}" class="topbar-action" aria-label="Wishlist" aria-current="page">
                <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.7" aria-hidden="true"><path d="M20.8 4.6a5.5 5.5 0 0 0-7.8 0L12 5.6l-1-1a5.5 5.5 0 0 0-7.8 7.8l1 1L12 21l7.8-7.6 1-1a5.5 5.5 0 0 0 0-7.8Z"/></svg>
                <span class="topbar-badge" data-wishlist-count @if ($wishlistCount < 1) hidden @endif>{{ $wishlistCount }}</span>
            </a>
            <a href="{{ route('buyer.cart') }}" class="topbar-action" aria-label="Cart">
                <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.7" aria-hidden="true"><circle cx="8" cy="21" r="1"/><circle cx="19" cy="21" r="1"/><path d="M2.1 2.1h3l2.7 12.4a2 2 0 0 0 2 1.6h7.8a2 2 0 0 0 2-1.6L21 7H6"/></svg>
                <span class="topbar-badge" data-cart-count @if ($cartCount < 1) hidden @endif>{{ $cartCount }}</span>
            </a>
        </div>
    </div>
</header>

<div class="drawer-backdrop" data-profile-backdrop></div>
<main class="profile-page wishlist-page">
    <div class="profile-layout">
        <div id="wishlistAccountSidebar">@include('profile.partials.account-sidebar', ['active' => 'wishlist'])</div>
        <section class="profile-content" aria-labelledby="wishlistTitle">
            <h1 class="profile-heading" id="wishlistTitle">Wishlist</h1>
            <p class="profile-description"><span data-wishlist-total>{{ $savedCount }}</span> saved items. Move your favorites to the cart whenever you are ready.</p>

            <div class="wishlist-toolbar">
                <label class="wishlist-select-label">Sort by
                    <select id="wishlistSort" aria-label="Sort wishlist">
                        <option value="recent" @selected($sort === 'recent')>Recently added</option>
                        <option value="price_asc" @selected($sort === 'price_asc')>Price low to high</option>
                        <option value="price_desc" @selected($sort === 'price_desc')>Price high to low</option>
                    </select>
                </label>
                <label class="wishlist-select-label">Shop
                    <select id="wishlistShop" aria-label="Filter by shop">
                        <option value="">All shops</option>
                        @foreach ($shops as $shop)
                            <option value="{{ $shop->id }}" @selected($selectedShop === (string) $shop->id)>{{ $shop->shop_name ?: $shop->name }}</option>
                        @endforeach
                    </select>
                </label>
                <button type="button" class="wishlist-add-all" data-wishlist-add-all @disabled($products->where('stock', '>', 0)->isEmpty())>Add all to cart</button>
            </div>

            <nav class="wishlist-filters" aria-label="Filter wishlist">
                @foreach (['all' => 'All', 'sale' => 'On sale', 'in_stock' => 'In stock', 'out_of_stock' => 'Out of stock'] as $key => $label)
                    <a href="{{ route('buyer.wishlist.index', array_filter(['filter' => $key === 'all' ? null : $key, 'shop' => $selectedShop ?: null, 'sort' => $sort !== 'recent' ? $sort : null])) }}" class="wishlist-filter {{ $filter === $key ? 'active' : '' }}" @if ($filter === $key) aria-current="page" @endif>{{ $label }}</a>
                @endforeach
            </nav>

            <div class="wishlist-skeleton-grid" id="wishlistLoading" aria-label="Loading saved products" aria-busy="true" hidden>
                @for ($skeleton = 0; $skeleton < 4; $skeleton++)
                    <div class="wishlist-skeleton-card"><div class="wishlist-skeleton-media"></div><div class="wishlist-skeleton-line short"></div><div class="wishlist-skeleton-line"></div><div class="wishlist-skeleton-line small"></div><div class="wishlist-skeleton-button"></div></div>
                @endfor
            </div>

            @if ($loadError)
                <section class="wishlist-empty wishlist-error-state" role="alert"><h2>We couldn’t load your wishlist</h2><p>Please try again in a moment.</p><button type="button" class="wishlist-browse-button" data-wishlist-retry>Retry</button></section>
            @elseif ($products->isNotEmpty())
                <div class="wishlist-grid" id="wishlistGrid">
                    @foreach ($products as $product)
                        @php
                            $discount = (float) $product->discount_percent;
                            $oldPrice = (float) $product->price;
                            $price = $discount > 0 ? $oldPrice * (1 - $discount / 100) : $oldPrice;
                            $shopName = $product->seller?->shop_name ?: ($product->seller?->approvedSellerApplication?->business_name ?: ($product->seller?->name ?: 'Lumora seller'));
                            $isNew = $product->created_at?->greaterThan(now()->subDays(30));
                        @endphp
                        <article class="wishlist-card" data-wishlist-card data-product-id="{{ $product->id }}">
                            <div class="wishlist-card-media">
                                <a href="{{ route('shop.product', ['id' => $product->id]) }}" aria-label="View {{ $product->name }}"><img src="{{ $product->image_url }}" alt="{{ $product->name }}" loading="lazy" onerror="this.onerror=null;this.src='{{ asset('images/product-placeholder.png') }}';"></a>
                                @if ($discount > 0)<span class="wishlist-sale-badge">-{{ rtrim(rtrim(number_format($discount, 1), '0'), '.') }}%</span>@endif
                                @if ($isNew)<span class="wishlist-new-badge">New</span>@endif
                                <button type="button" class="wishlist-remove" data-wishlist-remove aria-label="Remove {{ $product->name }} from wishlist" aria-pressed="true"><svg viewBox="0 0 24 24" fill="currentColor" aria-hidden="true"><path d="M20.8 4.6a5.5 5.5 0 0 0-7.8 0L12 5.6l-1-1a5.5 5.5 0 0 0-7.8 7.8l1 1L12 21l7.8-7.6 1-1a5.5 5.5 0 0 0 0-7.8Z"/></svg></button>
                            </div>
                            <div class="wishlist-card-copy">
                                <div class="wishlist-shop">{{ $shopName }}</div>
                                <a class="wishlist-product-name" href="{{ route('shop.product', ['id' => $product->id]) }}">{{ $product->name }}</a>
                                <div class="wishlist-rating">@if ($product->reviews_count > 0)★ {{ number_format((float) $product->reviews_avg_rating, 1) }} <span>({{ $product->reviews_count }})</span>@else No reviews yet @endif</div>
                                <div class="wishlist-price-line"><strong>₱{{ number_format($price, 2) }}</strong>@if ($discount > 0)<del>₱{{ number_format($oldPrice, 2) }}</del>@endif</div>
                                @if ((int) $product->stock > 0)
                                    <form method="POST" action="{{ route('buyer.cart.add', ['product' => $product->id]) }}" class="lumora-cart-form wishlist-cart-form" data-cart-product-name="{{ $product->name }}" data-cart-product-price="{{ $price }}" data-cart-product-image="{{ $product->image_url }}">
                                        @csrf<input type="hidden" name="quantity" value="1"><button class="wishlist-cart-button" type="submit">Add to Cart</button>
                                    </form>
                                @else
                                    <button class="wishlist-cart-button is-out" type="button" disabled>Out of stock</button>
                                    <p class="wishlist-stock-note">This item is currently unavailable.</p>
                                @endif
                            </div>
                        </article>
                    @endforeach
                </div>
            @else
                <section class="wishlist-empty" id="wishlistEmpty">
                    @if ($filtered)
                        <h2>No items match these filters</h2><p>Try another filter or browse your full wishlist.</p>
                        <a class="wishlist-browse-button" href="{{ route('buyer.wishlist.index') }}">Clear filters</a>
                    @else
                        <div class="wishlist-empty-heart" aria-hidden="true">♡</div><h2>Your wishlist is empty</h2><p>Tap the heart on any product to save it here.</p>
                        <a class="wishlist-browse-button" href="{{ route('shop.index') }}">Browse products</a>
                    @endif
                </section>
            @endif
        </section>
    </div>
</main>
<div class="wishlist-toast" id="wishlistToast" role="status" aria-live="polite"><span data-wishlist-toast-message></span><button type="button" data-wishlist-undo hidden>Undo</button></div>
@include('components.add-to-cart-success-modal')
@include('components.chat-widget')
</body>
</html>
