<x-admin-layout title="Product Approval">
    <style>
        .approval-page { --approval-ink:#2B1C22; --approval-muted:#66565C; --approval-maroon:#5B1A33; --approval-green:#1E6B4A; --approval-red:#9B2315; color:var(--approval-ink); }
        .approval-summary { display:grid; grid-template-columns:repeat(4,minmax(0,1fr)); gap:14px; margin-bottom:20px; }
        .approval-tile,.approval-card { background:#fff; border:1px solid var(--border); border-radius:24px; box-shadow:0 4px 18px rgba(91,26,53,.04); }
        .approval-tile { padding:18px 20px; min-height:112px; }
        .approval-tile-label { color:var(--approval-muted); font-size:.82rem; font-weight:600; }
        .approval-tile-value { display:block; margin-top:5px; font-size:1.7rem; line-height:1.2; font-weight:800; }
        .approval-tile.overdue { border-color:#E7B9B2; background:#FFF8F6; }
        .approval-tile.overdue .approval-tile-value { color:var(--approval-red); }
        .approval-tabs { display:flex; gap:8px; border-bottom:1px solid var(--border); padding:0 4px; margin-bottom:16px; overflow-x:auto; }
        .approval-tab { min-height:44px; display:inline-flex; align-items:center; gap:8px; padding:0 14px; border-bottom:3px solid transparent; color:var(--approval-muted); text-decoration:none; font-size:.9rem; font-weight:700; white-space:nowrap; }
        .approval-tab.active { color:var(--approval-maroon); border-bottom-color:var(--approval-maroon); }
        .approval-count { border-radius:999px; padding:2px 8px; background:#F5E9E5; color:var(--approval-maroon); font-size:.74rem; }
        .approval-toolbar { display:grid; grid-template-columns:minmax(210px,1.6fr) repeat(3,minmax(145px,1fr)); gap:10px; margin-bottom:14px; }
        .approval-control { min-height:46px; width:100%; border:1px solid #D9C9C4; border-radius:12px; padding:9px 12px; color:var(--approval-ink); background:#fff; font:500 .85rem Poppins,sans-serif; }
        .approval-control:focus,.approval-button:focus-visible,.approval-tab:focus-visible,.approval-table button:focus-visible,.approval-table a:focus-visible { outline:3px solid #9B6A80; outline-offset:2px; }
        .approval-loading { display:none; margin:0 0 12px; color:var(--approval-muted); }
        .approval-form[aria-busy="true"] .approval-loading { display:block; }
        #approvalSummarySkeleton,#approvalRowsSkeleton { display:none; }
        .approval-page.is-loading #approvalSummaryContent,.approval-page.is-loading #approvalTableContent { display:none; }
        .approval-page.is-loading #approvalSummarySkeleton { display:grid; }
        .approval-page.is-loading #approvalRowsSkeleton { display:block; }
        .approval-skeleton { display:inline-block; height:14px; width:100%; border-radius:8px; background:linear-gradient(90deg,#F3E7E2,#FBF1EC,#F3E7E2); background-size:200% 100%; animation:approval-shimmer 1.2s infinite; }
        @keyframes approval-shimmer { to { background-position:-200% 0; } }
        .approval-layout { display:grid; grid-template-columns:minmax(0,1fr) minmax(300px,360px); align-items:start; gap:18px; }
        .approval-card { min-width:0; padding:20px; }
        .approval-card h2 { margin:0 0 15px; color:var(--approval-ink); font-size:1.05rem; font-weight:800; }
        .approval-bulk { display:none; align-items:center; flex-wrap:wrap; gap:9px; padding:11px 13px; margin-bottom:14px; border-radius:14px; background:var(--approval-maroon); color:#fff; }
        .approval-bulk.visible { display:flex; }
        .approval-bulk-count { margin-right:auto; font-size:.88rem; font-weight:700; }
        .approval-button { min-height:44px; display:inline-flex; justify-content:center; align-items:center; gap:7px; padding:8px 13px; border:1px solid transparent; border-radius:11px; background:#fff; color:var(--approval-ink); font:700 .82rem Poppins,sans-serif; cursor:pointer; text-decoration:none; }
        .approval-button:disabled { opacity:.55; cursor:wait; }
        .approval-button.primary { background:var(--approval-maroon); color:#fff; }
        .approval-button.bulk-light { min-height:40px; background:#fff; color:var(--approval-maroon); }
        .approval-button.bulk-ghost { min-height:40px; background:transparent; color:#fff; border-color:rgba(255,255,255,.6); }
        .approval-button.approve { background:var(--approval-green); color:#fff; }
        .approval-button.reject { background:#fff; color:var(--approval-red); border-color:#D58B83; }
        .approval-table-wrap { overflow-x:auto; width:100%; border:1px solid var(--border); border-radius:14px; }
        .approval-table { min-width:1060px; width:100%; border-collapse:collapse; }
        .approval-table th { background:#FBF7F5; color:#58464D; font-size:.74rem; letter-spacing:.02em; white-space:nowrap; }
        .approval-table td { padding:12px 10px; color:var(--approval-ink); vertical-align:middle; font-size:.82rem; }
        .approval-table tr:last-child td { border-bottom:0; }
        .approval-table tr[data-product-row] { cursor:pointer; }
        .approval-table tr[data-product-row]:focus-within td,.approval-table tr[data-product-row]:hover td { background:#FFF9F6; }
        .approval-check { width:20px; height:20px; accent-color:var(--approval-maroon); cursor:pointer; }
        .approval-product { display:flex; align-items:center; gap:10px; min-width:235px; }
        .approval-thumb { width:50px; height:50px; flex:0 0 50px; border-radius:10px; object-fit:cover; background:#FBF1EC; }
        .approval-name { color:var(--approval-ink); font-weight:700; }
        .approval-sub { display:block; margin-top:3px; color:var(--approval-muted); font-size:.73rem; }
        .approval-chip { display:inline-flex; align-items:center; min-height:24px; padding:2px 8px; border-radius:999px; font-size:.7rem; font-weight:700; white-space:nowrap; }
        .approval-chip.new { color:#71420B; background:#F8E9C8; }
        .approval-chip.verified { color:#15553A; background:#E1F1E8; }
        .approval-chip.low { color:#71420B; background:#F8E9C8; }
        .approval-chip.overdue { color:#fff; background:var(--approval-red); }
        .approval-chip.normal { color:#315B48; background:#E5F2EA; }
        .approval-price { text-align:right!important; white-space:nowrap; font-weight:700; }
        .approval-actions { display:flex; align-items:center; gap:6px; }
        .approval-icon-button { width:44px; height:44px; display:inline-flex; align-items:center; justify-content:center; border:1px solid transparent; border-radius:11px; cursor:pointer; }
        .approval-icon-button svg { width:18px; height:18px; }
        .approval-icon-button.approve-icon { background:#E7F2EB; color:var(--approval-green); }
        .approval-icon-button.reject-icon { background:#fff; color:var(--approval-red); border-color:#D58B83; }
        .approval-panel[hidden] { display:none; }
        .approval-panel { position:sticky; top:16px; max-height:calc(100vh - 32px); overflow-y:auto; }
        .approval-panel-empty { color:var(--approval-muted); font-size:.86rem; line-height:1.65; }
        .approval-photos-main { width:100%; height:220px; object-fit:contain; background:#FBF7F5; border-radius:14px; }
        .approval-thumbs { display:flex; gap:8px; margin-top:8px; overflow-x:auto; }
        .approval-thumbs button { padding:0; border:2px solid transparent; border-radius:9px; background:none; cursor:pointer; }
        .approval-thumbs button:focus-visible,.approval-thumbs button.active { outline:2px solid var(--approval-maroon); border-color:var(--approval-maroon); }
        .approval-thumbs img { display:block; width:52px; height:52px; object-fit:cover; border-radius:7px; }
        .approval-detail-title { margin:15px 0 3px; font-size:1.05rem; font-weight:800; overflow-wrap:anywhere; }
        .approval-facts { display:grid; grid-template-columns:1fr 1fr; gap:10px; margin:14px 0; }
        .approval-fact { padding:10px; border-radius:12px; background:#FBF7F5; }
        .approval-fact span { display:block; color:var(--approval-muted); font-size:.72rem; }
        .approval-fact strong { display:block; margin-top:3px; font-size:.86rem; }
        .approval-checks { list-style:none; display:grid; gap:8px; margin:12px 0 16px; padding:0; }
        .approval-checks li { display:flex; gap:8px; color:var(--approval-ink); font-size:.78rem; line-height:1.5; }
        .approval-checks .pass { color:var(--approval-green); font-weight:800; }
        .approval-checks .warn { color:#805209; font-weight:800; }
        .approval-description { white-space:pre-wrap; overflow-wrap:anywhere; color:#493A3F; font-size:.82rem; line-height:1.6; }
        .approval-panel label,.approval-dialog label { display:block; margin:13px 0 5px; color:var(--approval-ink); font-size:.78rem; font-weight:700; }
        .approval-panel textarea { min-height:80px; resize:vertical; }
        .approval-panel-actions { display:grid; grid-template-columns:1fr 1fr; gap:8px; margin-top:12px; }
        .approval-empty { padding:34px 16px; text-align:center; }
        .approval-empty-icon { width:54px; height:54px; display:grid; place-items:center; margin:0 auto 12px; border-radius:50%; color:var(--approval-green); background:#E4F2E9; }
        .approval-empty h3 { margin-bottom:7px; font-size:1.1rem; }
        .approval-empty p { max-width:520px; margin:0 auto 18px; color:var(--approval-muted); font-size:.86rem; line-height:1.6; }
        .approval-empty-actions { display:flex; flex-wrap:wrap; justify-content:center; gap:8px; }
        .approval-pagination { display:flex; align-items:center; flex-wrap:wrap; gap:7px; margin-top:16px; }
        .approval-pagination-info { margin-right:auto; color:var(--approval-muted); font-size:.78rem; }
        .approval-page-link { min-width:44px; min-height:44px; display:grid; place-items:center; padding:0 10px; border:1px solid var(--border); border-radius:10px; background:#fff; color:var(--approval-maroon); text-decoration:none; font-size:.82rem; font-weight:700; }
        .approval-page-link.current { background:var(--approval-maroon); color:#fff; }
        .approval-page-link[aria-disabled="true"] { color:#766B6E; background:#F8F4F2; pointer-events:none; }
        .approval-toast { position:fixed; right:24px; bottom:24px; z-index:100; max-width:min(420px,calc(100vw - 32px)); padding:14px 18px; border-radius:14px; background:#253B30; color:#fff; box-shadow:0 8px 30px #0003; font-size:.88rem; }
        .approval-dialog { width:min(480px,calc(100vw - 32px)); border:0; border-radius:22px; padding:22px; color:var(--approval-ink); box-shadow:0 20px 60px #0004; }
        .approval-dialog::backdrop { background:#22171bb3; }
        .approval-dialog h2 { margin-bottom:8px; }
        .approval-dialog .approval-dialog-actions { display:flex; justify-content:flex-end; gap:8px; margin-top:16px; }
        .approval-retry { padding:16px; border:1px solid #E7B9B2; border-radius:14px; background:#FFF8F6; color:#6B2119; }
        @media (max-width:1200px) { .approval-layout { grid-template-columns:minmax(0,1fr) 320px; } .approval-toolbar { grid-template-columns:repeat(2,minmax(0,1fr)); } }
        @media (max-width:900px) { .approval-summary { grid-template-columns:repeat(2,minmax(0,1fr)); } .approval-layout { grid-template-columns:1fr; } .approval-panel { position:static; max-height:none; } }
        @media (max-width:600px) { .approval-summary { gap:8px; } .approval-tile { padding:14px; min-height:98px; } .approval-tile-value { font-size:1.35rem; } .approval-card { padding:14px; border-radius:20px; } .approval-toolbar { grid-template-columns:1fr; } .approval-bulk-count { flex-basis:100%; } .approval-pagination-info { flex-basis:100%; } }
    </style>

    <div class="approval-page">
        <div id="approvalSummarySkeleton" class="approval-summary" aria-hidden="true"><article class="approval-tile"><span class="approval-skeleton"></span><span class="approval-skeleton" style="height:28px;margin-top:12px;"></span></article><article class="approval-tile"><span class="approval-skeleton"></span><span class="approval-skeleton" style="height:28px;margin-top:12px;"></span></article><article class="approval-tile"><span class="approval-skeleton"></span><span class="approval-skeleton" style="height:28px;margin-top:12px;"></span></article><article class="approval-tile"><span class="approval-skeleton"></span><span class="approval-skeleton" style="height:28px;margin-top:12px;"></span></article></div>
        <section id="approvalSummaryContent" class="approval-summary" aria-label="Product review summary">
            <article class="approval-tile"><div class="approval-tile-label">Pending review</div><strong class="approval-tile-value">{{ number_format($pendingCount) }}</strong></article>
            <article class="approval-tile overdue"><div class="approval-tile-label">Waiting over 48 hours</div><strong class="approval-tile-value">{{ number_format($overdueCount) }}</strong></article>
            <article class="approval-tile"><div class="approval-tile-label">Approved today</div><strong class="approval-tile-value">{{ number_format($approvedTodayCount) }}</strong></article>
            <article class="approval-tile"><div class="approval-tile-label">Average review time · 7 days</div><strong class="approval-tile-value">{{ $averageReviewHours === null ? '—' : $averageReviewHours.'h' }}</strong></article>
        </section>

        <nav class="approval-tabs" aria-label="Product approval status">
            @foreach (['pending' => 'Pending', 'approved' => 'Approved', 'rejected' => 'Rejected'] as $tab => $label)
                <a class="approval-tab {{ $status === $tab ? 'active' : '' }}" href="{{ route('admin.product-approval', array_merge(request()->except('page', 'review'), ['status' => $tab])) }}" @if ($status === $tab) aria-current="page" @endif>
                    {{ $label }} <span class="approval-count">{{ number_format((int) ($tabCounts[$tab] ?? 0)) }}</span>
                </a>
            @endforeach
        </nav>

        @if ($errors->any())
            <div class="approval-retry" role="alert">The review page could not complete that request. <a class="approval-button primary" href="{{ route('admin.product-approval', request()->query()) }}">Retry</a></div>
        @endif

        <form class="approval-form" method="GET" action="{{ route('admin.product-approval') }}" id="approvalFilters">
            <input type="hidden" name="status" value="{{ $status }}">
            <div class="approval-toolbar">
                <label class="sr-only" for="approvalSearch">Search by product name, SKU, or seller</label>
                <input class="approval-control" id="approvalSearch" type="search" name="q" value="{{ $filters['q'] }}" placeholder="Product name{{ $skuExists ? ', SKU' : '' }}, or seller" aria-label="Search by product name{{ $skuExists ? ', SKU' : '' }}, or seller">
                <label class="sr-only" for="approvalCategory">Filter by category</label>
                <select class="approval-control" id="approvalCategory" name="category">
                    <option value="">All categories</option>
                    @foreach ($categories as $category)
                        <option value="{{ $category }}" @selected($filters['category'] === $category)>{{ \App\Support\CategoryCatalog::label($category) }}</option>
                    @endforeach
                </select>
                <label class="sr-only" for="approvalSellerType">Filter by seller type</label>
                <select class="approval-control" id="approvalSellerType" name="seller_type">
                    <option value="all">All sellers</option><option value="new" @selected($filters['seller_type'] === 'new')>New sellers</option><option value="verified" @selected($filters['seller_type'] === 'verified')>Verified sellers</option>
                </select>
                <label class="sr-only" for="approvalSort">Sort products</label>
                <select class="approval-control" id="approvalSort" name="sort">
                    <option value="oldest" @selected($filters['sort'] === 'oldest')>Oldest first</option><option value="newest" @selected($filters['sort'] === 'newest')>Newest first</option><option value="price" @selected($filters['sort'] === 'price')>Price high to low</option>
                </select>
            </div>
            <div class="approval-loading" aria-live="polite"><span class="approval-skeleton" aria-hidden="true"></span> Updating product list…</div>
            <noscript><button class="approval-button primary" type="submit">Apply filters</button></noscript>
        </form>

        <div class="approval-layout">
            <section class="approval-card" aria-label="{{ ucfirst($status) }} products">
                @if ($status === 'pending' && $products->isEmpty() && $filters['q'] === '' && $filters['category'] === '' && $filters['seller_type'] === 'all')
                    <div class="approval-empty">
                        <div class="approval-empty-icon" aria-hidden="true"><svg width="28" height="28" viewBox="0 0 24 24" fill="none"><path d="m5 12 4.5 4.5L19 7" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"/></svg></div>
                        <h3>You're all caught up</h3>
                        <p>No products are waiting for approval. New seller listings show up here as soon as they are submitted.</p>
                        <div class="approval-empty-actions"><a class="approval-button primary" href="{{ route('admin.product-approval', ['status' => 'approved', 'sort' => 'newest']) }}">View recently approved</a></div>
                    </div>
                @else
                    <div id="approvalRowsSkeleton" aria-hidden="true" style="margin:12px 0;">
                        @for ($skeletonRow = 0; $skeletonRow < 5; $skeletonRow++)<div style="margin:10px 0;"><span class="approval-skeleton" style="height:46px;"></span></div>@endfor
                    </div>
                    <div id="approvalTableContent">
                    <div class="approval-bulk" id="approvalBulk" aria-live="polite">
                        <span class="approval-bulk-count" id="selectedCount">0 products selected</span>
                        <button class="approval-button bulk-light" type="button" data-bulk-action="approved">Approve selected</button>
                        <button class="approval-button bulk-light" type="button" data-bulk-action="rejected">Reject selected</button>
                        <button class="approval-button bulk-ghost" type="button" id="clearSelection">Clear</button>
                    </div>
                    <div class="approval-table-wrap">
                        <table class="approval-table">
                            <thead><tr>
                                <th scope="col"><input class="approval-check" id="selectPage" type="checkbox" aria-label="Select all products on this page" @disabled($status !== 'pending')></th>
                                <th scope="col">Product</th><th scope="col">Seller</th><th scope="col">Category</th><th scope="col" class="approval-price">Price</th><th scope="col">Stock</th><th scope="col">Submitted</th><th scope="col">Actions</th>
                            </tr></thead>
                            <tbody>
                            @forelse ($products as $product)
                                @php
                                    $rawImages = isset($product->images) ? (is_array($product->images) ? $product->images : json_decode((string) $product->images, true)) : [];
                                    $rawImages = is_array($rawImages) ? array_values(array_filter($rawImages)) : [];
                                    if ($rawImages === [] && $product->image) $rawImages = [$product->image];
                                    $imageUrls = array_slice(array_map(fn ($image) => \App\Models\Product::resolveImageUrl((string) $image), $rawImages), 0, 4);
                                    if ($imageUrls === []) $imageUrls = [\App\Models\Product::placeholderImageUrl()];
                                    $sellerVerified = !empty($product->approved_application_id);
                                    $sellerNew = \Carbon\Carbon::parse($product->seller_created_at)->greaterThanOrEqualTo(now()->subDays(30));
                                    $submittedAt = $product->approval_submitted_at ?: $product->created_at;
                                    $waitingSeconds = max(0, \Carbon\Carbon::parse($submittedAt)->diffInSeconds(now()));
                                    $waitingDays = intdiv($waitingSeconds, 86400);
                                    $waitingHours = intdiv($waitingSeconds % 86400, 3600);
                                    $isOverdue = $waitingSeconds >= $overdueThresholdHours * 3600;
                                    $categoryAverage = (float) ($product->category_average_price ?? 0);
                                    $priceInRange = $categoryAverage > 0 && (float) $product->price >= $categoryAverage * .3 && (float) $product->price <= $categoryAverage * 3;
                                @endphp
                                <tr data-product-row tabindex="0" data-product-id="{{ $product->id }}">
                                    <td><input class="approval-check row-check" type="checkbox" value="{{ $product->id }}" aria-label="Select {{ $product->name }}" @disabled($status !== 'pending')></td>
                                    <td><div class="approval-product"><img class="approval-thumb" src="{{ $imageUrls[0] }}" alt=""><span><span class="approval-name">{{ $product->name }}</span><span class="approval-sub">SKU: {{ $product->sku ?? 'Not provided' }}</span></span></div></td>
                                    <td>{{ $product->seller_name }}<br><span class="approval-chip {{ $sellerVerified ? 'verified' : 'new' }}">{{ $sellerVerified ? 'Verified' : ($sellerNew ? 'New seller' : 'Unverified') }}</span></td>
                                    <td>{{ \App\Support\CategoryCatalog::label((string) $product->category) }}</td>
                                    <td class="approval-price">₱{{ number_format((float) $product->price, 2) }}</td>
                                    <td>{{ (int) $product->stock }} @if ((int) $product->stock < $lowStockThreshold)<br><span class="approval-chip low">Low</span>@endif</td>
                                    <td>{{ \Carbon\Carbon::parse($submittedAt)->format('M j, Y g:i A') }}<br><span class="approval-chip {{ $isOverdue ? 'overdue' : 'normal' }}">Waiting {{ $waitingDays ? $waitingDays.'d ' : '' }}{{ $waitingHours }}h</span></td>
                                    <td><div class="approval-actions">
                                        <button class="approval-button primary" type="button" data-review data-name="{{ $product->name }}" data-sku="{{ $product->sku ?? '' }}" data-category="{{ \App\Support\CategoryCatalog::label((string) $product->category) }}" data-price="{{ (float) $product->price }}" data-stock="{{ (int) $product->stock }}" data-seller="{{ $product->seller_name }}" data-verified="{{ $sellerVerified ? '1' : '0' }}" data-description="{{ $product->description ?? '' }}" data-images="{{ json_encode($imageUrls) }}" data-has-photos="{{ count($rawImages) ? '1' : '0' }}" data-price-range="{{ $priceInRange ? '1' : '0' }}" data-seller-products="{{ (int) ($product->seller_product_count ?? 0) }}" data-seller-approved="{{ (int) ($product->seller_approved_count ?? 0) }}" data-seller-rejected="{{ (int) ($product->seller_rejected_count ?? 0) }}">Review</button>
                                        @if ($status === 'pending')
                                            <form method="POST" action="{{ route('admin.product-approval.approve', $product->id) }}" data-approve-form>@csrf<button class="approval-icon-button approve-icon" type="submit" aria-label="Approve {{ $product->name }}" title="Approve product"><svg viewBox="0 0 24 24" fill="none" aria-hidden="true"><path d="m5 12 4.5 4.5L19 7" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"/></svg></button></form>
                                            <button class="approval-icon-button reject-icon" type="button" data-reject-review aria-label="Reject {{ $product->name }}" title="Reject product">✕</button>
                                        @endif
                                    </div></td>
                                </tr>
                            @empty
                                <tr><td colspan="8" style="text-align:center;color:#66565C;padding:24px;">No {{ $status }} products match these filters.</td></tr>
                            @endforelse
                            </tbody>
                        </table>
                    </div>
                    @if ($products->total() > 0)
                        <div class="approval-pagination" aria-label="Product pages">
                            <span class="approval-pagination-info">Showing {{ $products->firstItem() }}-{{ $products->lastItem() }} of {{ $products->total() }}</span>
                            <a class="approval-page-link" href="{{ $products->previousPageUrl() ?? '#' }}" aria-label="Previous page" aria-disabled="{{ $products->onFirstPage() ? 'true' : 'false' }}">‹</a>
                            @foreach ($products->getUrlRange(max(1, $products->currentPage() - 2), min($products->lastPage(), $products->currentPage() + 2)) as $pageNumber => $url)
                                <a class="approval-page-link {{ $pageNumber === $products->currentPage() ? 'current' : '' }}" href="{{ $url }}" @if ($pageNumber === $products->currentPage()) aria-current="page" @endif>{{ $pageNumber }}</a>
                            @endforeach
                            <a class="approval-page-link" href="{{ $products->nextPageUrl() ?? '#' }}" aria-label="Next page" aria-disabled="{{ !$products->hasMorePages() ? 'true' : 'false' }}">›</a>
                        </div>
                    @endif
                    </div>
                @endif
            </section>

            <aside class="approval-card approval-panel" id="reviewPanel" hidden aria-label="Product review panel" aria-live="polite">
                <button type="button" id="closeReviewPanel" class="approval-button" style="margin-left:auto;display:flex;">Close review</button>
                <div id="reviewContent"><p class="approval-panel-empty">Choose a product and select Review to see its details and checks.</p></div>
            </aside>
        </div>
    </div>

    <dialog class="approval-dialog" id="bulkRejectDialog">
        <form id="bulkRejectForm">
            <h2>Reject selected products?</h2>
            <p id="bulkRejectCount" class="approval-panel-empty"></p>
            <label for="bulkRejectReason">Reason</label>
            <select class="approval-control" id="bulkRejectReason" required><option value="">Choose a reason</option><option>Photos unclear or missing</option><option>Price looks incorrect</option><option>Description incomplete</option><option>Prohibited item</option><option>Other</option></select>
            <label for="bulkRejectNote">Note to seller (optional)</label><textarea class="approval-control" id="bulkRejectNote" rows="3"></textarea>
            <div class="approval-dialog-actions"><button class="approval-button" type="button" data-close-dialog>Cancel</button><button class="approval-button reject" type="submit">Reject products</button></div>
        </form>
    </dialog>
    <div class="approval-toast" id="approvalToast" role="status" aria-live="polite" hidden></div>

    <script>
        (() => {
            const root = document.querySelector('.approval-page');
            const selectedIds = new Set();
            const panel = document.getElementById('reviewPanel');
            const content = document.getElementById('reviewContent');
            const bulkBar = document.getElementById('approvalBulk');
            const toast = document.getElementById('approvalToast');
            let toastTimer;
            let bulkAction = null;
            const escapeHtml = (value) => String(value ?? '').replace(/[&<>"']/g, (char) => ({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#039;'}[char]));
            const money = (value) => '₱' + Number(value || 0).toLocaleString('en-PH', {minimumFractionDigits:2,maximumFractionDigits:2});
            const showToast = (message, retry = null) => {
                toast.replaceChildren(document.createTextNode(message));
                if (retry) {
                    const button = document.createElement('button'); button.type = 'button'; button.className = 'approval-button bulk-light'; button.textContent = 'Retry'; button.style.marginLeft = '10px';
                    button.addEventListener('click', retry); toast.appendChild(button);
                }
                toast.hidden = false; clearTimeout(toastTimer); toastTimer = setTimeout(() => toast.hidden = true, 6000);
            };
            const getSelected = () => Array.from(document.querySelectorAll('.row-check:checked')).map((checkbox) => Number(checkbox.value));
            const syncSelection = () => {
                const ids = getSelected();
                selectedIds.clear(); ids.forEach((id) => selectedIds.add(id));
                if (bulkBar) { bulkBar.classList.toggle('visible', ids.length > 0); document.getElementById('selectedCount').textContent = `${ids.length} product${ids.length === 1 ? '' : 's'} selected`; }
                const all = document.getElementById('selectPage');
                if (all) { const boxes = Array.from(document.querySelectorAll('.row-check:not(:disabled)')); all.checked = boxes.length > 0 && boxes.every((box) => box.checked); all.indeterminate = boxes.some((box) => box.checked) && !all.checked; }
            };
            const closePanel = () => { if (panel) { panel.hidden = true; document.querySelector('[data-review]')?.focus(); } };
            const openPanel = (button, focusReason = false) => {
                if (!panel || !button) return;
                const d = button.dataset;
                let images = []; try { images = JSON.parse(d.images || '[]'); } catch (error) {}
                if (!images.length) images = ['{{ \App\Models\Product::placeholderImageUrl() }}'];
                const hasPhotos = d.hasPhotos === '1';
                const priceInRange = d.priceRange === '1';
                const verified = d.verified === '1';
                const productName = escapeHtml(d.name);
                content.innerHTML = `<div class="approval-photo-area"><img class="approval-photos-main" src="${escapeHtml(images[0])}" alt="Product photo for ${productName}" id="reviewMainPhoto"><div class="approval-thumbs">${images.map((src,index) => `<button type="button" class="${index === 0 ? 'active' : ''}" data-photo="${escapeHtml(src)}" aria-label="Show product photo ${index + 1}"><img src="${escapeHtml(src)}" alt=""></button>`).join('')}</div></div>
                    <h2 class="approval-detail-title">${productName}</h2><p class="approval-panel-empty">SKU: ${escapeHtml(d.sku || 'Not provided')}</p>
                    <div class="approval-facts"><div class="approval-fact"><span>Category</span><strong>${escapeHtml(d.category)}</strong></div><div class="approval-fact"><span>Price</span><strong>${money(d.price)}</strong></div><div class="approval-fact"><span>Stock</span><strong>${escapeHtml(d.stock)}</strong></div><div class="approval-fact"><span>Seller</span><strong>${escapeHtml(d.seller)}</strong></div></div>
                    <h3>Quick checks</h3><ul class="approval-checks"><li><span class="${hasPhotos ? 'pass' : 'warn'}">${hasPhotos ? '✓' : '!'}</span>${hasPhotos ? 'Product photos uploaded' : 'Product photos are missing'}</li><li><span class="${priceInRange ? 'pass' : 'warn'}">${priceInRange ? '✓' : '!'}</span>${priceInRange ? 'Price is within the usual category range' : 'Price is outside the usual range or category data is limited'}</li><li><span class="${verified ? 'pass' : 'warn'}">${verified ? '✓' : '!'}</span>Seller ${verified ? 'is verified' : 'is not verified'}; ${escapeHtml(d.sellerApproved)} approved / ${escapeHtml(d.sellerRejected)} rejected (${escapeHtml(d.sellerProducts)} total)</li><li><span class="warn">!</span>${d.sku ? 'Shipping weight is not provided' : 'SKU and shipping weight are not provided'}</li></ul>
                    <h3>Description</h3><p class="approval-description">${escapeHtml(d.description || 'No description provided.')}</p>
                    ${document.querySelector('[data-reject-review]') ? `<label for="reviewRejectReason">Reason if rejecting</label><select class="approval-control" id="reviewRejectReason"><option value="">Choose a reason</option><option>Photos unclear or missing</option><option>Price looks incorrect</option><option>Description incomplete</option><option>Prohibited item</option><option>Other</option></select><label for="reviewRejectNote">Note to seller (optional)</label><textarea class="approval-control" id="reviewRejectNote" rows="3" placeholder="Add a helpful note"></textarea><div class="approval-panel-actions"><button class="approval-button reject" type="button" id="reviewRejectButton">Reject</button><button class="approval-button approve" type="button" id="reviewApproveButton">Approve and publish</button></div>` : ''}`;
                panel.hidden = false;
                panel.dataset.productId = d.id || button.closest('tr')?.dataset.productId || '';
                panel.scrollIntoView({behavior:'smooth',block:'nearest'});
                if (focusReason) setTimeout(() => document.getElementById('reviewRejectReason')?.focus(), 50);
                content.querySelectorAll('[data-photo]').forEach((thumb) => thumb.addEventListener('click', () => { document.getElementById('reviewMainPhoto').src = thumb.dataset.photo; content.querySelectorAll('[data-photo]').forEach((item) => item.classList.toggle('active', item === thumb)); }));
                document.getElementById('reviewApproveButton')?.addEventListener('click', () => postDecision(`/admin/product-approval/${panel.dataset.productId}/approve`, {confirmText:'Approve and publish this product?'}));
                document.getElementById('reviewRejectButton')?.addEventListener('click', () => {
                    const reason = document.getElementById('reviewRejectReason').value;
                    if (!reason) { document.getElementById('reviewRejectReason').focus(); showToast('Choose a rejection reason first.'); return; }
                    if (confirm('Reject this product and notify the seller?')) postDecision(`/admin/product-approval/${panel.dataset.productId}/reject`, {reason,note:document.getElementById('reviewRejectNote').value,confirmText:null});
                });
            };
            const postDecision = async (url, {action, ids, reason, note, confirmText} = {}) => {
                if (confirmText && !confirm(confirmText)) return;
                const routeId = Number(url.match(/product-approval\/(\d+)/)?.[1] || panel?.dataset.productId || 0);
                const rows = ids || [routeId];
                const rowNodes = rows.map((id) => document.querySelector(`tr[data-product-id="${id}"]`)).filter(Boolean);
                try {
                    const response = await fetch(url, {method:'POST',credentials:'same-origin',headers:{'X-CSRF-TOKEN':document.querySelector('meta[name="csrf-token"]')?.content || '', 'X-Requested-With':'XMLHttpRequest','Accept':'application/json','Content-Type':'application/json'},body:JSON.stringify({action,ids,reason,note})});
                    const result = await response.json().catch(() => null);
                    if (!response.ok) { showToast(result?.message || 'Could not save this review.', () => postDecision(url, {action,ids,reason,note})); return; }
                    rowNodes.forEach((row) => row.remove());
                    selectedIds.clear(); syncSelection(); panel.hidden = true; showToast(result?.message || 'Review saved.');
                    setTimeout(() => window.location.reload(), 650);
                } catch (error) { showToast('Connection error. Check your connection and retry.', () => postDecision(url, {action,ids,reason,note})); }
            };
            document.querySelectorAll('[data-review]').forEach((button) => button.addEventListener('click', () => openPanel(button)));
            document.querySelectorAll('[data-reject-review]').forEach((button) => button.addEventListener('click', () => openPanel(button.closest('tr').querySelector('[data-review]'), true)));
            document.querySelectorAll('[data-product-row]').forEach((row) => row.addEventListener('click', (event) => { if (event.target.closest('button,input,form,a')) return; const button=row.querySelector('[data-review]'); if (button) openPanel(button); }));
            document.querySelectorAll('[data-product-row]').forEach((row) => row.addEventListener('keydown', (event) => { if (event.key === 'Enter' && event.target === row) { event.preventDefault(); const button=row.querySelector('[data-review]'); if(button) openPanel(button); } }));
            document.getElementById('closeReviewPanel')?.addEventListener('click', closePanel);
            document.addEventListener('keydown', (event) => { if (event.key === 'Escape' && panel && !panel.hidden) closePanel(); });
            document.querySelectorAll('.row-check').forEach((checkbox) => checkbox.addEventListener('change', syncSelection));
            document.getElementById('selectPage')?.addEventListener('change', (event) => { document.querySelectorAll('.row-check:not(:disabled)').forEach((box) => box.checked = event.target.checked); syncSelection(); });
            document.getElementById('clearSelection')?.addEventListener('click', () => { document.querySelectorAll('.row-check').forEach((box) => box.checked = false); syncSelection(); });
            document.querySelectorAll('[data-bulk-action]').forEach((button) => button.addEventListener('click', () => {
                const ids = getSelected(); if (!ids.length) return;
                const action = button.dataset.bulkAction;
                if (action === 'approved') postDecision('/admin/product-approval/bulk', {action,ids,confirmText:`Approve and publish ${ids.length} selected product${ids.length === 1 ? '' : 's'}?`});
                else { bulkAction = ids; document.getElementById('bulkRejectCount').textContent = `${ids.length} selected product${ids.length === 1 ? '' : 's'} will be rejected.`; document.getElementById('bulkRejectDialog').showModal(); }
            }));
            document.querySelectorAll('[data-close-dialog]').forEach((button) => button.addEventListener('click', () => document.getElementById('bulkRejectDialog').close()));
            document.getElementById('bulkRejectForm')?.addEventListener('submit', (event) => { event.preventDefault(); const reason=document.getElementById('bulkRejectReason').value; if (!reason || !bulkAction?.length) return; const ids=bulkAction; document.getElementById('bulkRejectDialog').close(); postDecision('/admin/product-approval/bulk',{action:'rejected',ids,reason,note:document.getElementById('bulkRejectNote').value}); });
            document.querySelectorAll('[data-approve-form]').forEach((form) => form.addEventListener('submit', (event) => { event.preventDefault(); postDecision(form.action,{confirmText:'Approve and publish this product?'}); }));
            const filterForm = document.getElementById('approvalFilters');
            filterForm?.addEventListener('submit', () => { filterForm.setAttribute('aria-busy','true'); root.classList.add('is-loading'); });
            document.querySelectorAll('#approvalFilters select').forEach((input) => input.addEventListener('change', () => filterForm.requestSubmit()));
            document.getElementById('approvalSearch')?.addEventListener('keydown',(event) => { if(event.key==='Enter'){ filterForm?.requestSubmit(); } });
            document.querySelectorAll('.approval-pagination a:not([aria-disabled="true"])').forEach((link) => link.addEventListener('click', () => root.classList.add('is-loading')));
            document.querySelectorAll('.approval-tab').forEach((link) => link.addEventListener('click', () => root.classList.add('is-loading')));
        })();
    </script>
</x-admin-layout>
