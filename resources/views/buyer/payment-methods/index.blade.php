@php
    $user = request()->user();
    $cartCount = session('lumora_cart') ? collect(session('lumora_cart'))->sum('quantity') : 0;

    $typeLabels = [
        'cod' => 'Cash on Delivery',
        'gcash' => 'GCash',
        'maya' => 'Maya',
        'bank_transfer' => 'Bank Transfer',
        'card_reference' => 'Card Reference',
    ];

    $methodIcon = function (string $type): string {
        return match ($type) {
            'cod' => '<path d="M4 7h16v10H4z"/><path d="M8 11h8"/><path d="M8 14h5"/>',
            'gcash', 'maya' => '<rect x="4" y="3" width="16" height="18" rx="3"/><path d="M9 7h6"/><path d="M10 17h4"/>',
            'bank_transfer' => '<path d="M3 10h18L12 4 3 10Z"/><path d="M5 10v8"/><path d="M9 10v8"/><path d="M15 10v8"/><path d="M19 10v8"/><path d="M3 18h18"/>',
            default => '<rect x="3" y="5" width="18" height="14" rx="2"/><path d="M3 10h18"/><path d="M7 15h4"/>',
        };
    };

    $maskedIdentifier = function ($method): string {
        if ($method->last_four) {
            return 'Ending in ' . $method->last_four;
        }

        if (! $method->account_identifier) {
            return 'Saved payment option';
        }

        $identifier = (string) $method->account_identifier;
        $tail = substr($identifier, -4);

        return strlen($identifier) > 4 ? 'Ending in ' . $tail : $identifier;
    };
@endphp

<!DOCTYPE html>
<html lang="{{ str_replace('_', '-', app()->getLocale()) }}">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <meta name="csrf-token" content="{{ csrf_token() }}">
    <title>Lumora | Payment Methods</title>
    @vite(['resources/css/app.css', 'resources/js/app.js'])
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Playfair+Display:wght@500;600;700&family=Inter:wght@400;500;600;700&display=swap" rel="stylesheet">
    <style>
        :root{--background:#F7F1EC;--card:#FFFDFC;--primary:#3B1E34;--accent:#C98F72;--border:#EAE3DD;--text:#2F2528;--muted:#8B7B78;--success:#6F8F78;--hover:#F8F4F1;--active:#F5ECE6;--shadow:0 10px 40px rgba(0,0,0,.04)}
        *{box-sizing:border-box}
        body{margin:0;background:var(--background);color:var(--text);font-family:Inter,ui-sans-serif,system-ui,sans-serif;font-size:16px;letter-spacing:0}
        h1,h2,h3{font-family:'Playfair Display',Georgia,serif;color:var(--primary);font-weight:600;letter-spacing:0}
        a{text-decoration:none;color:inherit}
        button,input,select,textarea{font:inherit}
        button{cursor:pointer}
        .profile-topbar{position:sticky;top:0;z-index:30;background:var(--card);border-bottom:1px solid var(--border)}
        .profile-topbar-inner{max-width:1480px;margin:0 auto;padding:15px 40px;display:flex;align-items:center;gap:24px}
        .topbar-search{flex:1;max-width:520px;min-height:40px;display:flex;align-items:center;gap:9px;border:1px solid var(--border);border-radius:999px;background:var(--card);padding:0 16px;color:var(--muted);font-size:13px}
        .topbar-search input{width:100%;border:0;background:transparent;outline:0;color:var(--text)}
        .topbar-search svg,.topbar-action svg{width:17px;height:17px}
        .topbar-actions{margin-left:auto;display:flex;align-items:center;gap:12px}
        .topbar-action{position:relative;width:38px;height:38px;display:grid;place-items:center;border:1px solid var(--border);border-radius:999px;background:var(--card);color:var(--primary);transition:background-color .2s ease,border-color .2s ease,color .2s ease}
        .topbar-badge{position:absolute;top:-5px;right:-5px;min-width:17px;height:17px;display:grid;place-items:center;border-radius:999px;background:var(--accent);color:var(--card);font-size:10px;font-weight:600}
        .mobile-menu-button{display:none;width:40px;height:40px;border:1px solid var(--border);border-radius:999px;background:var(--card);color:var(--primary)}
        .profile-logo{display:inline-flex;flex-direction:column;align-items:flex-start;justify-content:center;flex-shrink:0;color:var(--primary);transition:opacity .2s ease}
        .profile-logo-brand{font-family:'Playfair Display',Georgia,serif;font-size:31px;font-weight:500;line-height:1;text-transform:uppercase;letter-spacing:.32em;color:var(--primary)}
        .profile-logo-brand span{color:var(--accent)}
        .profile-logo-tagline{margin-top:4px;font-size:8px;font-weight:500;line-height:1;text-transform:uppercase;letter-spacing:.4em;color:var(--muted)}
        .profile-page{max-width:1680px;margin:0 auto;padding:48px 48px 72px}
        .profile-layout{display:grid;grid-template-columns:280px minmax(0,1fr);gap:40px;align-items:start}
        .profile-sidebar{position:sticky;top:110px;height:fit-content}
        .profile-sidebar-card{border:1px solid var(--border);border-radius:24px;background:var(--card);box-shadow:var(--shadow);padding:14px}
        .profile-nav{display:grid;gap:10px}
        .profile-nav-section{display:grid;gap:10px}
        .profile-nav-section + .profile-nav-section{margin-top:16px;padding-top:16px;border-top:1px solid var(--border)}
        .profile-nav-section-title{padding:4px 16px;color:var(--muted);font-size:11px;font-weight:800;letter-spacing:.16em;text-transform:uppercase}
        .profile-nav-item,.logout-nav-button{width:100%;height:54px;display:flex;align-items:center;gap:13px;border:0;border-left:4px solid transparent;border-radius:16px;background:transparent;padding:0 16px;color:var(--muted);font-size:14px;font-weight:600;text-align:left;transition:background-color .2s ease,border-color .2s ease,color .2s ease}
        .profile-nav-item.active{border-left-color:var(--accent);background:var(--active);color:var(--primary);box-shadow:inset 0 0 0 1px rgba(201,143,114,.16)}
        .profile-nav-icon{width:18px;height:18px;display:grid;place-items:center;flex:0 0 auto}
        .profile-nav-icon svg{width:17px;height:17px}
        .logout-nav-form{margin:8px 0 0;padding-top:10px;border-top:1px solid var(--border)}
        .payment-content{min-width:0;animation:fadeUp .2s ease both}
        .breadcrumb{display:flex;align-items:center;gap:9px;margin-bottom:18px;color:var(--muted);font-size:13px}
        .breadcrumb a{color:var(--primary);transition:color .2s ease}
        .account-label{margin:0 0 10px;color:var(--accent);font-size:11px;font-weight:700;letter-spacing:.18em;text-transform:uppercase}
        .payment-title{margin:0;font-size:58px;line-height:1}
        .payment-subtitle{max-width:540px;margin:14px 0 0;color:var(--muted);font-size:16px;line-height:1.7}
        .payment-header{margin-bottom:30px}
        .payment-grid{display:grid;grid-template-columns:minmax(0,1.15fr) minmax(360px,.85fr);gap:28px;align-items:start}
        .payment-panel{border:1px solid var(--border);border-radius:24px;background:var(--card);box-shadow:var(--shadow);padding:28px}
        .panel-head{display:flex;align-items:flex-start;justify-content:space-between;gap:18px;margin-bottom:24px;padding-bottom:18px;border-bottom:1px solid var(--border)}
        .panel-head h2{margin:0;font-size:30px;line-height:1.15}
        .panel-head p{margin:7px 0 0;color:var(--muted);font-size:13px;line-height:1.6}
        .add-anchor{min-height:40px;display:inline-flex;align-items:center;justify-content:center;border:1px solid var(--accent);border-radius:999px;background:var(--card);padding:0 16px;color:var(--primary);font-size:13px;font-weight:700;white-space:nowrap}
        .method-list{display:grid;gap:16px}
        .method-card{display:grid;grid-template-columns:auto minmax(0,1fr);gap:16px;border:1px solid var(--border);border-radius:18px;background:var(--card);padding:18px;transition:border-color .2s ease,background-color .2s ease,transform .2s ease}
        .method-icon{width:48px;height:48px;display:grid;place-items:center;border:1px solid var(--border);border-radius:999px;background:var(--background);color:var(--primary)}
        .method-icon svg{width:23px;height:23px}
        .method-main{min-width:0}
        .method-top{display:flex;align-items:center;gap:10px;flex-wrap:wrap}
        .method-type{color:var(--primary);font-size:15px;font-weight:800}
        .default-badge{min-height:24px;display:inline-flex;align-items:center;border:1px solid rgba(111,143,120,.22);border-radius:999px;background:rgba(111,143,120,.12);padding:0 9px;color:var(--success);font-size:11px;font-weight:800;text-transform:uppercase}
        .method-provider{margin:8px 0 0;color:var(--text);font-size:14px;font-weight:600}
        .method-identifier,.method-notes{margin:6px 0 0;color:var(--muted);font-size:13px;line-height:1.5}
        .method-actions{display:flex;align-items:center;gap:10px;flex-wrap:wrap;margin-top:16px}
        .method-actions form{margin:0}
        .text-button,.danger-button,.submit-button{min-height:38px;display:inline-flex;align-items:center;justify-content:center;border-radius:999px;padding:0 15px;font-size:13px;font-weight:700;transition:background-color .2s ease,border-color .2s ease,color .2s ease}
        .text-button{border:1px solid var(--border);background:var(--card);color:var(--primary)}
        .danger-button{border:1px solid rgba(201,143,114,.45);background:var(--card);color:var(--accent)}
        .submit-button{width:100%;min-height:50px;border:1px solid var(--primary);background:var(--primary);color:var(--card)}
        .empty-state{padding:46px 24px;text-align:center;border:1px dashed var(--border);border-radius:18px;background:var(--hover)}
        .empty-icon{width:72px;height:72px;display:grid;place-items:center;margin:0 auto 18px;border:1px solid var(--border);border-radius:999px;background:var(--card);color:var(--primary)}
        .empty-icon svg{width:34px;height:34px}
        .empty-state h2{margin:0;font-size:31px;line-height:1.15}
        .empty-state p{max-width:320px;margin:10px auto 0;color:var(--muted);font-size:14px;line-height:1.7}
        .payment-form{display:grid;gap:18px}
        .field{min-width:0}
        .field label,.checkbox-label{display:block;margin-bottom:8px;color:var(--muted);font-size:13px;font-weight:600}
        .input,.select,.textarea{width:100%;border:1px solid var(--border);border-radius:14px;background:var(--card);color:var(--text);font-size:15px;outline:0;transition:border-color .2s ease,box-shadow .2s ease,background-color .2s ease}
        .input,.select{height:48px;padding:0 14px}
        .textarea{min-height:98px;resize:vertical;padding:13px 14px;line-height:1.5}
        .input:focus,.select:focus,.textarea:focus{border-color:var(--accent);box-shadow:0 0 0 3px rgba(201,143,114,.16)}
        .field-error{display:block;margin-top:6px;color:var(--accent);font-size:13px;line-height:1.4}
        .checkbox-row{display:flex;align-items:center;gap:10px;border:1px solid var(--border);border-radius:14px;background:var(--hover);padding:13px 14px}
        .checkbox-row input{width:18px;height:18px;accent-color:var(--primary)}
        .checkbox-label{margin:0;color:var(--text)}
        .alert{margin-bottom:18px;border:1px solid var(--border);border-radius:14px;background:rgba(111,143,120,.12);padding:13px 16px;color:var(--success);font-size:13px;line-height:1.5}
        .drawer-backdrop{position:fixed;inset:0;z-index:40;display:none;background:rgba(47,37,40,.25)}
        .drawer-backdrop.open{display:block}
        .profile-page svg,.profile-topbar svg{stroke-width:1.75}
        @keyframes fadeUp{from{opacity:0;transform:translateY(8px)}to{opacity:1;transform:translateY(0)}}
        @media(hover:hover) and (pointer:fine){.topbar-action:hover,.text-button:hover,.add-anchor:hover{background:var(--hover);border-color:var(--accent)}.profile-nav-item:hover,.logout-nav-button:hover{background:var(--hover);color:var(--primary)}.method-card:hover{border-color:var(--accent);background:#FFF9F6;transform:translateY(-2px)}.danger-button:hover{background:var(--active)}.submit-button:hover{background:#4E2A47}}
        @media(prefers-reduced-motion:reduce){*,*::before,*::after{animation:none!important;transition:none!important}}
        @media(max-width:1399px){.profile-topbar-inner,.profile-page{padding-right:32px;padding-left:32px}.profile-layout{grid-template-columns:250px minmax(0,1fr);gap:28px}.payment-grid{grid-template-columns:1fr}.payment-title{font-size:50px}}
        @media(max-width:1023px) and (min-width:768px){.profile-layout{display:block}.profile-sidebar{position:static;width:100%;height:auto;margin-bottom:24px}.profile-sidebar-card{display:flex;align-items:center;overflow-x:auto;padding:10px;border-radius:20px}.profile-nav{display:flex;flex:0 0 auto;gap:10px;width:max-content}.profile-nav-section{display:flex;align-items:center;gap:10px}.profile-nav-section + .profile-nav-section{margin-top:0;margin-left:10px;padding-top:0;padding-left:14px;border-top:0;border-left:1px solid var(--border)}.profile-nav-section-title{display:none}.logout-nav-form{flex:0 0 auto;margin:0;padding:0;border:0}.profile-nav-item,.logout-nav-button{width:auto;min-width:max-content;height:50px;padding:0 16px;border-left:0}.profile-nav-item.active{box-shadow:inset 0 -3px 0 var(--accent)}.drawer-backdrop{display:none!important}}
        @media(max-width:767px){body{font-size:15px}.mobile-menu-button{display:grid;place-items:center}.topbar-search{display:none}.profile-topbar-inner{padding:13px 20px;gap:16px}.profile-logo-brand{font-size:24px;letter-spacing:.28em}.profile-logo-tagline{font-size:7px;letter-spacing:.32em}.profile-page{padding:24px 20px 48px}.profile-layout{display:block}.profile-sidebar{position:fixed;top:0;left:0;bottom:0;z-index:50;width:280px;height:100%;padding:0;background:var(--card);border-right:1px solid var(--border);transform:translateX(-105%);transition:transform .25s ease-out}.profile-sidebar.open{transform:translateX(0)}.profile-sidebar-card{height:100%;overflow-y:auto;border:0;border-radius:0;background:var(--card);padding:20px 12px}.profile-nav-item,.logout-nav-button{justify-content:flex-start;padding:0 15px;border-left:4px solid transparent}.profile-nav-item.active{box-shadow:none}.payment-title{font-size:42px}.payment-subtitle{font-size:15px}.payment-panel{padding:20px;border-radius:18px}.panel-head{align-items:stretch;flex-direction:column}.add-anchor{width:100%}.method-card{grid-template-columns:1fr}.method-icon{width:44px;height:44px}.method-actions{align-items:stretch;flex-direction:column}.method-actions form,.text-button,.danger-button{width:100%}.topbar-action:active,.profile-nav-item:active,.logout-nav-button:active{background:var(--active)}}
    </style>
</head>
<body>
<header class="profile-topbar">
    <div class="profile-topbar-inner">
        <button type="button" class="mobile-menu-button" data-profile-menu aria-label="Open account menu">
            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" aria-hidden="true"><path d="M4 6h16"/><path d="M4 12h16"/><path d="M4 18h16"/></svg>
        </button>
        <a href="{{ route('shop.index') }}" class="profile-logo" aria-label="Lumora shop">
            <span class="profile-logo-brand">LUM<span>O</span>RA</span>
            <span class="profile-logo-tagline">Beauty lives here</span>
        </a>
        <form action="{{ route('shop.index') }}" method="GET" class="topbar-search">
            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" aria-hidden="true"><path d="m21 21-4.3-4.3"/><circle cx="11" cy="11" r="7"/></svg>
            <input type="search" name="search" placeholder="Search Lumora" aria-label="Search Lumora">
        </form>
        <div class="topbar-actions">
            <a href="{{ route('profile.edit') }}#wishlist" class="topbar-action" aria-label="Wishlist">
                <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.7" aria-hidden="true"><path d="M20.8 4.6a5.5 5.5 0 0 0-7.8 0L12 5.6l-1-1a5.5 5.5 0 0 0-7.8 7.8l1 1L12 21l7.8-7.6 1-1a5.5 5.5 0 0 0 0-7.8Z"/></svg>
            </a>
            <a href="{{ route('buyer.cart') }}" class="topbar-action" aria-label="Cart">
                <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.7" aria-hidden="true"><circle cx="8" cy="21" r="1"/><circle cx="19" cy="21" r="1"/><path d="M2.1 2.1h3l2.7 12.4a2 2 0 0 0 2 1.6h7.8a2 2 0 0 0 2-1.6L21 7H6"/></svg>
                @if ($cartCount > 0)<span class="topbar-badge">{{ $cartCount }}</span>@endif
            </a>
        </div>
    </div>
</header>

<div class="drawer-backdrop" data-profile-backdrop></div>

<main class="profile-page">
    <div class="profile-layout">
        @include('profile.partials.account-sidebar', ['active' => 'payment-methods'])

        <section class="payment-content">
            <nav class="breadcrumb" aria-label="Breadcrumb">
                <a href="{{ route('shop.index') }}">Home</a>
                <span>/</span>
                <a href="{{ route('profile.edit') }}">Account</a>
                <span>/</span>
                <span>Payment Methods</span>
            </nav>

            <header class="payment-header">
                <p class="account-label">Account</p>
                <h1 class="payment-title">Payment Methods</h1>
                <p class="payment-subtitle">Manage your saved payment options for faster checkout.</p>
            </header>

            @if (session('status') === 'payment-method-saved')
                <div class="alert">Payment method saved.</div>
            @elseif (session('status') === 'payment-method-default')
                <div class="alert">Default payment method updated.</div>
            @elseif (session('status') === 'payment-method-removed')
                <div class="alert">Payment method removed.</div>
            @endif

            <div class="payment-grid">
                <section class="payment-panel" aria-labelledby="saved-methods-heading">
                    <div class="panel-head">
                        <div>
                            <h2 id="saved-methods-heading">Saved Methods</h2>
                        </div>
                        <a class="add-anchor" href="#add-payment-method">Add New Method</a>
                    </div>

                    @if ($paymentMethods->isEmpty())
                        <div class="empty-state">
                            <div class="empty-icon" aria-hidden="true">
                                <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.7"><rect x="3" y="5" width="18" height="14" rx="2"/><path d="M3 10h18"/></svg>
                            </div>
                            <h2>No saved payment methods yet.</h2>
                            <p>Add a payment option for faster checkout.</p>
                        </div>
                    @else
                        <div class="method-list">
                            @foreach ($paymentMethods as $method)
                                <article class="method-card">
                                    <div class="method-icon" aria-hidden="true">
                                        <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.7">{!! $methodIcon($method->type) !!}</svg>
                                    </div>
                                    <div class="method-main">
                                        <div class="method-top">
                                            <span class="method-type">{{ $typeLabels[$method->type] ?? ucwords(str_replace('_', ' ', $method->type)) }}</span>
                                            @if ($method->is_default)
                                                <span class="default-badge">Default</span>
                                            @endif
                                        </div>
                                        <p class="method-provider">{{ $method->provider ?: $method->account_name ?: 'Lumora payment method' }}</p>
                                        <p class="method-identifier">{{ $maskedIdentifier($method) }}</p>
                                        @if ($method->notes)
                                            <p class="method-notes">{{ $method->notes }}</p>
                                        @endif

                                        <div class="method-actions">
                                            @unless ($method->is_default)
                                                <form method="POST" action="{{ route('buyer.payment-methods.default', $method) }}">
                                                    @csrf
                                                    @method('PATCH')
                                                    <button class="text-button" type="submit">Set Default</button>
                                                </form>
                                            @endunless
                                            <form method="POST" action="{{ route('buyer.payment-methods.destroy', $method) }}">
                                                @csrf
                                                @method('DELETE')
                                                <button class="danger-button" type="submit">Remove</button>
                                            </form>
                                        </div>
                                    </div>
                                </article>
                            @endforeach
                        </div>
                    @endif
                </section>

                <section class="payment-panel" id="add-payment-method" aria-labelledby="add-method-heading">
                    <div class="panel-head">
                        <div>
                            <h2 id="add-method-heading">Add New Payment Method</h2>
                            <p>Add a new payment option to your account.</p>
                        </div>
                    </div>

                    <form class="payment-form" method="POST" action="{{ route('buyer.payment-methods.store') }}">
                        @csrf
                        <div class="field">
                            <label for="type">Method Type</label>
                            <select class="select" id="type" name="type" required>
                                <option value="cod" @selected(old('type') === 'cod')>Cash on Delivery</option>
                                <option value="gcash" @selected(old('type') === 'gcash')>GCash</option>
                                <option value="maya" @selected(old('type') === 'maya')>Maya</option>
                                <option value="bank_transfer" @selected(old('type') === 'bank_transfer')>Bank Transfer</option>
                                <option value="card_reference" @selected(old('type') === 'card_reference')>Card Reference</option>
                            </select>
                            @error('type')<span class="field-error">{{ $message }}</span>@enderror
                        </div>

                        <div class="field">
                            <label for="provider">Provider</label>
                            <input class="input" id="provider" name="provider" value="{{ old('provider') }}" placeholder="Cash on Delivery, GCash, Maya, or bank name">
                            @error('provider')<span class="field-error">{{ $message }}</span>@enderror
                        </div>

                        <div class="field">
                            <label for="account_name">Account / Cardholder Name</label>
                            <input class="input" id="account_name" name="account_name" value="{{ old('account_name') }}" placeholder="{{ $user->name }}">
                            @error('account_name')<span class="field-error">{{ $message }}</span>@enderror
                        </div>

                        <div class="field">
                            <label for="account_identifier">Account Number / Last 4 Digits</label>
                            <input class="input" id="account_identifier" name="account_identifier" value="{{ old('account_identifier', old('last_four')) }}" placeholder="Enter last 4 digits only" maxlength="255">
                            @error('account_identifier')<span class="field-error">{{ $message }}</span>@enderror
                            @error('last_four')<span class="field-error">{{ $message }}</span>@enderror
                        </div>

                        <div class="field">
                            <label for="notes">Notes Optional</label>
                            <textarea class="textarea" id="notes" name="notes" placeholder="Optional note for this payment method">{{ old('notes') }}</textarea>
                            @error('notes')<span class="field-error">{{ $message }}</span>@enderror
                        </div>

                        <label class="checkbox-row">
                            <input type="checkbox" name="is_default" value="1" @checked(old('is_default'))>
                            <span class="checkbox-label">Set as default</span>
                        </label>

                        <button class="submit-button" type="submit">Save Payment Method</button>
                    </form>
                </section>
            </div>
        </section>
    </div>
</main>

@auth
    @include('components.chat-widget')
@endauth

<script>
    document.addEventListener('DOMContentLoaded', () => {
        const typeSelect = document.querySelector('#type');
        const providerInput = document.querySelector('#provider');
        const identifierInput = document.querySelector('#account_identifier');

        const syncPaymentFields = () => {
            if (!typeSelect || !providerInput || !identifierInput) return;

            const type = typeSelect.value;

            if (type === 'cod' && providerInput.value.trim() === '') {
                providerInput.value = 'Cash on Delivery';
            }

            identifierInput.maxLength = type === 'card_reference' ? 4 : 255;
            identifierInput.placeholder = type === 'card_reference'
                ? 'Enter last 4 digits only'
                : 'Account number or safe account reference';
        };

        typeSelect?.addEventListener('change', syncPaymentFields);
        syncPaymentFields();
    });
</script>
</body>
</html>
