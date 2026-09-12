<!DOCTYPE html>
<html lang="{{ str_replace('_', '-', app()->getLocale()) }}">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <meta name="csrf-token" content="{{ csrf_token() }}">
    <title>About Lumora | {{ config('app.name', 'Lumora') }}</title>
    @vite(['resources/css/app.css', 'resources/js/app.js'])
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Playfair+Display:wght@500;600;700&family=Inter:wght@400;500;600;700&display=swap" rel="stylesheet">
</head>
<body id="top" class="min-h-screen bg-[#FFFDFB] text-[#3A2E30] antialiased">
    <header class="sticky top-0 z-30 border-b border-[#EBDDD8] bg-[#FFFDFB]/95 shadow-[0_4px_18px_rgba(61,27,61,0.04)] backdrop-blur-md">
        <div class="mx-auto flex max-w-[1240px] items-center gap-4 px-6 py-4 lg:gap-6">
            <a href="{{ route('shop.index') }}" aria-label="Open shop by collection" class="grid h-[38px] w-[38px] shrink-0 place-items-center rounded-full border border-[#B96562] bg-[#FFFDFB] text-[#3D1B3D] transition-all duration-300 hover:-translate-y-0.5 hover:bg-[#3D1B3D] hover:text-white">
                <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" class="h-[18px] w-[18px]" aria-hidden="true"><path d="M4 7h16M4 12h16M4 17h16"/></svg>
            </a>

            <x-logo :href="route('shop.index')" aria-label="Lumora shop" />

            <form action="{{ route('shop.index') }}" method="GET" class="hidden max-w-[520px] flex-1 items-center gap-2 rounded-full border border-[#EBDDD8] bg-[#FFFDFB] px-4 py-2.5 text-[#8A7B7E] md:flex">
                <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" class="h-4 w-4 shrink-0" aria-hidden="true"><circle cx="11" cy="11" r="7"/><path d="m21 21-4.3-4.3"/></svg>
                <input type="text" name="q" placeholder="Search skincare, makeup, fragrance..." class="w-full border-0 bg-transparent p-0 text-sm text-[#3A2E30] placeholder:text-[#8A7B7E] focus:ring-0">
            </form>

            <nav class="ml-auto flex items-center gap-3" aria-label="Primary">
                <a href="#" aria-label="Wishlist" class="grid h-[38px] w-[38px] place-items-center rounded-full border border-[#EBDDD8] bg-[#FFFDFB] text-[#3D1B3D] transition-all duration-300 hover:-translate-y-0.5 hover:bg-[#3D1B3D] hover:text-white">
                    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" class="h-[18px] w-[18px]" aria-hidden="true"><path d="M20.8 4.6a5.5 5.5 0 0 0-7.8 0L12 5.6l-1-1a5.5 5.5 0 0 0-7.8 7.8l1 1L12 21l7.8-7.6 1-1a5.5 5.5 0 0 0 0-7.8Z"/></svg>
                </a>
                @auth
                    <a href="{{ route('buyer.cart') }}" aria-label="Cart" class="relative grid h-[38px] w-[38px] place-items-center rounded-full border border-[#EBDDD8] bg-[#FFFDFB] text-[#3D1B3D] transition-all duration-300 hover:-translate-y-0.5 hover:bg-[#3D1B3D] hover:text-white">
                        <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" class="h-[18px] w-[18px]" aria-hidden="true"><circle cx="9" cy="21" r="1"/><circle cx="19" cy="21" r="1"/><path d="M2.5 3h2l2.7 12.4a2 2 0 0 0 2 1.6h8.6a2 2 0 0 0 2-1.6L21.5 7H6"/></svg>
                        <span class="absolute -right-1 -top-1 grid h-4 w-4 place-items-center rounded-full bg-[#E2703A] text-[10px] font-semibold text-white">{{ session('lumora_cart') ? collect(session('lumora_cart'))->sum('quantity') : 0 }}</span>
                    </a>
                @else
                    <a href="{{ route('login') }}" class="hidden rounded-full border border-[#EBDDD8] bg-[#FFFDFB] px-5 py-2 text-sm font-semibold text-[#3D1B3D] transition-all duration-300 hover:bg-[#FBEFEA] hover:text-[#B96562] sm:inline-flex">Login</a>
                    <a href="{{ route('register') }}" class="rounded-full border border-[#B96562] bg-[#FFFDFB] px-5 py-2 text-sm font-semibold text-[#3D1B3D] transition-all duration-300 hover:-translate-y-0.5 hover:bg-white">Sign Up</a>
                @endauth
            </nav>
        </div>
    </header>

    <main>
        <section class="mx-auto grid max-w-[1240px] items-center gap-10 px-6 py-16 lg:grid-cols-[1fr_0.9fr] lg:py-24">
            <div>
                <p class="mb-4 text-xs font-bold uppercase tracking-[0.22em] text-[#B96562]">ABOUT LUMORA</p>
                <h1 class="font-serif text-5xl font-semibold leading-[1.02] text-[#3D1B3D] md:text-6xl lg:text-7xl">More than beauty,<br>a brighter you.</h1>
                <p class="mt-6 max-w-xl text-base leading-8 text-[#8A7B7E] md:text-lg">At Lumora, we believe beauty is more than appearance. We carefully curate quality skincare, makeup, fragrances, and lifestyle essentials that help people feel confident every day.</p>
                <a href="#our-story" class="mt-8 inline-flex min-h-12 items-center rounded-[5px] border border-[#B96562] bg-[#FFFDFB] px-6 text-sm font-bold uppercase tracking-[0.08em] text-[#3D1B3D] transition-all duration-300 hover:-translate-y-0.5 hover:bg-white">Our Story &rarr;</a>
            </div>
            <div class="overflow-hidden rounded-3xl border border-[#EBDDD8] bg-[#FFF8F3] shadow-[0_8px_30px_rgba(61,27,61,0.035)]">
                <img src="{{ asset('images/hero.jpg') }}" alt="Lumora beauty collection" class="h-[360px] w-full object-cover md:h-[480px]">
            </div>
        </section>

        <section id="our-story" class="mx-auto max-w-[1040px] px-6 py-12">
            <p class="mb-3 text-xs font-bold uppercase tracking-[0.22em] text-[#B96562]">Our Story</p>
            <h2 class="font-serif text-4xl font-semibold text-[#3D1B3D] md:text-5xl">Our Story</h2>
            <p class="mt-6 text-base leading-8 text-[#8A7B7E]">Lumora is a modern online beauty and lifestyle destination created for customers who value quality, confidence, and ease. Our platform brings together carefully selected skincare, makeup, fragrance, body care, and everyday essentials in one refined shopping experience. From the first product search to checkout, Lumora is designed to feel calm, reliable, and beautifully simple, making premium online shopping more accessible for every customer.</p>
        </section>

        <section class="mx-auto grid max-w-[1240px] gap-5 px-6 py-12 lg:grid-cols-2">
            <article class="rounded-3xl border border-[#EBDDD8] bg-[#FFFAF5] p-8 shadow-[0_8px_30px_rgba(61,27,61,0.035)]">
                <h2 class="font-serif text-3xl font-semibold text-[#3D1B3D]">Mission Statement</h2>
                <p class="mt-5 text-sm leading-7 text-[#8A7B7E]">At Lumora, our mission is to make beauty accessible, inspiring, and enjoyable for everyone. We are committed to offering carefully selected beauty, skincare, makeup, and lifestyle products that help our customers feel confident and express their unique style. Through quality products, excellent customer service, and a seamless shopping experience, we aim to bring beauty closer to every home.</p>
            </article>
            <article class="rounded-3xl border border-[#EBDDD8] bg-[#FFFAF5] p-8 shadow-[0_8px_30px_rgba(61,27,61,0.035)]">
                <h2 class="font-serif text-3xl font-semibold text-[#3D1B3D]">Vision Statement</h2>
                <p class="mt-5 text-sm leading-7 text-[#8A7B7E]">Our vision is to become one of the most trusted online beauty destinations by providing high-quality products, exceptional customer experiences, and innovative digital shopping solutions. We strive to empower individuals to embrace their beauty with confidence while continuously growing as a modern customer-focused e-commerce platform.</p>
            </article>
        </section>

        <section class="mx-auto max-w-[1240px] px-6 py-12">
            <div class="mb-8 text-center">
                <h2 class="font-serif text-4xl font-semibold text-[#3D1B3D]">Core Values</h2>
                <p class="mt-3 text-sm text-[#8A7B7E]">The principles that guide every Lumora experience.</p>
            </div>
            <div class="grid gap-4 sm:grid-cols-2 lg:grid-cols-5">
                @foreach ([
                    ['title' => 'Customer First', 'text' => 'We design every interaction around comfort, trust, and care.', 'icon' => 'heart'],
                    ['title' => 'Quality', 'text' => 'We curate products with attention to value, function, and feel.', 'icon' => 'check'],
                    ['title' => 'Integrity', 'text' => 'We value honest service and transparent customer relationships.', 'icon' => 'shield'],
                    ['title' => 'Innovation', 'text' => 'We keep improving the platform with thoughtful digital solutions.', 'icon' => 'spark'],
                    ['title' => 'Excellence', 'text' => 'We aim for polished details across service, design, and delivery.', 'icon' => 'gem'],
                ] as $value)
                    <article class="h-full rounded-3xl border border-[#EBDDD8] bg-[#FFFAF5] p-6 shadow-[0_8px_30px_rgba(61,27,61,0.035)] transition-all duration-300 hover:-translate-y-1 hover:border-[#B96562]/50 hover:shadow-[0_14px_34px_rgba(61,27,61,0.07)]">
                        <div class="mb-5 grid h-11 w-11 place-items-center rounded-full border border-[#EBDDD8] text-[#B96562]">
                            @if ($value['icon'] === 'heart')
                                <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.7" class="h-5 w-5" aria-hidden="true"><path d="M20.8 4.6a5.5 5.5 0 0 0-7.8 0L12 5.6l-1-1a5.5 5.5 0 0 0-7.8 7.8l1 1L12 21l7.8-7.6 1-1a5.5 5.5 0 0 0 0-7.8Z"/></svg>
                            @elseif ($value['icon'] === 'check')
                                <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.7" class="h-5 w-5" aria-hidden="true"><path d="m5 12 4 4L19 6"/></svg>
                            @elseif ($value['icon'] === 'shield')
                                <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.7" class="h-5 w-5" aria-hidden="true"><path d="M12 3 5 6v5c0 4.4 2.8 8 7 10 4.2-2 7-5.6 7-10V6z"/></svg>
                            @elseif ($value['icon'] === 'spark')
                                <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.7" class="h-5 w-5" aria-hidden="true"><path d="M12 3v4M12 17v4M3 12h4M17 12h4M5.6 5.6l2.8 2.8M15.6 15.6l2.8 2.8M18.4 5.6l-2.8 2.8M8.4 15.6l-2.8 2.8"/></svg>
                            @else
                                <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.7" class="h-5 w-5" aria-hidden="true"><path d="m6 3 12 0 3 6-9 12L3 9z"/><path d="M3 9h18M9 3 7 9l5 12 5-12-2-6"/></svg>
                            @endif
                        </div>
                        <h3 class="font-serif text-xl font-semibold text-[#3D1B3D]">{{ $value['title'] }}</h3>
                        <p class="mt-3 text-sm leading-6 text-[#8A7B7E]">{{ $value['text'] }}</p>
                    </article>
                @endforeach
            </div>
        </section>

        <section class="mx-auto max-w-[1240px] px-6 py-12">
            <div class="grid gap-8 rounded-3xl border border-[#EBDDD8] bg-[#FFFAF5] p-8 shadow-[0_8px_30px_rgba(61,27,61,0.035)] lg:grid-cols-2 lg:p-10">
                @foreach ([
                    'Short-Term Goals' => ['Build a user-friendly website', 'Expand product collection', 'Secure payment methods', 'Reliable customer support'],
                    'Long-Term Goals' => ['Become one of the leading beauty e-commerce platforms', 'Partner with trusted beauty brands', 'Expand nationwide', 'Continuously innovate the platform'],
                ] as $heading => $goals)
                    <div>
                        <h2 class="font-serif text-3xl font-semibold text-[#3D1B3D]">{{ $heading }}</h2>
                        <ul class="mt-6 space-y-4">
                            @foreach ($goals as $goal)
                                <li class="flex gap-3 text-sm leading-6 text-[#8A7B7E]">
                                    <span class="mt-0.5 grid h-6 w-6 shrink-0 place-items-center rounded-full border border-[#EBDDD8] text-[#B96562]">
                                        <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" class="h-3.5 w-3.5" aria-hidden="true"><path d="m5 12 4 4L19 6"/></svg>
                                    </span>
                                    <span>{{ $goal }}</span>
                                </li>
                            @endforeach
                        </ul>
                    </div>
                @endforeach
            </div>
        </section>

        <section class="mx-auto max-w-[1240px] px-6 py-12" aria-labelledby="developersHeading">
            <div class="mb-8 text-center">
                <h2 id="developersHeading" class="font-serif text-4xl font-semibold text-[#3D1B3D]">Meet the Developers</h2>
                <p class="mt-3 text-sm text-[#8A7B7E]">The minds behind Lumora.</p>
            </div>
            <div class="grid items-stretch gap-5 md:grid-cols-2 lg:grid-cols-3">
                <article class="flex h-full flex-col items-center rounded-3xl border border-[#EBDDD8] bg-[#FFFAF5] p-8 text-center shadow-[0_8px_30px_rgba(61,27,61,0.035)] transition-all duration-300 hover:-translate-y-1 hover:border-[#B96562]/50 hover:shadow-[0_14px_34px_rgba(61,27,61,0.07)]">
                    <img src="{{ asset('images/Justin.jpg') }}" alt="Justin Sobreviñas" class="h-44 w-44 rounded-full border border-[#EADFD8] object-cover">
                    <h3 class="mt-6 font-serif text-2xl font-semibold text-[#3D1B3D]">Justin Sobreviñas</h3>
                    <p class="mt-2 text-xs font-bold uppercase tracking-[0.12em] text-[#8A7B7E]">Full-Stack Developer, Backend Developer & UI/UX Designer</p>
                    <p class="mt-5 text-sm leading-7 text-[#8A7B7E]">Justin is responsible for designing and developing the Lumora platform. He handles both frontend and backend development, builds responsive and user-friendly interfaces, designs the overall user experience, develops secure server-side functionality, manages system integration, and ensures a seamless shopping experience through clean architecture and efficient development.</p>
                </article>
                <article class="flex h-full flex-col items-center rounded-3xl border border-[#EBDDD8] bg-[#FFFAF5] p-8 text-center shadow-[0_8px_30px_rgba(61,27,61,0.035)] transition-all duration-300 hover:-translate-y-1 hover:border-[#B96562]/50 hover:shadow-[0_14px_34px_rgba(61,27,61,0.07)]">
                    <img src="{{ asset('images/Arron.jpg') }}" alt="Arron Balonzo" class="h-44 w-44 rounded-full border border-[#EADFD8] object-cover">
                    <h3 class="mt-6 font-serif text-2xl font-semibold text-[#3D1B3D]">Arron Balonzo</h3>
                    <p class="mt-2 text-xs font-bold uppercase tracking-[0.12em] text-[#8A7B7E]">Mobile Application Developer & Database Specialist</p>
                    <p class="mt-5 text-sm leading-7 text-[#8A7B7E]">Arron is responsible for developing the Lumora mobile application and managing the project's database architecture. He works on mobile application features, authentication, database management, API integration, and ensures the application runs smoothly, securely, and efficiently across supported devices.</p>
                </article>
                <article class="flex h-full flex-col items-center rounded-3xl border border-[#EBDDD8] bg-[#FFFAF5] p-8 text-center shadow-[0_8px_30px_rgba(61,27,61,0.035)] transition-all duration-300 hover:-translate-y-1 hover:border-[#B96562]/50 hover:shadow-[0_14px_34px_rgba(61,27,61,0.07)] md:col-span-2 lg:col-span-1">
                    <img src="{{ asset('images/Carl.jpg') }}" alt="Carl John Rubiles" class="h-44 w-44 rounded-full border border-[#EADFD8] object-cover">
                    <h3 class="mt-6 font-serif text-2xl font-semibold text-[#3D1B3D]">Carl John Rubiles</h3>
                    <p class="mt-2 text-xs font-bold uppercase tracking-[0.12em] text-[#8A7B7E]">Frontend Developer, Web Designer & Logistics Coordinator</p>
                    <p class="mt-5 text-sm leading-7 text-[#8A7B7E]">Carl is responsible for developing responsive user interfaces and improving the overall web experience. He also oversees logistics-related operations, including inventory coordination, order tracking, shipping workflow, and ensuring customer orders are processed accurately and delivered efficiently.</p>
                </article>
            </div>
        </section>

        <section class="mx-auto max-w-[1240px] px-6 py-14">
            <div class="rounded-3xl border border-[#EBDDD8] bg-[#FFFAF5] p-8 text-center shadow-[0_8px_30px_rgba(61,27,61,0.035)] md:p-12">
                <h2 class="font-serif text-4xl font-semibold text-[#3D1B3D] md:text-5xl">Be part of our journey.</h2>
                <p class="mx-auto mt-4 max-w-xl text-sm leading-7 text-[#8A7B7E]">Discover beauty that inspires confidence.</p>
                <a href="{{ route('shop.index') }}" class="mt-7 inline-flex min-h-12 items-center rounded-[5px] border border-[#B96562] bg-[#FFFDFB] px-6 text-sm font-bold uppercase tracking-[0.08em] text-[#3D1B3D] transition-all duration-300 hover:-translate-y-0.5 hover:bg-white">Explore Products &rarr;</a>
            </div>
        </section>
    </main>

    <footer class="mt-10 border-t border-[#EBDDD8] bg-[#FFF8F3] px-6 pb-8 pt-12">
        <div class="mx-auto max-w-[1240px]">
            <section class="mb-12 grid items-center gap-8 rounded-3xl border border-[#EBDDD8] bg-[#FFFAF5] p-8 md:grid-cols-[1fr_0.85fr]">
                <div>
                    <p class="mb-3 text-[11px] font-bold uppercase tracking-[0.22em] text-[#B96562]">JOIN LUMORA</p>
                    <h2 class="font-serif text-3xl font-semibold leading-tight text-[#3D1B3D] md:text-4xl">Be the first to know.</h2>
                    <p class="mt-3 max-w-md text-sm leading-7 text-[#8A7B7E]">Get exclusive offers, new arrivals, and beauty inspiration straight to your inbox.</p>
                </div>
                <form action="{{ route('shop.index') }}" method="GET" class="flex flex-col gap-3 sm:flex-row">
                    <label class="flex min-h-[38px] flex-1 items-center gap-2 rounded-full border border-[#EBDDD8] bg-[#FFFDFB] px-4 py-2.5 text-[#8A7B7E] focus-within:border-[#B96562] focus-within:ring-4 focus-within:ring-[#B96562]/10">
                        <span class="sr-only">Email address</span>
                        <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" class="h-4 w-4 shrink-0" aria-hidden="true"><path d="M4 6h16v12H4z"/><path d="m4 7 8 6 8-6"/></svg>
                        <input type="email" name="newsletter_email" placeholder="Enter your email" autocomplete="email" class="w-full border-0 bg-transparent p-0 text-sm text-[#3A2E30] placeholder:text-[#8A7B7E] focus:ring-0">
                    </label>
                    <button type="submit" class="min-h-[38px] rounded-full border border-[#B96562] bg-[#FFFDFB] px-5 text-sm font-semibold text-[#3D1B3D] transition-all duration-300 hover:-translate-y-0.5 hover:bg-white">Subscribe</button>
                </form>
            </section>

            <div class="grid gap-9 text-center md:grid-cols-2 md:text-left lg:grid-cols-[1.45fr_repeat(3,1fr)_1.35fr]">
                <div class="md:col-span-2 lg:col-span-1">
                    <x-logo :href="route('shop.index')" aria-label="Lumora home" class="mx-auto mb-4 items-center md:mx-0 md:items-start" />
                    <p class="mx-auto max-w-[220px] text-sm leading-7 text-[#8A7B7E] md:mx-0">Curated essentials for beauty,<br>confidence,<br>and the everyday.</p>
                    <div class="mt-5 flex flex-wrap justify-center gap-2 md:justify-start" aria-label="Social links">
                        <a href="#" aria-label="Instagram" class="grid h-[38px] w-[38px] place-items-center rounded-full border border-[#EBDDD8] bg-[#FFFDFB] text-[#3D1B3D] transition-all duration-300 hover:-translate-y-0.5 hover:bg-[#3D1B3D] hover:text-white">
                            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.6" class="h-[17px] w-[17px]" aria-hidden="true"><rect x="5" y="5" width="14" height="14" rx="4"/><circle cx="12" cy="12" r="3.2"/><circle cx="16.3" cy="7.8" r=".7" fill="currentColor" stroke="none"/></svg>
                        </a>
                        <a href="#" aria-label="Facebook" class="grid h-[38px] w-[38px] place-items-center rounded-full border border-[#EBDDD8] bg-[#FFFDFB] text-[#3D1B3D] transition-all duration-300 hover:-translate-y-0.5 hover:bg-[#3D1B3D] hover:text-white">
                            <svg viewBox="0 0 24 24" fill="currentColor" class="h-[17px] w-[17px]" aria-hidden="true"><path d="M14 8.2h2.2V5h-2.7C10.6 5 9 6.7 9 9.4V12H7v3.1h2V20h3.3v-4.9h2.8l.5-3.1h-3.3V9.7c0-.9.4-1.5 1.7-1.5Z"/></svg>
                        </a>
                        <a href="#" aria-label="Twitter" class="grid h-[38px] w-[38px] place-items-center rounded-full border border-[#EBDDD8] bg-[#FFFDFB] text-[#3D1B3D] transition-all duration-300 hover:-translate-y-0.5 hover:bg-[#3D1B3D] hover:text-white">
                            <svg viewBox="0 0 24 24" fill="currentColor" class="h-[17px] w-[17px]" aria-hidden="true"><path d="M18.9 5H21l-6.5 7.4 7.6 10.1h-6l-4.7-6.1-5.3 6.1H3.9l7-8-7.3-9.5h6.1l4.2 5.6L18.9 5Zm-.7 15.7h1.2L9 6.7H7.7l10.5 14Z"/></svg>
                        </a>
                    </div>
                </div>
                <nav aria-label="Shop">
                    <h3 class="mb-4 text-xs font-bold uppercase tracking-[0.08em] text-[#3D1B3D]">Shop</h3>
                    <ul class="grid gap-2.5 text-xs text-[#8A7B7E]">
                        <li><a class="transition-colors hover:text-[#B96562]" href="{{ route('shop.index') }}">All Products</a></li>
                        <li><a class="transition-colors hover:text-[#B96562]" href="{{ route('shop.index') }}?sort=top_sales">Best Sellers</a></li>
                        <li><a class="transition-colors hover:text-[#B96562]" href="{{ route('shop.index') }}?sort=latest">New Arrivals</a></li>
                        <li><a class="transition-colors hover:text-[#B96562]" href="{{ route('shop.index') }}?category=skincare">Skincare</a></li>
                        <li><a class="transition-colors hover:text-[#B96562]" href="{{ route('shop.index') }}?category=makeup">Makeup</a></li>
                        <li><a class="transition-colors hover:text-[#B96562]" href="{{ route('shop.index') }}?category=fragrance">Fragrance</a></li>
                        <li><a class="transition-colors hover:text-[#B96562]" href="{{ route('shop.index') }}?category=personal-care">Body Care</a></li>
                        <li><a class="transition-colors hover:text-[#B96562]" href="{{ route('shop.index') }}?category=bundles">Bundles</a></li>
                    </ul>
                </nav>
                <nav aria-label="Customer Care">
                    <h3 class="mb-4 text-xs font-bold uppercase tracking-[0.08em] text-[#3D1B3D]">Customer Care</h3>
                    <ul class="grid gap-2.5 text-xs text-[#8A7B7E]">
                        <li><a class="transition-colors hover:text-[#B96562]" href="#">Help Center</a></li>
                        <li><a class="transition-colors hover:text-[#B96562]" href="#">Shipping Information</a></li>
                        <li><a class="transition-colors hover:text-[#B96562]" href="#">Returns</a></li>
                        <li><a class="transition-colors hover:text-[#B96562]" href="#">Track Order</a></li>
                        <li><a class="transition-colors hover:text-[#B96562]" href="#">Size Guide</a></li>
                        <li><a class="transition-colors hover:text-[#B96562]" href="#">Contact Us</a></li>
                        <li><a class="transition-colors hover:text-[#B96562]" href="#">FAQ</a></li>
                    </ul>
                </nav>
                <nav aria-label="About Lumora">
                    <h3 class="mb-4 text-xs font-bold uppercase tracking-[0.08em] text-[#3D1B3D]">About Lumora</h3>
                    <ul class="grid gap-2.5 text-xs text-[#8A7B7E]">
                        <li><a class="transition-colors hover:text-[#B96562]" href="{{ route('about') }}">About Lumora &rarr;</a></li>
                    </ul>
                </nav>
                <div>
                    <h3 class="mb-4 text-xs font-bold uppercase tracking-[0.08em] text-[#3D1B3D]">We Accept</h3>
                    <div class="flex flex-wrap justify-center gap-2 md:justify-start">
                        <span class="grid h-10 min-w-[86px] place-items-center rounded-lg border border-[#EBDDD8] bg-[#FFFDFB] px-2.5">
                            <img src="{{ asset('images/payments/gcash.svg') }}" alt="GCash" class="block max-h-[25px] max-w-[72px] object-contain">
                        </span>
                        <span class="grid h-10 min-w-[86px] place-items-center rounded-lg border border-[#EBDDD8] bg-[#FFFDFB] px-2.5">
                            <img src="{{ asset('images/payments/maya.svg') }}" alt="Maya" class="block max-h-[25px] max-w-[72px] object-contain">
                        </span>
                    </div>
                    <div class="mt-5 grid gap-2.5 text-xs text-[#8A7B7E]">
                        <div class="flex items-center justify-center gap-2.5 md:justify-start">
                            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.7" class="h-4 w-4 shrink-0 text-[#B96562]" aria-hidden="true"><path d="M3 7h11v9H3z"/><path d="M14 10h4l3 3v3h-7z"/><circle cx="7" cy="18" r="1.5"/><circle cx="18" cy="18" r="1.5"/></svg>
                            <span>Free Shipping</span>
                        </div>
                        <div class="flex items-center justify-center gap-2.5 md:justify-start">
                            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.7" class="h-4 w-4 shrink-0 text-[#B96562]" aria-hidden="true"><path d="M7 7h10v10H7z"/><path d="M7 11 4 8l3-3"/><path d="M17 13l3 3-3 3"/></svg>
                            <span>Easy Returns</span>
                        </div>
                        <div class="flex items-center justify-center gap-2.5 md:justify-start">
                            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.7" class="h-4 w-4 shrink-0 text-[#B96562]" aria-hidden="true"><path d="M12 3 5 6v5c0 4.4 2.8 8 7 10 4.2-2 7-5.6 7-10V6z"/><path d="m9 12 2 2 4-4"/></svg>
                            <span>Secure Payment</span>
                        </div>
                    </div>
                </div>
            </div>
            <div class="mt-9 flex flex-col items-center justify-between gap-4 border-t border-[#EBDDD8] pt-5 text-xs text-[#8A7B7E] sm:flex-row">
                <p>&copy; 2026 Lumora. All rights reserved.</p>
                <a href="#top" aria-label="Back to top" class="grid h-[38px] w-[38px] place-items-center rounded-full border border-[#EBDDD8] bg-[#FFFDFB] text-[#3D1B3D] transition-all duration-300 hover:-translate-y-0.5 hover:bg-[#3D1B3D] hover:text-white">
                    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" class="h-4 w-4" aria-hidden="true"><path d="m6 14 6-6 6 6"/><path d="M12 8v12"/></svg>
                </a>
            </div>
        </div>
    </footer>
</body>
</html>
