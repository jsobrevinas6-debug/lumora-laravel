{{-- Replace the buyer shop page's current product price markup with this block. --}}
@php
    $discountPercent = (float) ($product->discount_percent ?? 0);
    $originalPrice = (float) $product->price;
    $finalPrice = $discountPercent > 0
        ? $originalPrice * (1 - ($discountPercent / 100))
        : $originalPrice;
@endphp

<div class="price-row">
    <span class="price">₱{{ number_format($finalPrice, 2) }}</span>
    @if ($discountPercent > 0)
        <span class="old-price">₱{{ number_format($originalPrice, 2) }}</span>
    @endif
</div>

@if ($discountPercent > 0)
    <span class="sale-badge">
        {{ rtrim(rtrim(number_format($discountPercent, 1), '0'), '.') }}% OFF
    </span>
@endif

<style>
    .price-row { display:flex; align-items:center; gap:8px; flex-wrap:wrap; }
    .old-price { color:#a99b9f; font-size:12px; text-decoration:line-through; font-weight:500; }
    .sale-badge { display:inline-block; margin-top:8px; padding:4px 8px; border-radius:999px; background:#b85c3b; color:#fff; font-size:10px; font-weight:800; letter-spacing:.04em; }
</style>
