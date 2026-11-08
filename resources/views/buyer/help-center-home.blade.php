<!DOCTYPE html>
<html lang="{{ str_replace('_', '-', app()->getLocale()) }}">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <meta name="csrf-token" content="{{ csrf_token() }}">
    <title>Help Center | Lumora</title>
    @vite(['resources/css/app.css', 'resources/js/app.js'])
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Playfair+Display:wght@500;600;700&family=Inter:wght@400;500;600;700&display=swap" rel="stylesheet">
    <style>
        :root{--cream:#f5f1ec;--paper:#fff;--maroon:#4a1233;--rose:#c98b6b;--ink:#392932;--muted:#65585d;--line:#e8ded7}
        *{box-sizing:border-box}html{scroll-behavior:smooth}body{margin:0;background:var(--cream);color:var(--ink);font-family:Inter,ui-sans-serif,system-ui,sans-serif;font-size:14px;line-height:1.6}a{color:inherit;text-decoration:none}button,input{font:inherit}a:focus-visible,button:focus-visible,input:focus-visible,summary:focus-visible{outline:3px solid var(--rose);outline-offset:3px}
        .topbar{position:sticky;top:0;z-index:20;background:rgba(255,255,255,.97);border-bottom:1px solid var(--line);backdrop-filter:blur(12px)}.topbar-inner{width:min(1320px,calc(100% - 48px));min-height:82px;margin:auto;display:flex;align-items:center;gap:34px}.logo{display:flex;flex:0 0 auto;flex-direction:column;color:var(--maroon)}.logo-name{font:500 28px/1 'Playfair Display',Georgia,serif;letter-spacing:.28em}.logo-name span{color:var(--rose)}.logo-tagline{margin-top:5px;font-size:8px;letter-spacing:.36em;text-transform:uppercase;color:var(--muted)}.header-search{height:42px;display:flex;align-items:center;gap:10px;flex:1;max-width:570px;padding:0 15px;border:1px solid var(--line);border-radius:999px;background:#fff}.header-search svg{width:17px;color:var(--muted);flex:0 0 auto}.header-search input{width:100%;border:0;outline:0;background:transparent;color:var(--ink)}.header-search input:focus-visible{outline:none}.header-actions{display:flex;align-items:center;gap:11px;margin-left:auto}.icon-link{position:relative;width:40px;height:40px;display:grid;place-items:center;border:1px solid var(--line);border-radius:50%;background:#fff;color:var(--maroon);transition:background .2s,border-color .2s,transform .2s}.icon-link:hover{background:#f9f0eb;border-color:var(--rose);transform:translateY(-1px)}.icon-link svg{width:19px;height:19px}.cart-count{position:absolute;top:-5px;right:-4px;min-width:17px;height:17px;padding:0 4px;display:grid;place-items:center;border-radius:99px;background:var(--rose);color:#fff;font-size:10px;font-weight:700}
        .sr-only{position:absolute;width:1px;height:1px;padding:0;margin:-1px;overflow:hidden;clip:rect(0,0,0,0);white-space:nowrap;border:0}.page{width:min(1120px,calc(100% - 48px));margin:0 auto;padding:24px 0 72px}.breadcrumb{display:flex;align-items:center;gap:9px;margin:0 0 20px;color:var(--muted);font-size:12px}.breadcrumb a{color:var(--maroon)}.breadcrumb a:hover{text-decoration:underline}.crumb-sep{color:#a38e85}
        .hero{padding:clamp(28px,5vw,58px);border:1px solid var(--line);border-radius:22px;background:linear-gradient(125deg,#fff 0%,#fff 68%,#fbf2ec 100%);box-shadow:0 12px 38px rgba(74,18,51,.045)}.eyebrow{color:#9c6048;font-size:11px;font-weight:700;letter-spacing:.2em;text-transform:uppercase}.hero h1{margin:10px 0 9px;color:var(--maroon);font:600 clamp(38px,5.3vw,60px)/1.08 'Playfair Display',Georgia,serif;letter-spacing:-.02em}.hero>p{margin:0;color:var(--muted);font-size:15px}.help-search-form{width:min(740px,100%);margin-top:28px}.help-search{min-height:58px;display:flex;align-items:center;gap:12px;padding:7px 8px 7px 18px;border:1px solid #d9c8bd;border-radius:999px;background:#fff;box-shadow:0 5px 18px rgba(74,18,51,.06);transition:border-color .2s,box-shadow .2s}.help-search:focus-within{border-color:var(--rose);box-shadow:0 0 0 4px rgba(201,139,107,.17)}.help-search svg{width:20px;height:20px;flex:0 0 auto;color:var(--rose)}.help-search input{min-width:0;flex:1;border:0;outline:0;background:transparent;color:var(--ink);font-size:14px}.help-search input::placeholder{color:#77696b;opacity:1}.help-search button,.primary-button{min-height:42px;padding:0 20px;border:1px solid var(--maroon);border-radius:999px;background:var(--maroon);color:#fff;font-size:13px;font-weight:700;cursor:pointer;transition:background .2s,transform .2s}.help-search button:hover,.primary-button:hover{background:#351025;transform:translateY(-1px)}.search-status{min-height:22px;margin:8px 0 0 20px;color:var(--muted);font-size:12px}.search-status a{color:var(--maroon);font-weight:700;text-decoration:underline}
        .section{margin-top:48px}.section-heading{display:flex;align-items:end;justify-content:space-between;gap:18px;margin-bottom:18px}.section-heading h2{margin:0;color:var(--maroon);font:600 30px/1.2 'Playfair Display',Georgia,serif}.section-heading p{margin:5px 0 0;color:var(--muted);font-size:13px}.text-link{color:var(--maroon);font-size:13px;font-weight:700;text-decoration:underline;text-decoration-color:#d8b39f;text-underline-offset:3px}.topic-grid{display:grid;grid-template-columns:repeat(3,minmax(0,1fr));gap:15px}.topic-card{min-height:148px;display:flex;align-items:flex-start;gap:15px;padding:22px;border:1px solid var(--line);border-radius:18px;background:var(--paper);box-shadow:0 4px 15px rgba(74,18,51,.035);transition:transform .2s,border-color .2s,box-shadow .2s}.topic-card:hover{transform:translateY(-3px);border-color:#d5aa93;box-shadow:0 12px 25px rgba(74,18,51,.09)}.topic-icon{width:44px;height:44px;display:grid;place-items:center;flex:0 0 44px;border-radius:14px;background:#f8eee8;color:var(--maroon)}.topic-icon svg{width:22px;height:22px}.topic-copy{min-width:0}.topic-copy h3{margin:1px 0 5px;color:var(--maroon);font-size:15px;font-weight:700}.topic-copy p{margin:0;color:var(--muted);font-size:12px;line-height:1.6}
        .topic-copy{display:grid;gap:5px}.topic-title{margin:1px 0 0;color:var(--maroon);font-size:15px;font-weight:700}.topic-description{color:var(--muted);font-size:12px;line-height:1.6}
        .faq-list{display:grid;gap:10px}.faq-item{overflow:hidden;border:1px solid var(--line);border-radius:15px;background:#fff}.faq-item[hidden]{display:none}.faq-item details{padding:0 21px}.faq-item summary{position:relative;padding:18px 38px 18px 0;color:var(--maroon);font-size:14px;font-weight:700;cursor:pointer;list-style:none}.faq-item summary::-webkit-details-marker{display:none}.faq-item summary:after{content:'+';position:absolute;right:2px;top:13px;color:var(--rose);font-size:23px;font-weight:400}.faq-item details[open] summary:after{content:'−'}.faq-answer{padding:0 0 15px;color:var(--muted);font-size:13px}.faq-answer p{margin:0 0 14px}.helpful{display:flex;align-items:center;gap:8px;font-size:11px}.helpful span{margin-right:3px;color:#65585d}.helpful button{min-height:29px;padding:0 11px;border:1px solid #d8c8be;border-radius:999px;background:#fff;color:var(--maroon);font-size:11px;font-weight:700;cursor:pointer;transition:background .2s,border-color .2s}.helpful button:hover{border-color:var(--rose);background:#fbf2ec}.no-results{padding:22px;border:1px dashed #cdb8ac;border-radius:14px;background:#fff;color:var(--muted)}.no-results[hidden]{display:none}
        .orders-strip{display:grid;grid-template-columns:repeat(3,minmax(0,1fr));gap:12px}.order-mini{display:flex;align-items:center;justify-content:space-between;gap:12px;padding:17px;border:1px solid var(--line);border-radius:15px;background:#fff}.order-number{display:block;color:var(--maroon);font-weight:700}.order-status{display:inline-flex;margin-top:7px;padding:4px 9px;border-radius:999px;background:#f5ece7;color:#694232;font-size:10px;font-weight:700}.track-link{flex:0 0 auto;color:var(--maroon);font-size:12px;font-weight:700;text-decoration:underline;text-underline-offset:3px}.contact-grid{display:grid;grid-template-columns:repeat(3,minmax(0,1fr));gap:15px}.contact-card{padding:22px;border:1px solid var(--line);border-radius:18px;background:#fff}.contact-card h3{margin:0 0 5px;color:var(--maroon);font:600 21px 'Playfair Display',Georgia,serif}.contact-card p{margin:0 0 14px;color:var(--muted);font-size:12px}.contact-meta{display:grid;gap:4px;color:#57494c;font-size:11px}.contact-card .text-link,.contact-card button{display:inline-flex;margin-top:16px}.contact-card button{min-height:38px;padding:0 15px;border:1px solid var(--maroon);border-radius:999px;background:var(--maroon);color:#fff;font-size:12px;font-weight:700;cursor:pointer}.banner{display:flex;align-items:center;justify-content:space-between;gap:22px;margin-top:48px;padding:28px 32px;border-radius:20px;background:var(--maroon);color:#fff}.banner h2{margin:0;font:600 29px/1.2 'Playfair Display',Georgia,serif}.banner p{margin:6px 0 0;color:#f1e5eb;font-size:13px}.banner .primary-button{flex:0 0 auto;border-color:#fff;background:#fff;color:var(--maroon)}.banner .primary-button:hover{background:#f6e9e2}
        .footer{border-top:1px solid var(--line);background:#fff}.footer-inner{width:min(1120px,calc(100% - 48px));min-height:88px;margin:auto;display:flex;align-items:center;justify-content:space-between;gap:20px;color:var(--muted);font-size:12px}.footer-links{display:flex;gap:18px;flex-wrap:wrap}.footer a:hover{color:var(--maroon);text-decoration:underline}
        @media(max-width:900px){.topbar-inner{gap:20px}.topic-grid{grid-template-columns:repeat(2,minmax(0,1fr))}.hero{padding:38px}.section{margin-top:40px}}
        @media(max-width:640px){.topbar-inner{width:calc(100% - 28px);min-height:70px;gap:12px;flex-wrap:wrap;padding:11px 0}.logo-name{font-size:23px;letter-spacing:.23em}.logo-tagline{font-size:7px;letter-spacing:.26em}.header-search{order:3;flex-basis:100%;max-width:none;height:40px}.header-actions{gap:7px}.icon-link{width:36px;height:36px}.page{width:calc(100% - 28px);padding:18px 0 48px}.breadcrumb{margin-bottom:14px}.hero{padding:27px 21px;border-radius:18px}.hero h1{font-size:39px}.hero>p{font-size:13px}.help-search-form{margin-top:21px}.help-search{min-height:54px;padding-left:13px;gap:8px}.help-search input{font-size:12px}.help-search input::placeholder{font-size:11px}.help-search button{min-height:38px;padding:0 13px;font-size:12px}.search-status{margin-left:6px}.section{margin-top:35px}.section-heading{align-items:flex-start;flex-direction:column;gap:8px}.section-heading h2{font-size:27px}.topic-grid,.contact-grid,.orders-strip{grid-template-columns:1fr}.topic-card{min-height:0;padding:18px}.topic-copy p{font-size:12px}.faq-item details{padding:0 16px}.faq-item summary{font-size:13px}.contact-card{padding:19px}.banner{align-items:flex-start;flex-direction:column;padding:25px 21px}.banner h2{font-size:27px}.footer-inner{width:calc(100% - 28px);align-items:flex-start;flex-direction:column;justify-content:center;padding:20px 0}.footer-links{gap:12px 17px}}
        @media(prefers-reduced-motion:reduce){*,*:before,*:after{scroll-behavior:auto!important;transition-duration:.01ms!important;animation-duration:.01ms!important}}
    </style>
</head>
<body>
@php($cartCount = collect(session('lumora_cart', []))->sum('quantity'))
<header class="topbar">
    <div class="topbar-inner">
        <a class="logo" href="{{ route('shop.index') }}" aria-label="Lumora home"><span class="logo-name">LUM<span>O</span>RA</span><span class="logo-tagline">Beauty lives here</span></a>
        <form class="header-search" action="{{ route('shop.index') }}" method="GET" role="search" aria-label="Search products">
            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" aria-hidden="true"><circle cx="11" cy="11" r="7"/><path d="m20 20-4-4"/></svg>
            <input type="search" name="q" placeholder="Search Lumora" aria-label="Search products">
        </form>
        <nav class="header-actions" aria-label="Account and shopping">
            <a class="icon-link" href="{{ auth()->check() ? route('profile.edit') . '#wishlist' : route('login') }}" aria-label="Wishlist"><svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.7" aria-hidden="true"><path d="M20.8 4.6a5.5 5.5 0 0 0-7.8 0L12 5.6l-1-1a5.5 5.5 0 0 0-7.8 7.8l1 1L12 21l7.8-7.6 1-1a5.5 5.5 0 0 0 0-7.8Z"/></svg></a>
            <a class="icon-link" href="{{ route('buyer.cart') }}" aria-label="Cart"><svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.7" aria-hidden="true"><circle cx="8" cy="21" r="1"/><circle cx="19" cy="21" r="1"/><path d="M2 3h3l2.6 12.4a2 2 0 0 0 2 1.6h8a2 2 0 0 0 2-1.6L21 7H6"/></svg>@if($cartCount)<span class="cart-count">{{ $cartCount }}</span>@endif</a>
        </nav>
    </div>
</header>

<main class="page">
    <nav class="breadcrumb" aria-label="Breadcrumb"><a href="{{ route('shop.index') }}">Home</a><span class="crumb-sep" aria-hidden="true">›</span><span aria-current="page">Help Center</span></nav>
    <section class="hero" aria-labelledby="help-title">
        <span class="eyebrow">Lumora Customer Care</span>
        <h1 id="help-title">How can we help?</h1>
        <p>Find quick answers about shopping, accounts, payments, and orders.</p>
        <form class="help-search-form" id="faqSearchForm" action="{{ route('help.center', 'faq') }}" method="GET" role="search">
            <div class="help-search"><label class="sr-only" for="faqSearchInput">Search popular questions and answers</label><svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" aria-hidden="true"><circle cx="11" cy="11" r="7"/><path d="m20 20-4-4"/></svg><input id="faqSearchInput" name="q" type="search" placeholder="Search for answers: returns, GCash, tracking…" autocomplete="off"><button type="submit">Search</button></div>
            <p class="search-status" id="faqSearchStatus" aria-live="polite"></p>
        </form>
    </section>

    <section class="section" aria-labelledby="topics-title">
        <div class="section-heading"><div><h2 id="topics-title">Browse by topic</h2><p>Choose a topic to find the right information.</p></div></div>
        <div class="topic-grid">
            @php($topics = [
                ['shipping','Shipping','Delivery estimates, couriers, and shipping updates.','M12 3v3m0 0 3-3m-3 3L9 3M5 10h14l-1.5 11h-11L5 10Zm3 0V7a4 4 0 0 1 8 0v3'],
                ['returns','Returns & Refunds','How to request a return or check a refund.','M4 7h12a4 4 0 0 1 0 8H8m0 0 4-4m-4 4 4 4M5 4v3'],
                ['tracking','Track Order','Follow your order status and parcel.','M3 6h11v12H3zM14 10h4l3 3v5h-7zM7 20a2 2 0 1 0 0-4 2 2 0 0 0 0 4Zm11 0a2 2 0 1 0 0-4 2 2 0 0 0 0 4Z'],
                ['size-guide','Size Guide','Find product sizes and choosing advice.','M4 16 16 4l4 4L8 20H4v-4Zm8-8 4 4m-8 4 4 4'],
                ['payments','Payments','Payment options, GCash, Maya, and COD.','M3 6h18v13H3zM3 10h18m-14 5h4'],
                ['contact','Contact Us','Reach the Lumora support team.','M4 5h16v12H9l-5 4V5Zm4 5h8m-8 4h5'],
                ['faq','FAQ','Answers to popular shopping questions.','M9.5 9a2.5 2.5 0 1 1 4.6 1.4c-.8 1.1-2.1 1.3-2.1 3.1M12 17.5v.1M12 22a10 10 0 1 0 0-20 10 10 0 0 0 0 20Z'],
            ])
            @foreach($topics as [$slug,$label,$description,$path])
                <a class="topic-card" href="{{ route('help.center', $slug) }}">
                    <span class="topic-icon" aria-hidden="true"><svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.6" stroke-linecap="round" stroke-linejoin="round"><path d="{{ $path }}"/></svg></span>
                    <span class="topic-copy"><span class="topic-title">{{ $label }}</span><span class="topic-description">{{ $description }}</span></span>
                </a>
            @endforeach
        </div>
    </section>

    <section class="section" id="popular-questions" aria-labelledby="faq-title">
        <div class="section-heading"><div><h2 id="faq-title">Popular questions</h2><p>Helpful answers to the things customers ask most.</p></div><a class="text-link" href="{{ route('help.center', 'faq') }}">View all FAQs <span aria-hidden="true">→</span></a></div>
        <div class="faq-list" id="faqList">
            @foreach($faqs as $index => $faq)
                <article class="faq-item" data-faq-item data-search="{{ strtolower($faq['question'].' '.$faq['answer']) }}">
                    <details><summary>{{ $faq['question'] }}</summary><div class="faq-answer"><p>{{ $faq['answer'] }}</p><div class="helpful"><span>Was this helpful?</span><button type="button" aria-label="Yes, this answer was helpful">Yes</button><button type="button" aria-label="No, this answer was not helpful">No</button></div></div></details>
                </article>
            @endforeach
        </div>
        <p class="no-results" id="faqNoResults" hidden>No matching popular questions. Press Enter or use <a class="text-link" href="{{ route('help.center', 'faq') }}">all FAQs</a> to continue searching.</p>
    </section>

    @auth
        <section class="section" aria-labelledby="orders-title">
            <div class="section-heading"><div><h2 id="orders-title">Your recent orders</h2><p>Quick access to your latest purchases.</p></div><a class="text-link" href="{{ route('buyer.orders.index') }}">My Orders <span aria-hidden="true">→</span></a></div>
            @if($recentOrders->isNotEmpty())
                <div class="orders-strip">
                    @foreach($recentOrders as $order)
                        <article class="order-mini"><div><span class="order-number">Order #{{ $order->order_number }}</span><span class="order-status">{{ $order->status_label }}</span></div><a class="track-link" href="{{ route('buyer.orders.show', $order) }}">Track <span aria-hidden="true">→</span></a></article>
                    @endforeach
                </div>
            @else
                <div class="no-results">No recent orders yet. <a class="text-link" href="{{ route('shop.index') }}">Browse the shop</a></div>
            @endif
        </section>
    @endauth

    <section class="section" aria-labelledby="contact-title">
        <div class="section-heading"><div><h2 id="contact-title">Talk to our team</h2><p>We’re here if you need a hand with anything else.</p></div></div>
        <div class="contact-grid">
            <article class="contact-card"><h3>Live chat</h3><p>Get help with shopping, orders, or your account.</p><div class="contact-meta"><span>Hours: Daily, 9:00 AM–6:00 PM</span><span>Typical reply: a few minutes</span></div>@auth<button type="button" data-open-support>Start a chat</button>@else<a class="text-link" href="{{ route('login') }}">Sign in to chat →</a>@endauth</article>
            <article class="contact-card"><h3>Messages</h3><p>Continue a conversation with Lumora Support.</p><div class="contact-meta"><span>Hours: Daily, 9:00 AM–6:00 PM</span><span>Typical reply: within 1 business day</span></div>@auth<a class="text-link" href="{{ route('buyer.chats.index') }}">Open messages →</a>@else<a class="text-link" href="{{ route('login') }}">Sign in to view messages →</a>@endauth</article>
            <article class="contact-card"><h3>Email</h3><p>Send us details and we’ll get back to you.</p><div class="contact-meta"><span>Hours: Daily, 9:00 AM–6:00 PM</span><span>Typical reply: within 1 business day</span></div><a class="text-link" href="mailto:{{ config('mail.from.address') }}">Email support →</a></article>
        </div>
    </section>

    <section class="banner" aria-labelledby="still-help-title"><div><h2 id="still-help-title">Still need help?</h2><p>Our customer care team is ready to help you find an answer.</p></div><a class="primary-button" href="{{ route('help.center', 'contact') }}">Contact us</a></section>
</main>

<footer class="footer"><div class="footer-inner"><span>© {{ date('Y') }} Lumora. Beauty lives here.</span><nav class="footer-links" aria-label="Footer"><a href="{{ route('help.center', 'help') }}">Help Center</a><a href="{{ route('help.center', 'shipping') }}">Shipping</a><a href="{{ route('help.center', 'returns') }}">Returns</a><a href="{{ route('about') }}">About Lumora</a></nav></div></footer>

<script>
(() => {
    const input = document.getElementById('faqSearchInput');
    const form = document.getElementById('faqSearchForm');
    const items = [...document.querySelectorAll('[data-faq-item]')];
    const status = document.getElementById('faqSearchStatus');
    const empty = document.getElementById('faqNoResults');
    let visibleCount = items.length;
    const filter = () => {
        const term = input.value.trim().toLocaleLowerCase();
        visibleCount = 0;
        items.forEach((item) => {
            const matches = !term || item.dataset.search.includes(term);
            item.hidden = !matches;
            if (matches) visibleCount++;
        });
        empty.hidden = visibleCount !== 0 || !term;
        status.textContent = term && visibleCount ? `${visibleCount} matching popular ${visibleCount === 1 ? 'question' : 'questions'}.` : '';
        if (term && !visibleCount) status.textContent = 'No popular questions match. Press Enter to search all FAQs.';
    };
    input.addEventListener('input', filter);
    form.addEventListener('submit', (event) => {
        if (input.value.trim() && visibleCount) {
            event.preventDefault();
            document.getElementById('popular-questions').scrollIntoView({behavior:'smooth', block:'start'});
            const first = items.find((item) => !item.hidden);
            first?.querySelector('summary')?.focus({preventScroll:true});
        }
    });
    document.querySelector('[data-open-support]')?.addEventListener('click', () => document.querySelector('.lumora-chat-fab')?.click());
})();
</script>
@auth @include('components.chat-widget') @endauth
</body>
</html>
