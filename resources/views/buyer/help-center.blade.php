<!DOCTYPE html>
<html lang="{{ str_replace('_', '-', app()->getLocale()) }}">
<head>
    <meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1">
    <title>{{ $title }} | Lumora</title>
    @vite(['resources/css/app.css', 'resources/js/app.js'])
    <link rel="preconnect" href="https://fonts.googleapis.com"><link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Playfair+Display:wght@500;600;700&family=Inter:wght@400;500;600;700&display=swap" rel="stylesheet">
    <style>
        body{margin:0;background:#f5f1ec;color:#392932;font-family:Inter, sans-serif}.help-wrap{max-width:1120px;margin:auto;padding:34px 24px 70px}.help-top{display:flex;align-items:center;justify-content:space-between;gap:16px}.help-top a{color:#4a1233;text-decoration:none;font-weight:600}.help-card{margin-top:36px;padding:clamp(24px,5vw,54px);border:1px solid #e7d9d2;border-radius:20px;background:#fffdfa}.help-eyebrow{color:#b96562;font-size:11px;font-weight:700;letter-spacing:.2em;text-transform:uppercase}.help-card h1{margin:10px 0 14px;color:#4a1233;font:600 clamp(34px,6vw,52px)/1.08 'Playfair Display',Georgia,serif}.help-card p{max-width:700px;color:#65585a;line-height:1.8}.help-actions{display:flex;flex-wrap:wrap;gap:12px;margin-top:26px}.help-actions a,.help-actions button{display:inline-flex;align-items:center;justify-content:center;min-height:46px;padding:0 20px;border:1px solid #c98b6b;border-radius:999px;background:#fff;color:#4a1233;text-decoration:none;font:600 13px Inter,sans-serif;cursor:pointer}.help-actions .primary{border-color:#4a1233;background:#4a1233;color:white}.help-links{display:flex;flex-wrap:wrap;gap:10px;margin-top:32px}.help-links a{padding:9px 13px;border-radius:999px;background:#f5ece7;color:#4a1233;text-decoration:none;font-size:12px;font-weight:600}.help-links a[aria-current=page]{background:#4a1233;color:white}
    </style>
</head>
<body>
<main class="help-wrap">
    <header class="help-top"><a href="{{ route('shop.index') }}" aria-label="Lumora home">LUMORA</a><a href="{{ route('shop.index') }}">Continue shopping →</a></header>
    <article class="help-card">
        <span class="help-eyebrow">Lumora Customer Care</span>
        <h1>{{ $title }}</h1>
        <p>{{ $description }}</p>
        <div class="help-actions">
            @if ($topic === 'returns' || $topic === 'tracking')
                <a class="primary" href="{{ auth()->check() ? route('buyer.orders.index') : route('login') }}">{{ auth()->check() ? 'Go to My Orders' : 'Sign in to view orders' }}</a>
            @elseif ($topic === 'contact')
                @auth<button class="primary" type="button" data-open-support>Chat with Lumora Support</button>@else<a class="primary" href="{{ route('login') }}">Sign in to contact support</a>@endauth
            @else
                <a class="primary" href="{{ route('shop.index') }}">Browse products</a>
            @endif
            <a href="{{ route('help.center', 'faq') }}">Visit FAQ</a>
        </div>
        <nav class="help-links" aria-label="Customer care topics">
            @foreach (['help' => 'Help Center', 'shipping' => 'Shipping', 'returns' => 'Returns', 'tracking' => 'Track Order', 'size-guide' => 'Size Guide', 'contact' => 'Contact Us', 'faq' => 'FAQ', 'payments' => 'Payments'] as $key => $label)
                <a href="{{ route('help.center', $key) }}" @if($topic === $key) aria-current="page" @endif>{{ $label }}</a>
            @endforeach
        </nav>
    </article>
    @if ($topic === 'faq' && filled($searchQuery ?? ''))
        <section aria-labelledby="faq-search-results" style="margin-top:28px;padding:28px;border:1px solid #e7d9d2;border-radius:20px;background:#fffdfa">
            <h2 id="faq-search-results" style="margin:0 0 16px;color:#4a1233;font:600 26px 'Playfair Display',Georgia,serif">Search results for “{{ $searchQuery }}”</h2>
            @forelse ($matchedFaqs as $faq)
                <details style="padding:14px 0;border-top:1px solid #e7d9d2">
                    <summary style="color:#4a1233;font-weight:700;cursor:pointer">{{ $faq['question'] }}</summary>
                    <p style="margin:10px 0 0;color:#65585a;line-height:1.8">{{ $faq['answer'] }}</p>
                </details>
            @empty
                <p style="color:#65585a">No matching answers found. Try a shorter search or browse the topics above.</p>
            @endforelse
        </section>
    @endif
</main>
@auth
    @include('components.chat-widget')
    <script>document.querySelector('[data-open-support]')?.addEventListener('click',()=>document.querySelector('.lumora-chat-fab')?.click());</script>
@endauth
</body>
</html>
