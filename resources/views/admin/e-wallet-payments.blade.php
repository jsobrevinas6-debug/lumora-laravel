<x-admin-layout title="E-Wallet Payments">
    @php
        $page = $orders->currentPage();
        $lastPage = $orders->lastPage();
        $firstPage = max(1, $page - 1);
        $finalPage = min($lastPage, $page + 1);
        $pageLinks = collect(array_merge([1], range($firstPage, $finalPage), [$lastPage]))
            ->filter(fn ($number) => $number >= 1 && $number <= $lastPage)
            ->unique()
            ->sort()
            ->values();
        $from = $orders->total() ? (($page - 1) * $orders->perPage()) + 1 : 0;
        $to = min($page * $orders->perPage(), $orders->total());
        $filterParams = $filters;
        unset($filterParams['page'], $filterParams['per_page']);
    @endphp

    <style>
        .ewallet-head { display:flex; justify-content:space-between; align-items:flex-start; gap:16px; flex-wrap:wrap; }
        .ewallet-head h2 { margin-bottom:8px; }
        .ewallet-subtitle { color:var(--text-muted); margin:-2px 0 18px; font-size:.9rem; }
        .ewallet-toolbar { display:flex; align-items:flex-end; gap:12px; flex-wrap:wrap; margin:18px 0 16px; }
        .ewallet-field { display:grid; gap:5px; color:var(--text-dark); font-size:12px; font-weight:600; }
        .ewallet-field input,.ewallet-field select { min-height:44px; border:1px solid #E6D3CC; border-radius:9px; padding:8px 11px; background:#fff; color:var(--text-dark); font:inherit; font-size:13px; }
        .ewallet-field input { width:min(330px,70vw); }
        .ewallet-field select { min-width:142px; }
        .ewallet-field input:focus-visible,.ewallet-field select:focus-visible,.ewallet-button:focus-visible,.ewallet-tabs a:focus-visible,.pagination-link:focus-visible,.detail-toggle:focus-visible,.copy-ref:focus-visible,.rows-form select:focus-visible { outline:2px solid var(--maroon); outline-offset:2px; }
        .ewallet-button { min-height:44px; display:inline-flex; align-items:center; justify-content:center; border:1px solid var(--maroon); border-radius:9px; padding:8px 14px; background:#fff; color:var(--maroon); font:inherit; font-size:13px; font-weight:600; text-decoration:none; cursor:pointer; }
        .ewallet-button:hover { background:#F6EAE5; }
        .ewallet-button.primary { background:#5C1A33; color:#fff; }
        .ewallet-button.primary:hover { background:#3D0F22; }
        .ewallet-tabs { display:flex; flex-wrap:wrap; gap:8px; margin-top:18px; }
        .ewallet-tabs a { min-height:44px; display:inline-flex; align-items:center; gap:8px; border:1px solid #EBD9D3; border-radius:999px; padding:7px 13px; color:#4A3A3D; background:#F6EAE5; text-decoration:none; font-size:13px; font-weight:600; }
        .ewallet-tabs a.active { border-color:#5C1A33; background:#5C1A33; color:#fff; }
        .ewallet-count { min-width:22px; padding:1px 6px; border-radius:999px; background:rgba(91,26,53,.1); text-align:center; font-size:11px; }
        .ewallet-tabs a.active .ewallet-count { background:rgba(255,255,255,.2); }
        .ewallet-table-wrap { width:100%; overflow-x:auto; border:1px solid #EBD9D3; border-radius:12px; }
        .ewallet-table { min-width:1040px; width:100%; border-collapse:collapse; }
        .ewallet-table thead { background:#F6EAE5; }
        .ewallet-table th,.ewallet-table td { padding:12px 11px; border-bottom:1px solid #F1E3DE; text-align:left; vertical-align:middle; font-size:12.5px; }
        .ewallet-table th { color:#4A3A3D; font-size:12px; font-weight:700; white-space:nowrap; }
        .ewallet-table tbody tr:last-child > td { border-bottom:0; }
        .ewallet-table tbody tr.order-row.expanded > td { background:#FBF3F0; }
        .order-number { display:block; color:#2B1D20; font-weight:700; white-space:nowrap; }
        .muted-text { display:block; margin-top:3px; color:#6E5E61; font-size:11.5px; }
        .status-chip,.method-chip { display:inline-flex; align-items:center; min-height:26px; border-radius:999px; padding:4px 9px; font-size:11.5px; font-weight:700; white-space:nowrap; }
        .method-gcash { background:#E6F0FF; color:#1B4F9C; }
        .method-maya { background:#E4F7EC; color:#1E6B45; }
        .payment-review { background:#FFF1D6; color:#7A4F00; }
        .payment-verified { background:#E3F3EA; color:#1F6B47; }
        .payment-missing { background:#FCE4E4; color:#7C2020; }
        .payment-other { background:#F2ECEE; color:#4A3A3D; }
        .detail-toggle { min-height:44px; border:0; background:transparent; color:#5C1A33; font:inherit; font-size:12.5px; font-weight:700; text-decoration:underline; text-underline-offset:3px; cursor:pointer; }
        .detail-row[hidden] { display:none; }
        .detail-cell { padding:0 12px 14px !important; background:#FBF3F0; }
        .detail-panel { display:grid; grid-template-columns:repeat(3,minmax(0,1fr)); gap:16px; border:1px solid #EBD9D3; border-radius:14px; padding:16px; background:#FFFDFC; }
        .detail-panel h3 { margin:0 0 9px; color:#2B1D20; font-size:13px; }
        .detail-panel p,.detail-panel li { color:#4A3A3D; font-size:12px; line-height:1.6; overflow-wrap:anywhere; }
        .detail-panel p { margin:0 0 5px; }
        .detail-panel ul { margin:0; padding-left:17px; }
        .copy-ref { min-height:44px; margin-left:6px; border:1px solid #EBD9D3; border-radius:7px; padding:4px 9px; background:#fff; color:#5C1A33; font:inherit; font-size:11px; cursor:pointer; }
        .receipt-image { display:block; max-width:100%; max-height:190px; margin:7px 0 12px; border:1px solid #EBD9D3; border-radius:9px; object-fit:contain; }
        .receipt-alert { margin:8px 0 12px !important; padding:10px 11px; border-radius:9px; background:#FCE4E4; color:#7C2020 !important; }
        .detail-actions { display:flex; gap:8px; flex-wrap:wrap; }
        .detail-actions form { margin:0; }
        .detail-actions .ewallet-button { min-height:44px; }
        .ewallet-button.danger { border-color:#A33B39; color:#7C2020; }
        .ewallet-button:disabled { opacity:.48; cursor:not-allowed; }
        .ewallet-footer { display:flex; align-items:center; justify-content:space-between; gap:16px; flex-wrap:wrap; margin-top:16px; color:#4A3A3D; font-size:12.5px; }
        .rows-form { display:flex; align-items:center; gap:8px; }
        .rows-form select { min-height:44px; border:1px solid #E6D3CC; border-radius:8px; padding:6px 9px; background:#fff; font:inherit; }
        .pagination-links { display:flex; align-items:center; gap:5px; flex-wrap:wrap; }
        .pagination-link { min-width:40px; min-height:44px; display:inline-flex; align-items:center; justify-content:center; border:1px solid #EBD9D3; border-radius:8px; padding:6px 10px; background:#fff; color:#4A3A3D; text-decoration:none; }
        .pagination-link.current { border-color:#5C1A33; background:#5C1A33; color:#fff; }
        .pagination-link.disabled { color:#9A8B8E; background:#F7F2F0; }
        .pagination-gap { min-width:22px; text-align:center; color:#6E5E61; }
        .empty-state { padding:36px 16px; color:#4A3A3D; text-align:center; }
        .empty-state h3 { margin:0 0 6px; font-size:17px; }
        .empty-state p { margin:0 0 14px; color:#6E5E61; font-size:13px; }
        .export-button { white-space:nowrap; }
        @media(max-width:760px) { .detail-panel { grid-template-columns:1fr; } .ewallet-footer { align-items:flex-start; } }
    </style>

    <div class="panel">
        <div class="ewallet-head">
            <div>
                <h2>Buyer payment submissions</h2>
                <p class="ewallet-subtitle">GCash and Maya orders with buyer details and payment proof.</p>
            </div>
            <a class="ewallet-button export-button" href="{{ route('admin.e-wallet-payments.export', $filterParams) }}">Export CSV</a>
        </div>

        <nav class="ewallet-tabs" aria-label="Payment submission status filters">
            @foreach (['all' => 'All', 'review' => 'To review', 'verified' => 'Verified', 'missing' => 'Receipt missing'] as $key => $label)
                <a href="{{ route('admin.e-wallet-payments', array_merge($filters, ['status' => $key, 'page' => 1])) }}" class="{{ $filters['status'] === $key ? 'active' : '' }}">
                    {{ $label }} <span class="ewallet-count">{{ number_format($tabCounts[$key]) }}</span>
                </a>
            @endforeach
        </nav>

        <form class="ewallet-toolbar" method="GET" action="{{ route('admin.e-wallet-payments') }}">
            <input type="hidden" name="page" value="1">
            <input type="hidden" name="per_page" value="{{ $filters['per_page'] }}">
            <input type="hidden" name="status" value="{{ $filters['status'] }}">
            <label class="ewallet-field">Search
                <input type="search" name="q" value="{{ $filters['q'] }}" maxlength="120" placeholder="Order, buyer, email, or reference">
            </label>
            <label class="ewallet-field">Method
                <select name="method">
                    <option value="all" @selected($filters['method'] === 'all')>All methods</option>
                    <option value="gcash" @selected($filters['method'] === 'gcash')>GCash</option>
                    <option value="maya" @selected($filters['method'] === 'maya')>Maya</option>
                </select>
            </label>
            <label class="ewallet-field">Date range
                <select name="range">
                    <option value="30" @selected($filters['range'] === '30')>Last 30 days</option>
                    <option value="7" @selected($filters['range'] === '7')>Last 7 days</option>
                    <option value="today" @selected($filters['range'] === 'today')>Today</option>
                </select>
            </label>
            <label class="ewallet-field">Sort
                <select name="sort">
                    <option value="attention" @selected($filters['sort'] === 'attention')>Needs attention first</option>
                    <option value="newest" @selected($filters['sort'] === 'newest')>Newest first</option>
                    <option value="oldest" @selected($filters['sort'] === 'oldest')>Oldest first</option>
                    <option value="amount" @selected($filters['sort'] === 'amount')>Amount high to low</option>
                </select>
            </label>
            <button class="ewallet-button primary" type="submit">Apply filters</button>
        </form>

        @if ($orders->isEmpty())
            <div class="empty-state">
                <h3>No payment submissions match your filters</h3>
                <p>Try another search or clear the filters to see more e-wallet orders.</p>
                <a class="ewallet-button" href="{{ route('admin.e-wallet-payments') }}">Clear filters</a>
            </div>
        @else
            <div class="ewallet-table-wrap">
                <table class="ewallet-table">
                    <thead>
                        <tr>
                            <th>Order</th><th>Buyer</th><th>Seller</th><th>Method</th><th>Amount</th><th>Order status</th><th>Payment</th><th>Action</th>
                        </tr>
                    </thead>
                    <tbody>
                        @foreach ($orders as $order)
                            @php
                                $methodLabel = in_array($order->payment_method, ['maya', 'paymaya'], true) ? 'Maya' : 'GCash';
                                $paymentLabel = $order->payment_status === 'paid' ? 'Verified' : (! $order->payment_proof_available ? 'Receipt missing' : ($order->payment_status === 'pending' ? 'To review' : ucfirst($order->payment_status)));
                                $paymentClass = $paymentLabel === 'Verified' ? 'payment-verified' : ($paymentLabel === 'Receipt missing' ? 'payment-missing' : ($paymentLabel === 'To review' ? 'payment-review' : 'payment-other'));
                                $canVerify = $order->payment_status === 'pending' && $order->status === 'pending' && $order->payment_proof_available && preg_match('/^\d{6}$/', (string) $order->payment_reference_last6);
                            @endphp
                            <tr class="order-row" data-order-row="{{ $order->id }}">
                                <td><span class="order-number">{{ $order->order_number }}</span><span class="muted-text">{{ $order->created_at?->format('M j, Y g:i A') }}</span></td>
                                <td>{{ $order->user?->name ?? 'Unknown buyer' }}<span class="muted-text">{{ $order->user?->email ?? 'Email unavailable' }}</span></td>
                                <td>{{ $order->seller?->name ?? 'Multiple / unavailable' }}</td>
                                <td><span class="method-chip {{ $methodLabel === 'Maya' ? 'method-maya' : 'method-gcash' }}">{{ $methodLabel }}</span></td>
                                <td><strong>PHP {{ number_format((float) $order->total, 2) }}</strong></td>
                                <td>{{ $order->status_label }}</td>
                                <td><span class="status-chip {{ $paymentClass }}">{{ $paymentLabel }}</span></td>
                                <td><button type="button" class="detail-toggle" data-detail-toggle="{{ $order->id }}" aria-expanded="false">{{ $paymentLabel === 'Verified' ? 'View' : 'Review' }}</button></td>
                            </tr>
                            <tr class="detail-row" data-detail-panel="{{ $order->id }}" hidden>
                                <td colspan="8" class="detail-cell">
                                    <div class="detail-panel">
                                        <section>
                                            <h3>Buyer and reference</h3>
                                            <p><strong>{{ $order->user?->name ?? 'Unknown buyer' }}</strong></p>
                                            <p>{{ $order->user?->email ?? 'Email unavailable' }}</p>
                                            <p>Reference: @if ($order->payment_reference_last6)<span>&bull;&bull;{{ $order->payment_reference_last6 }}</span><button class="copy-ref" type="button" data-copy-ref="{{ $order->payment_reference_last6 }}" aria-label="Copy reference number">Copy</button>@else Not provided @endif</p>
                                            <p>Payment method: {{ $methodLabel }}</p>
                                        </section>
                                        <section>
                                            <h3>Order details</h3>
                                            <ul>
                                                @foreach ($order->items as $item)
                                                    <li>{{ $item->product?->name ?? 'Product unavailable' }} &times; {{ $item->quantity }} &mdash; PHP {{ number_format((float) $item->subtotal, 2) }}</li>
                                                @endforeach
                                            </ul>
                                            <p style="margin-top:8px">Subtotal: PHP {{ number_format((float) $order->subtotal, 2) }}</p>
                                            <p>Shipping: PHP {{ number_format((float) $order->shipping_fee, 2) }}</p>
                                            <p><strong>Total: PHP {{ number_format((float) $order->total, 2) }}</strong></p>
                                        </section>
                                        <section>
                                            <h3>Payment screenshot</h3>
                                            @if ($order->payment_proof_available)
                                                <a href="{{ route('admin.e-wallet-payments.proof', $order) }}" target="_blank" rel="noopener"><img class="receipt-image" src="{{ route('admin.e-wallet-payments.proof', $order) }}" alt="Payment receipt for order {{ $order->order_number }}"></a>
                                            @else
                                                <p class="receipt-alert" role="alert">The receipt file is missing from storage. Ask the buyer to submit the receipt again.</p>
                                            @endif
                                            <div class="detail-actions">
                                                <button class="ewallet-button primary" type="button" disabled title="Buyer receipt notifications are not available yet">Request receipt again</button>
                                                @if ($order->payment_status === 'pending' && $order->status === 'pending')
                                                    <form method="POST" action="{{ route('admin.e-wallet-payments.approve', $order) }}">
                                                        @csrf
                                                        <button class="ewallet-button" type="submit" @disabled(!$canVerify)>Verify payment</button>
                                                    </form>
                                                    <form method="POST" action="{{ route('admin.e-wallet-payments.reject', $order) }}" onsubmit="return confirm('Reject this payment and cancel this order?')">
                                                        @csrf
                                                        <button class="ewallet-button danger" type="submit">Reject</button>
                                                    </form>
                                                @else
                                                    <span class="muted-text">{{ $paymentLabel }}</span>
                                                @endif
                                            </div>
                                        </section>
                                    </div>
                                </td>
                            </tr>
                        @endforeach
                    </tbody>
                </table>
            </div>

            <div class="ewallet-footer">
                <div style="display:flex;align-items:center;gap:18px;flex-wrap:wrap">
                    <span>Showing {{ $from }}&ndash;{{ $to }} of {{ number_format($orders->total()) }} orders</span>
                    <form class="rows-form" method="GET" action="{{ route('admin.e-wallet-payments') }}">
                        <input type="hidden" name="page" value="1">
                        @foreach ($filterParams as $key => $value)<input type="hidden" name="{{ $key }}" value="{{ $value }}">@endforeach
                        <label for="rows-per-page">Rows per page</label>
                        <select id="rows-per-page" name="per_page" onchange="this.form.submit()">
                            @foreach ([8, 16, 32] as $size)<option value="{{ $size }}" @selected($orders->perPage() === $size)>{{ $size }}</option>@endforeach
                        </select>
                    </form>
                </div>
                @if ($orders->lastPage() > 1)
                    <nav class="pagination-links" aria-label="Pagination">
                        @if ($page > 1)
                            <a class="pagination-link" href="{{ $orders->url($page - 1) }}" rel="prev" aria-label="Previous page">Prev</a>
                        @else
                            <span class="pagination-link disabled" aria-disabled="true">Prev</span>
                        @endif
                        @php $previous = null; @endphp
                        @foreach ($pageLinks as $pageLink)
                            @if ($previous !== null && $pageLink > $previous + 1)<span class="pagination-gap" aria-hidden="true">&hellip;</span>@endif
                            <a class="pagination-link {{ $pageLink === $page ? 'current' : '' }}" href="{{ $orders->url($pageLink) }}" @if($pageLink === $page) aria-current="page" @endif>{{ $pageLink }}</a>
                            @php $previous = $pageLink; @endphp
                        @endforeach
                        @if ($page < $orders->lastPage())
                            <a class="pagination-link" href="{{ $orders->url($page + 1) }}" rel="next" aria-label="Next page">Next</a>
                        @else
                            <span class="pagination-link disabled" aria-disabled="true">Next</span>
                        @endif
                    </nav>
                @endif
            </div>
        @endif
    </div>

    <script>
        document.querySelectorAll('[data-detail-toggle]').forEach(button => {
            button.addEventListener('click', () => {
                const id = button.dataset.detailToggle;
                const panel = document.querySelector(`[data-detail-panel="${id}"]`);
                const shouldOpen = panel.hidden;

                document.querySelectorAll('[data-detail-panel]').forEach(item => item.hidden = true);
                document.querySelectorAll('[data-detail-toggle]').forEach(item => {
                    item.setAttribute('aria-expanded', 'false');
                    item.closest('.order-row')?.classList.remove('expanded');
                });

                panel.hidden = !shouldOpen;
                button.setAttribute('aria-expanded', shouldOpen ? 'true' : 'false');
                button.closest('.order-row')?.classList.toggle('expanded', shouldOpen);
            });
        });

        document.querySelectorAll('[data-copy-ref]').forEach(button => {
            button.addEventListener('click', async () => {
                try {
                    await navigator.clipboard.writeText(button.dataset.copyRef);
                    button.textContent = 'Copied';
                    window.setTimeout(() => button.textContent = 'Copy', 1500);
                } catch (_) {
                    button.textContent = 'Copy unavailable';
                }
            });
        });
    </script>
</x-admin-layout>
