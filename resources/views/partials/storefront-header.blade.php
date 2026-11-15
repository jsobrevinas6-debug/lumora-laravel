    <div class="flow-menu-backdrop" id="flowMenuBackdrop"></div>
    <aside class="flow-menu-drawer" id="flowMenuDrawer" aria-hidden="true">
        <x-logo :href="route('home')" aria-label="Lumora home" class="mb-5" />
        <div class="flow-menu-head">
            <h2>Shop by collection</h2>
            <button type="button" class="flow-menu-close" id="flowMenuClose" aria-label="Close collections menu">&times;</button>
        </div>
        <nav class="flow-menu-list" aria-label="Shop by collection">
            @php
                $categoryCounts = $categoryCounts ?? [];
                $shopProducts = collect($products ?? []);
            @endphp

            @foreach ($flowMenuCategories as $category)
                <x-flow-menu-node
                    :node="$category"
                    :category-counts="$categoryCounts"
                    :shop-products="$shopProducts"
                />
            @endforeach
        </nav>
        <p class="flow-menu-note">Select a collection to browse matching products.</p>
    </aside>

    <!-- ===================== TOP BAR ===================== -->
    <header class="topbar storefront-header">
        <div class="topbar-inner">
            <button type="button" class="flow-menu-trigger left-menu-trigger" id="flowMenuTriggerLeft" aria-label="Open shop by collection" aria-expanded="false" aria-controls="flowMenuDrawer">
                <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8"><path d="M4 7h16M4 12h16M4 17h16"/></svg>
            </button>
            <x-logo :href="route('home')" aria-label="Lumora home" class="storefront-brand" />

            <form action="{{ route('shop.index') }}" method="GET" class="search">
                <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><circle cx="11" cy="11" r="7"/><path d="m21 21-4.3-4.3"/></svg>
                <input type="text" name="q" placeholder="Search skincare, makeup, fragrance..." value="{{ request('q') }}">
            </form>

            <div class="nav-actions">
                @auth
                    @php
                        $headerNotifications = Auth::user()->notifications()->latest()->limit(8)->get();
                        $unreadNotificationCount = Auth::user()->unreadNotifications()->count();
                    @endphp
                    <div class="notification-wrap" id="notificationWrap">
                        <button type="button" class="icon-btn notification-trigger" id="notificationTrigger" aria-label="Notifications{{ $unreadNotificationCount ? ', '.$unreadNotificationCount.' unread' : '' }}" aria-expanded="false" aria-controls="notificationDropdown">
                            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" aria-hidden="true"><path d="M18 8a6 6 0 0 0-12 0c0 7-3 7-3 9h18c0-2-3-2-3-9M10 21h4"/></svg>
                            @if ($unreadNotificationCount > 0)<span class="badge">{{ $unreadNotificationCount > 9 ? '9+' : $unreadNotificationCount }}</span>@endif
                        </button>
                        <div class="notification-dropdown" id="notificationDropdown" aria-label="Notifications">
                            <div class="notification-head">
                                <strong>Notifications</strong>
                                @if ($unreadNotificationCount > 0)
                                    <form method="POST" action="{{ route('buyer.notifications.read-all') }}">@csrf<button type="submit" class="notification-mark-all">Mark all as read</button></form>
                                @endif
                            </div>
                            <div class="notification-list">
                                @forelse ($headerNotifications as $notification)
                                    @php
                                        $notificationTitle = data_get($notification->data, 'title');
                                        $notificationBody = data_get($notification->data, 'body');
                                        $notificationMessage = data_get($notification->data, 'message', 'You have a new update from Lumora.');
                                    @endphp
                                    <div class="notification-item {{ $notification->read_at ? '' : 'unread' }}">
                                        @unless ($notification->read_at)<span class="notification-unread-dot" aria-label="Unread"></span>@endunless
                                        <form method="POST" action="{{ route('buyer.notifications.read', $notification->id) }}">
                                            @csrf
                                            <button type="submit" class="notification-open">
                                                @if ($notificationTitle)<strong class="notification-message">{{ $notificationTitle }}</strong>@endif
                                                <span class="notification-message">{{ $notificationBody ?: $notificationMessage }}</span>
                                                <span class="notification-time">{{ $notification->created_at->diffForHumans() }}</span>
                                            </button>
                                        </form>
                                    </div>
                                @empty
                                    <p class="notification-empty">Youâ€™re all caught up.</p>
                                @endforelse
                            </div>
                        </div>
                    </div>
                @else
                    <a href="{{ route('login') }}" class="icon-btn" aria-label="Sign in to view notifications">
                        <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" aria-hidden="true"><path d="M18 8a6 6 0 0 0-12 0c0 7-3 7-3 9h18c0-2-3-2-3-9M10 21h4"/></svg>
                    </a>
                @endauth
                @php
                    $wishlistCount = auth()->check()
                        ? \Illuminate\Support\Facades\DB::table('saved_products')->where('user_id', auth()->id())->count()
                        : 0;
                @endphp
                <a href="{{ auth()->check() ? route('buyer.wishlist.index') : route('login', ['redirect_to' => route('buyer.wishlist.index')]) }}" class="icon-btn" aria-label="Wishlist">
                    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8"><path d="M20.8 4.6a5.5 5.5 0 0 0-7.8 0L12 5.6l-1-1a5.5 5.5 0 0 0-7.8 7.8l1 1L12 21l7.8-7.6 1-1a5.5 5.5 0 0 0 0-7.8Z"/></svg>
                    <span class="badge" data-wishlist-count @if ($wishlistCount < 1) hidden @endif>{{ $wishlistCount }}</span>
                </a>
                @auth
                    <a href="{{ route('buyer.cart') }}" class="icon-btn" aria-label="Cart">
                @else
                    <button type="button" class="icon-btn" data-open-guest-cart aria-label="Sign in to view cart">
                @endauth
                    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8"><circle cx="9" cy="21" r="1"/><circle cx="19" cy="21" r="1"/><path d="M2.5 3h2l2.7 12.4a2 2 0 0 0 2 1.6h8.6a2 2 0 0 0 2-1.6L21.5 7H6"/></svg>
                    <span class="badge" data-cart-count>
                        {{ session('lumora_cart') ? collect(session('lumora_cart'))->sum('quantity') : 0 }}
                    </span>
                @auth
                    </a>
                @else
                    </button>
                @endauth

                @auth
                    @php
                        $authUser = Auth::user();
                        $sellerApplication = $authUser->sellerApplication;
                        $isGoogleBuyer = $authUser->provider === 'google' && $authUser->role === 'buyer';
                    @endphp
                    <div class="account-menu-wrap" id="accountMenuWrap">
                        <button type="button" class="account-trigger" id="accountTrigger" aria-expanded="false" aria-haspopup="menu" aria-controls="accountDropdown">
                            <div class="avatar">@if ($authUser->avatar)<img src="{{ $authUser->avatar }}" alt="">@else{{ strtoupper(substr($authUser->name,0,1)) }}@endif</div>
                            <div class="account-text">
                                <div class="account-name">{{ $authUser->name }}</div>
                                <div class="account-mode">Shopping as Buyer</div>
                            </div>
                            <svg class="account-chevron" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="m6 9 6 6 6-6"/></svg>
                        </button>

                        <div class="account-dropdown" id="accountDropdown" role="menu" aria-labelledby="accountTrigger">
                            <div class="account-dropdown-head">
                                <div class="avatar">@if ($authUser->avatar)<img src="{{ $authUser->avatar }}" alt="">@else{{ strtoupper(substr($authUser->name,0,1)) }}@endif</div>
                                <div class="account-dropdown-user">
                                    <div class="account-dropdown-name">{{ $authUser->name }}</div>
                                    <div class="account-dropdown-meta"><span>{{ ucfirst($authUser->role) }}</span><span aria-hidden="true">·</span><span class="account-dropdown-email">{{ $authUser->email }}</span></div>
                                </div>
                            </div>

                            <a href="{{ route('profile.edit') }}" class="account-menu-item account-menu-link" role="menuitem">
                                <span class="account-menu-icon"><svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8"><circle cx="12" cy="8" r="4"/><path d="M4 21a8 8 0 0 1 16 0"/></svg></span>
                                <span>Profile / Settings</span>
                            </a>
                            <div class="account-menu-divider"></div>

                            @if ($authUser->role === 'seller')
                                <form method="POST" action="{{ route('switchToSeller') }}">
                                    @csrf
                                    <button type="submit" class="account-menu-item account-menu-button switch-seller" role="menuitem">
                                        <span class="account-menu-icon"><svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8"><path d="M4 12h12"/><path d="m12 6 6 6-6 6"/><path d="M4 4h6M4 20h6"/></svg></span>
                                        <span>Switch to Seller Dashboard</span>
                                    </button>
                                </form>
                            @elseif ($isGoogleBuyer)
                                @if (! $sellerApplication)
                                    <a href="{{ route('seller.apply') }}" class="account-menu-item account-menu-link" role="menuitem">
                                        <span class="account-menu-icon"><svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8"><path d="M4 10h16"/><path d="M5 10l1.2-5h11.6L19 10"/><path d="M6 10v9h12v-9"/><path d="M9 19v-5h6v5"/></svg></span>
                                        <span>Apply as Seller</span>
                                    </a>
                                @elseif ($sellerApplication->status === 'pending')
                                    <div class="account-menu-item account-menu-note" role="menuitem" aria-disabled="true" tabindex="0">
                                        <span class="account-menu-icon"><svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8"><circle cx="12" cy="12" r="9"/><path d="M12 7v5l3 2"/></svg></span>
                                        <span class="account-menu-label">Seller application</span><span class="account-pending-pill">Pending</span>
                                    </div>
                                @elseif ($sellerApplication->status === 'rejected')
                                    <div class="account-menu-item account-menu-note" role="menuitem" aria-disabled="true" tabindex="0">
                                        <span class="account-menu-icon"><svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8"><circle cx="12" cy="12" r="9"/><path d="m9 9 6 6M15 9l-6 6"/></svg></span>
                                        <span>Seller Application Rejected</span>
                                    </div>
                                @elseif ($sellerApplication->status === 'approved')
                                    <div class="account-menu-item account-menu-note" role="menuitem" aria-disabled="true" tabindex="0">
                                        <span class="account-menu-icon"><svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8"><circle cx="12" cy="12" r="9"/><path d="m8.5 12 2.5 2.5L16 9"/></svg></span>
                                        <span>Seller Application Approved</span>
                                    </div>
                                @endif
                            @endif

                            <a href="{{ route('buyer.orders.index') }}" class="account-menu-item account-menu-link" role="menuitem">
                                <span class="account-menu-icon"><svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8"><path d="M6 3h12v18l-3-2-3 2-3-2-3 2V3Z"/><path d="M9 8h6M9 12h6"/></svg></span>
                                <span>My Orders</span>
                            </a>

                            <x-account-recent-chats />

                            <div class="account-menu-divider"></div>
                            <form method="POST" action="{{ route('logout') }}">
                                @csrf
                                <button type="submit" class="account-menu-item account-menu-button logout-menu" role="menuitem">
                                    <span class="account-menu-icon"><svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8"><path d="M10 17 5 12l5-5"/><path d="M5 12h12"/><path d="M14 4h5v16h-5"/></svg></span>
                                    <span>Log out</span>
                                </button>
                            </form>
                        </div>
                    </div>
                @else
                    <a href="{{ route('login') }}" class="btn btn-ghost">Login</a>
                    <a href="{{ route('register') }}" class="btn btn-primary">Sign Up</a>
                @endauth
            </div>
        </div>
    </header>
