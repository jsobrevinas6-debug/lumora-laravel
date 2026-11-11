@extends('layouts.seller')

@section('title', 'Return / Refund Requests')

@section('content')
    @if (session('success'))
        <div class="alert-success" style="display:flex;align-items:center;gap:10px;margin-bottom:20px;">
            <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M22 11.08V12a10 10 0 1 1-5.93-9.14"/><polyline points="22 4 12 14.01 9 11.01"/></svg>
            <span>{{ session('success') }}</span>
        </div>
    @endif

    @if (session('error'))
        <div class="alert-error" style="display:flex;align-items:center;gap:10px;margin-bottom:20px;">
            <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><circle cx="12" cy="12" r="10"/><line x1="12" y1="8" x2="12" y2="12"/><line x1="12" y1="16" x2="12.01" y2="16"/></svg>
            <span>{{ session('error') }}</span>
        </div>
    @endif

    @if ($errors->any())
        <div class="alert-error" style="display:flex;align-items:center;gap:10px;margin-bottom:20px;">
            <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><circle cx="12" cy="12" r="10"/><line x1="12" y1="8" x2="12" y2="12"/><line x1="12" y1="16" x2="12.01" y2="16"/></svg>
            <span>{{ $errors->first() }}</span>
        </div>
    @endif

    <style>
        .returns-header-wrap {
            display: flex;
            justify-content: space-between;
            align-items: flex-start;
            flex-wrap: wrap;
            gap: 16px;
            margin-bottom: 24px;
        }
        .returns-title-sub {
            color: var(--text-muted);
            font-size: 13.5px;
            margin-top: 4px;
            max-width: 650px;
            line-height: 1.5;
        }
        .returns-kpi-grid {
            display: grid;
            grid-template-columns: repeat(4, 1fr);
            gap: 18px;
            margin-bottom: 24px;
        }
        @media (max-width: 1024px) {
            .returns-kpi-grid { grid-template-columns: repeat(2, 1fr); }
        }
        @media (max-width: 600px) {
            .returns-kpi-grid { grid-template-columns: 1fr; }
        }
        .returns-kpi-card {
            background: var(--card-bg);
            border: 1px solid var(--border);
            border-radius: var(--radius);
            padding: 20px;
            display: flex;
            align-items: center;
            gap: 16px;
            box-shadow: 0 4px 18px rgba(91,26,53,.03);
            text-decoration: none;
            color: inherit;
            transition: transform .15s ease, box-shadow .15s ease, border-color .15s ease;
        }
        .returns-kpi-card:hover {
            transform: translateY(-2px);
            box-shadow: 0 6px 22px rgba(91,26,53,.07);
            border-color: var(--maroon);
        }
        .returns-kpi-card.active-kpi {
            border-color: var(--maroon);
            background: #FFFBF9;
            box-shadow: 0 4px 20px rgba(91,26,53,.08);
        }
        .returns-kpi-icon {
            width: 46px;
            height: 46px;
            border-radius: 12px;
            display: flex;
            align-items: center;
            justify-content: center;
            font-size: 20px;
            flex-shrink: 0;
        }
        .kpi-icon-all { background: linear-gradient(135deg, #7C9473, #5C7355); color: #fff; }
        .kpi-icon-pending { background: linear-gradient(135deg, #E8674A, #B85C3B); color: #fff; }
        .kpi-icon-approved { background: linear-gradient(135deg, #2261a8, #18487e); color: #fff; }
        .kpi-icon-denied { background: linear-gradient(135deg, #8B7A80, #5B1A35); color: #fff; }

        .returns-kpi-meta { display: flex; flex-direction: column; min-width: 0; }
        .returns-kpi-val { font-size: 24px; font-weight: 800; line-height: 1.1; color: var(--text-dark); }
        .returns-kpi-label { font-size: 12.5px; color: var(--text-muted); font-weight: 500; margin-top: 3px; }

        .returns-toolbar {
            display: flex;
            justify-content: space-between;
            align-items: center;
            gap: 16px;
            flex-wrap: wrap;
            margin-bottom: 20px;
        }
        .returns-tabs {
            display: flex;
            gap: 8px;
            flex-wrap: wrap;
            align-items: center;
        }
        .returns-tab-btn {
            display: inline-flex;
            align-items: center;
            gap: 7px;
            padding: 8px 16px;
            border-radius: 999px;
            background: #fff;
            border: 1px solid var(--border);
            color: var(--text-muted);
            text-decoration: none;
            font-size: 13px;
            font-weight: 600;
            transition: all .15s ease;
        }
        .returns-tab-btn:hover {
            border-color: var(--maroon);
            color: var(--maroon);
        }
        .returns-tab-btn.active {
            background: var(--maroon);
            border-color: var(--maroon);
            color: #fff;
        }
        .returns-tab-badge {
            display: inline-block;
            padding: 1px 7px;
            border-radius: 999px;
            font-size: 11px;
            font-weight: 700;
            background: var(--bg);
            color: var(--text-dark);
        }
        .returns-tab-btn.active .returns-tab-badge {
            background: rgba(255,255,255,0.25);
            color: #fff;
        }
        .returns-tab-badge.badge-alert {
            background: var(--coral);
            color: #fff;
        }
        .returns-search-form {
            display: flex;
            gap: 8px;
            align-items: center;
        }
        .returns-search-input {
            padding: 8px 14px;
            border: 1px solid var(--border);
            border-radius: 999px;
            font-size: 13px;
            background: #fff;
            width: 250px;
            font-family: inherit;
        }
        .returns-search-input:focus {
            outline: none;
            border-color: var(--maroon);
        }

        .returns-table {
            width: 100%;
            border-collapse: separate;
            border-spacing: 0;
        }
        .returns-table th {
            background: #FAF5F2;
            padding: 12px 14px;
            font-size: 12px;
            font-weight: 700;
            text-transform: uppercase;
            letter-spacing: .03em;
            color: var(--text-muted);
            border-bottom: 1px solid var(--border);
            text-align: left;
            white-space: nowrap;
        }
        .returns-table td {
            padding: 14px;
            border-bottom: 1px solid var(--border);
            font-size: 13.5px;
            vertical-align: top;
            background: #fff;
        }
        .returns-table tr:hover td {
            background: #FFFDFB;
        }
        .returns-table tr:last-child td {
            border-bottom: none;
        }

        .order-link {
            font-weight: 700;
            color: var(--maroon);
            text-decoration: none;
            display: inline-flex;
            align-items: center;
            gap: 4px;
        }
        .order-link:hover {
            text-decoration: underline;
        }
        .buyer-name { font-weight: 600; color: var(--text-dark); }
        .buyer-sub { font-size: 12px; color: var(--text-muted); margin-top: 2px; }

        .reason-badge {
            display: inline-block;
            padding: 3px 10px;
            border-radius: 6px;
            font-size: 12px;
            font-weight: 600;
            background: #FFF0EB;
            color: var(--terra-2);
            border: 1px solid #FCD9CC;
            margin-bottom: 4px;
        }
        .reason-details {
            font-size: 12.5px;
            color: var(--text-dark);
            line-height: 1.45;
            max-width: 280px;
            word-break: break-word;
        }
        .review-note-box {
            margin-top: 6px;
            padding: 6px 10px;
            background: #F8F8F9;
            border-left: 3px solid var(--text-muted);
            border-radius: 4px;
            font-size: 11.5px;
            color: var(--text-muted);
            line-height: 1.4;
        }

        .items-pill-list {
            display: flex;
            flex-direction: column;
            gap: 4px;
            max-width: 220px;
        }
        .item-pill-row {
            font-size: 12px;
            color: var(--text-dark);
            line-height: 1.35;
        }

        .proof-trigger-btn {
            display: inline-flex;
            align-items: center;
            gap: 6px;
            padding: 5px 10px;
            border-radius: 8px;
            background: #fff;
            border: 1px solid var(--border);
            font-size: 12px;
            font-weight: 600;
            color: var(--maroon);
            cursor: pointer;
            transition: all .15s ease;
        }
        .proof-trigger-btn:hover {
            background: var(--bg);
            border-color: var(--maroon);
        }

        .action-btn-group {
            display: flex;
            flex-direction: column;
            gap: 6px;
            min-width: 110px;
        }
        .btn-action-approve {
            background: #065F46;
            color: #fff;
            border: none;
            padding: 7px 12px;
            border-radius: 8px;
            font-size: 12.5px;
            font-weight: 600;
            cursor: pointer;
            transition: background .15s ease;
            display: inline-flex;
            align-items: center;
            justify-content: center;
            gap: 4px;
            width: 100%;
        }
        .btn-action-approve:hover { background: #044E3A; }

        .btn-action-deny {
            background: #fff;
            color: #DC2626;
            border: 1px solid #FCA5A5;
            padding: 6px 12px;
            border-radius: 8px;
            font-size: 12.5px;
            font-weight: 600;
            cursor: pointer;
            transition: all .15s ease;
            display: inline-flex;
            align-items: center;
            justify-content: center;
            gap: 4px;
            width: 100%;
        }
        .btn-action-deny:hover { background: #FEF2F2; border-color: #DC2626; }

        /* Modal Styles */
        .returns-modal-overlay {
            display: none;
            position: fixed;
            inset: 0;
            background: rgba(43,28,34,.55);
            backdrop-filter: blur(3px);
            align-items: center;
            justify-content: center;
            z-index: 100;
            padding: 20px;
        }
        .returns-modal-box {
            background: #fff;
            border-radius: 18px;
            width: 520px;
            max-width: 100%;
            max-height: 90vh;
            overflow-y: auto;
            box-shadow: 0 12px 36px rgba(91,26,53,.2);
            border: 1px solid var(--border);
            animation: modalFadeIn .2s ease;
        }
        @keyframes modalFadeIn {
            from { opacity: 0; transform: scale(.96); }
            to { opacity: 1; transform: scale(1); }
        }
        .returns-modal-header {
            padding: 20px 24px;
            border-bottom: 1px solid var(--border);
            display: flex;
            justify-content: space-between;
            align-items: center;
        }
        .returns-modal-header h3 {
            font-size: 17px;
            font-weight: 800;
            color: var(--text-dark);
            margin: 0;
        }
        .returns-modal-close {
            background: none;
            border: none;
            font-size: 22px;
            cursor: pointer;
            color: var(--text-muted);
            line-height: 1;
            padding: 4px;
            border-radius: 6px;
        }
        .returns-modal-close:hover { color: var(--maroon); background: var(--bg); }
        .returns-modal-body { padding: 22px 24px; }
        .returns-modal-footer {
            padding: 16px 24px;
            border-top: 1px solid var(--border);
            display: flex;
            justify-content: flex-end;
            gap: 10px;
            background: #FAF7F5;
            border-radius: 0 0 18px 18px;
        }

        .proof-gallery-grid {
            display: grid;
            grid-template-columns: repeat(auto-fill, minmax(130px, 1fr));
            gap: 12px;
            margin-top: 12px;
        }
        .proof-card {
            border: 1px solid var(--border);
            border-radius: 10px;
            overflow: hidden;
            background: var(--bg);
            transition: transform .15s ease, box-shadow .15s ease;
        }
        .proof-card:hover {
            transform: scale(1.02);
            box-shadow: 0 4px 14px rgba(91,26,53,.08);
        }
        .proof-card img {
            width: 100%;
            height: 120px;
            object-fit: cover;
            display: block;
            cursor: pointer;
        }
        .proof-card video {
            width: 100%;
            height: 120px;
            background: #000;
            display: block;
        }
        .proof-card-footer {
            padding: 6px 8px;
            font-size: 11px;
            text-align: center;
            background: #fff;
            border-top: 1px solid var(--border);
            color: var(--maroon);
            font-weight: 600;
            text-decoration: none;
            display: block;
        }
        .proof-card-footer:hover { background: var(--bg); }
    </style>

    <!-- Top Header -->
    <div class="returns-header-wrap">
        <div>
            <h1 style="font-size:26px;font-weight:800;color:var(--text-dark);margin:0;">Customer Return & Refund Hub</h1>
            <p class="returns-title-sub">
                Review, investigate, and process return or refund claims filed by buyers for your items. Approving a return initiates a reverse logistics pickup via Lumora Logistics.
            </p>
        </div>

        <div style="display:flex;gap:10px;align-items:center;">
            <a href="{{ route('seller.orders.index', ['status' => 'returns']) }}" class="btn-outline" style="text-decoration:none;font-size:13px;display:inline-flex;align-items:center;gap:6px;">
                <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><rect x="5" y="3" width="14" height="18" rx="2"/><path d="M8 7h8M8 11h8M8 15h5"/></svg>
                <span>View in Orders Tab</span>
            </a>
        </div>
    </div>

    <!-- KPI Summary Cards -->
    <div class="returns-kpi-grid">
        <a href="{{ route('seller.returns.index', ['status' => 'all']) }}" class="returns-kpi-card {{ $status === 'all' ? 'active-kpi' : '' }}">
            <div class="returns-kpi-icon kpi-icon-all">
                ↺
            </div>
            <div class="returns-kpi-meta">
                <span class="returns-kpi-val">{{ number_format($tabCounts['all'] ?? 0) }}</span>
                <span class="returns-kpi-label">Total Requests</span>
            </div>
        </a>

        <a href="{{ route('seller.returns.index', ['status' => 'pending']) }}" class="returns-kpi-card {{ $status === 'pending' ? 'active-kpi' : '' }}">
            <div class="returns-kpi-icon kpi-icon-pending">
                ⚠️
            </div>
            <div class="returns-kpi-meta">
                <span class="returns-kpi-val" style="{{ ($tabCounts['pending'] ?? 0) > 0 ? 'color:var(--coral);' : '' }}">
                    {{ number_format($tabCounts['pending'] ?? 0) }}
                </span>
                <span class="returns-kpi-label">Pending Review</span>
            </div>
        </a>

        <a href="{{ route('seller.returns.index', ['status' => 'approved']) }}" class="returns-kpi-card {{ $status === 'approved' ? 'active-kpi' : '' }}">
            <div class="returns-kpi-icon kpi-icon-approved">
                ✓
            </div>
            <div class="returns-kpi-meta">
                <span class="returns-kpi-val">{{ number_format($tabCounts['approved'] ?? 0) }}</span>
                <span class="returns-kpi-label">Approved & Queued</span>
            </div>
        </a>

        <a href="{{ route('seller.returns.index', ['status' => 'denied']) }}" class="returns-kpi-card {{ $status === 'denied' ? 'active-kpi' : '' }}">
            <div class="returns-kpi-icon kpi-icon-denied">
                ✕
            </div>
            <div class="returns-kpi-meta">
                <span class="returns-kpi-val">{{ number_format($tabCounts['denied'] ?? 0) }}</span>
                <span class="returns-kpi-label">Denied Claims</span>
            </div>
        </a>
    </div>

    <!-- Filter Tabs & Search Bar -->
    <div class="returns-toolbar">
        <div class="returns-tabs">
            <a href="{{ route('seller.returns.index', array_merge(request()->except(['status', 'page']), ['status' => 'all'])) }}"
               class="returns-tab-btn {{ $status === 'all' ? 'active' : '' }}">
                <span>All</span>
                <span class="returns-tab-badge">{{ $tabCounts['all'] ?? 0 }}</span>
            </a>

            <a href="{{ route('seller.returns.index', array_merge(request()->except(['status', 'page']), ['status' => 'pending'])) }}"
               class="returns-tab-btn {{ $status === 'pending' ? 'active' : '' }}">
                <span>Pending Review</span>
                <span class="returns-tab-badge {{ ($tabCounts['pending'] ?? 0) > 0 && $status !== 'pending' ? 'badge-alert' : '' }}">
                    {{ $tabCounts['pending'] ?? 0 }}
                </span>
            </a>

            <a href="{{ route('seller.returns.index', array_merge(request()->except(['status', 'page']), ['status' => 'approved'])) }}"
               class="returns-tab-btn {{ $status === 'approved' ? 'active' : '' }}">
                <span>Approved</span>
                <span class="returns-tab-badge">{{ $tabCounts['approved'] ?? 0 }}</span>
            </a>

            <a href="{{ route('seller.returns.index', array_merge(request()->except(['status', 'page']), ['status' => 'denied'])) }}"
               class="returns-tab-btn {{ $status === 'denied' ? 'active' : '' }}">
                <span>Denied</span>
                <span class="returns-tab-badge">{{ $tabCounts['denied'] ?? 0 }}</span>
            </a>
        </div>

        <form method="GET" action="{{ route('seller.returns.index') }}" class="returns-search-form">
            @if ($status !== 'all')
                <input type="hidden" name="status" value="{{ $status }}">
            @endif
            <input type="text"
                   name="search"
                   value="{{ $search ?? '' }}"
                   placeholder="Search order #, buyer, reason..."
                   class="returns-search-input">
            <button type="submit" class="btn-solid" style="padding:8px 16px;min-height:36px;font-size:13px;">
                Search
            </button>
            @if (!empty($search))
                <a href="{{ route('seller.returns.index', ['status' => $status]) }}" class="btn-outline" style="padding:8px 12px;min-height:36px;font-size:13px;text-decoration:none;">
                    Clear
                </a>
            @endif
        </form>
    </div>

    <!-- Main Table Panel -->
    <div class="panel" style="padding:0;overflow:hidden;border:1px solid var(--border);">
        <div style="overflow-x:auto;">
            <table class="returns-table">
                <thead>
                    <tr>
                        <th style="width:140px;">Submitted</th>
                        <th style="width:160px;">Order Details</th>
                        <th style="width:180px;">Buyer</th>
                        <th style="min-width:240px;">Return Reason & Explanation</th>
                        <th style="width:200px;">Your Items</th>
                        <th style="width:130px;">Evidence</th>
                        <th style="width:120px;">Status</th>
                        <th style="width:120px;">Logistics</th>
                        <th style="width:140px;text-align:right;">Actions</th>
                    </tr>
                </thead>
                <tbody>
                    @forelse ($requests as $returnRequest)
                        @php
                            $sellerItems = $returnRequest->order->items->where('seller_id', auth()->id());
                            $evidenceList = $returnRequest->evidence->map(function ($ev) use ($returnRequest) {
                                return [
                                    'id' => $ev->id,
                                    'mime_type' => $ev->mime_type,
                                    'url' => route('seller.returns.evidence', [$returnRequest, $ev->id]),
                                    'is_image' => str_starts_with($ev->mime_type, 'image/'),
                                ];
                            });
                        @endphp
                        <tr>
                            <!-- Submitted Date -->
                            <td>
                                <div style="font-weight:600;color:var(--text-dark);">
                                    {{ $returnRequest->created_at->format('M d, Y') }}
                                </div>
                                <div style="font-size:11.5px;color:var(--text-muted);margin-top:2px;">
                                    {{ $returnRequest->created_at->format('g:i A') }}
                                </div>
                            </td>

                            <!-- Order Details -->
                            <td>
                                <a href="{{ route('seller.orders.show', $returnRequest->order_id) }}" class="order-link">
                                    <span>#{{ $returnRequest->order->order_number }}</span>
                                    <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><path d="M18 13v6a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2V8a2 2 0 0 1 2-2h6"/><polyline points="15 3 21 3 21 9"/><line x1="10" y1="14" x2="21" y2="3"/></svg>
                                </a>
                                <div style="font-size:12px;color:var(--text-muted);margin-top:3px;">
                                    Total: <strong>PHP {{ number_format((float) $returnRequest->order->total, 2) }}</strong>
                                </div>
                            </td>

                            <!-- Buyer Info -->
                            <td>
                                <div class="buyer-name">{{ $returnRequest->buyer->name ?? 'Buyer' }}</div>
                                <div class="buyer-sub">{{ $returnRequest->buyer->email ?? 'No email' }}</div>
                                @if (!empty($returnRequest->order->contact_number))
                                    <div class="buyer-sub">📞 {{ $returnRequest->order->contact_number }}</div>
                                @endif
                            </td>

                            <!-- Reason & Explanation -->
                            <td>
                                <span class="reason-badge">
                                    {{ ucwords(str_replace('_', ' ', $returnRequest->reason)) }}
                                </span>
                                <div class="reason-details">
                                    {{ $returnRequest->details ?: 'No detailed explanation provided by buyer.' }}
                                </div>

                                @if ($returnRequest->admin_note)
                                    <div class="review-note-box">
                                        <strong>Seller Note:</strong> {{ $returnRequest->admin_note }}
                                    </div>
                                @endif
                            </td>

                            <!-- Items Covered -->
                            <td>
                                <div class="items-pill-list">
                                    @forelse ($sellerItems as $item)
                                        <div class="item-pill-row">
                                            <strong>{{ $item->quantity }}×</strong> {{ $item->product?->name ?? 'Item' }}
                                        </div>
                                    @empty
                                        <span style="font-size:12px;color:var(--text-muted);">No seller items matched</span>
                                    @endforelse
                                </div>
                            </td>

                            <!-- Evidence -->
                            <td>
                                @if ($returnRequest->evidence->count() > 0)
                                    <button type="button"
                                            class="proof-trigger-btn"
                                            onclick='openEvidenceModal("{{ $returnRequest->order->order_number }}", "{{ addslashes(ucwords(str_replace('_', ' ', $returnRequest->reason))) }}", "{{ addslashes($returnRequest->details ?? '') }}", @json($evidenceList))'>
                                        📷 Proof ({{ $returnRequest->evidence->count() }})
                                    </button>
                                @else
                                    <span style="font-size:12px;color:var(--text-muted);">None attached</span>
                                @endif
                            </td>

                            <!-- Status -->
                            <td>
                                @if ($returnRequest->status === 'pending')
                                    <span class="status-pill status-pending" style="font-size:11.5px;padding:3px 10px;">Pending</span>
                                @elseif ($returnRequest->status === 'approved')
                                    <span class="status-pill status-approved" style="font-size:11.5px;padding:3px 10px;background:#ECFDF5;color:#065F46;">Approved</span>
                                @elseif ($returnRequest->status === 'denied')
                                    <span class="status-pill status-rejected" style="font-size:11.5px;padding:3px 10px;">Denied</span>
                                @else
                                    <span class="status-pill" style="font-size:11.5px;padding:3px 10px;">{{ ucfirst($returnRequest->status) }}</span>
                                @endif
                            </td>

                            <!-- Logistics Status -->
                            <td>
                                @if ($returnRequest->logisticsNotification)
                                    @if ($returnRequest->logisticsNotification->status === 'processed')
                                        <span class="status-pill status-paid" style="font-size:11.5px;padding:3px 8px;">Dispatched</span>
                                    @else
                                        <span class="status-pill status-pending" style="font-size:11.5px;padding:3px 8px;background:#EFF6FF;color:#1E40AF;">Queued</span>
                                    @endif
                                @else
                                    <span style="font-size:12px;color:var(--text-muted);">—</span>
                                @endif
                            </td>

                            <!-- Actions -->
                            <td style="text-align:right;">
                                @if ($returnRequest->status === 'pending')
                                    <div class="action-btn-group">
                                        <form method="POST" action="{{ route('seller.returns.approve', $returnRequest) }}" onsubmit="return confirm('Approve this return request for Order #{{ $returnRequest->order->order_number }}?\n\nThis will mark the order as returned and dispatch a return notification to Lumora Logistics.')">
                                            @csrf
                                            <button type="submit" class="btn-action-approve">
                                                ✓ Approve
                                            </button>
                                        </form>

                                        <button type="button"
                                                class="btn-action-deny"
                                                onclick='openDenyModal("{{ route('seller.returns.deny', $returnRequest) }}", "{{ $returnRequest->order->order_number }}", "{{ addslashes($returnRequest->buyer->name ?? 'Buyer') }}")'>
                                            ✕ Deny...
                                        </button>
                                    </div>
                                @else
                                    <a href="{{ route('seller.orders.show', $returnRequest->order_id) }}" class="btn-outline" style="padding:5px 10px;font-size:12px;text-decoration:none;display:inline-block;">
                                        View Order
                                    </a>
                                @endif
                            </td>
                        </tr>
                    @empty
                        <tr>
                            <td colspan="9" style="text-align:center;padding:48px 20px;background:#fff;">
                                <div style="font-size:36px;margin-bottom:12px;">📦</div>
                                <h3 style="font-size:16px;font-weight:700;color:var(--text-dark);margin:0 0 6px;">
                                    @if (!empty($search))
                                        No return requests match "{{ $search }}"
                                    @elseif ($status !== 'all')
                                        No {{ $status }} return requests
                                    @else
                                        No return requests found
                                    @endif
                                </h3>
                                <p style="font-size:13px;color:var(--text-muted);margin:0 0 16px;max-width:420px;margin-inline:auto;">
                                    @if (!empty($search))
                                        Try adjusting your search keywords or clear filters to view all customer claims.
                                    @else
                                        When a buyer submits a return or refund request for your items, it will appear here for your review and approval.
                                    @endif
                                </p>
                                @if (!empty($search) || $status !== 'all')
                                    <a href="{{ route('seller.returns.index') }}" class="btn-outline" style="text-decoration:none;font-size:13px;padding:8px 16px;">
                                        Clear all filters
                                    </a>
                                @endif
                            </td>
                        </tr>
                    @endforelse
                </tbody>
            </table>
        </div>

        @if ($requests->hasPages())
            <div style="padding:16px 20px;border-top:1px solid var(--border);background:#FAF7F5;">
                {{ $requests->links() }}
            </div>
        @endif
    </div>

    <!-- Deny Return Modal -->
    <div class="returns-modal-overlay" id="denyModalOverlay" onclick="handleDenyOverlayClick(event)">
        <div class="returns-modal-box">
            <div class="returns-modal-header">
                <h3>Deny Return Request</h3>
                <button type="button" class="returns-modal-close" onclick="closeDenyModal()">&times;</button>
            </div>

            <form id="denyForm" method="POST" action="">
                @csrf
                <div class="returns-modal-body">
                    <p style="font-size:13.5px;color:var(--text-muted);margin-bottom:16px;line-height:1.5;">
                        You are denying the return request for <strong id="denyModalOrderNum" style="color:var(--text-dark);"></strong> filed by <strong id="denyModalBuyerName" style="color:var(--text-dark);"></strong>.
                    </p>

                    <label for="seller_note" style="display:block;font-size:13px;font-weight:700;color:var(--text-dark);margin-bottom:6px;">
                        Reason for Denial <span style="color:var(--coral);">*</span>
                    </label>
                    <textarea name="seller_note"
                              id="seller_note"
                              rows="4"
                              required
                              maxlength="1000"
                              placeholder="Explain why this request is being rejected (e.g., item arrived as described, outside 7-day return policy, damaged by customer, etc.). This note will be sent directly to the buyer."
                              style="width:100%;border:1px solid var(--border);border-radius:10px;padding:12px;font-size:13.5px;font-family:inherit;box-sizing:border-box;"></textarea>
                    <div style="font-size:11.5px;color:var(--text-muted);margin-top:4px;text-align:right;">
                        Maximum 1,000 characters
                    </div>
                </div>

                <div class="returns-modal-footer">
                    <button type="button" class="btn-outline" style="padding:9px 18px;font-size:13px;" onclick="closeDenyModal()">Cancel</button>
                    <button type="submit" class="btn-solid" style="background:#DC2626;padding:9px 18px;font-size:13px;">Confirm Denial</button>
                </div>
            </form>
        </div>
    </div>

    <!-- Evidence Lightbox Modal -->
    <div class="returns-modal-overlay" id="evidenceModalOverlay" onclick="handleEvidenceOverlayClick(event)">
        <div class="returns-modal-box" style="width:620px;">
            <div class="returns-modal-header">
                <div>
                    <h3 id="evidenceModalTitle">Return Evidence & Proof</h3>
                    <div id="evidenceModalSub" style="font-size:12px;color:var(--text-muted);margin-top:2px;"></div>
                </div>
                <button type="button" class="returns-modal-close" onclick="closeEvidenceModal()">&times;</button>
            </div>

            <div class="returns-modal-body">
                <div style="background:var(--bg);border-radius:10px;padding:12px 14px;margin-bottom:16px;border:1px solid var(--border);">
                    <div style="font-size:12px;font-weight:700;color:var(--text-muted);text-transform:uppercase;margin-bottom:4px;">Buyer's Stated Reason</div>
                    <div id="evidenceModalReason" style="font-weight:700;color:var(--terra-2);font-size:13.5px;margin-bottom:4px;"></div>
                    <div id="evidenceModalDetails" style="font-size:13px;color:var(--text-dark);line-height:1.45;"></div>
                </div>

                <div style="font-size:13px;font-weight:700;color:var(--text-dark);margin-bottom:6px;">Uploaded Photos & Videos</div>
                <div class="proof-gallery-grid" id="evidenceGallery"></div>
            </div>

            <div class="returns-modal-footer">
                <button type="button" class="btn-solid" style="padding:8px 18px;font-size:13px;" onclick="closeEvidenceModal()">Close</button>
            </div>
        </div>
    </div>

    <script>
        function openDenyModal(url, orderNum, buyerName) {
            const form = document.getElementById('denyForm');
            form.action = url;
            document.getElementById('denyModalOrderNum').textContent = '#' + orderNum;
            document.getElementById('denyModalBuyerName').textContent = buyerName;
            document.getElementById('seller_note').value = '';
            document.getElementById('denyModalOverlay').style.display = 'flex';
            setTimeout(() => document.getElementById('seller_note').focus(), 100);
        }

        function closeDenyModal() {
            document.getElementById('denyModalOverlay').style.display = 'none';
        }

        function handleDenyOverlayClick(e) {
            if (e.target.id === 'denyModalOverlay') {
                closeDenyModal();
            }
        }

        function openEvidenceModal(orderNum, reason, details, evidenceList) {
            document.getElementById('evidenceModalTitle').textContent = 'Evidence · Order #' + orderNum;
            document.getElementById('evidenceModalSub').textContent = 'Attached proof submitted by buyer';
            document.getElementById('evidenceModalReason').textContent = reason;
            document.getElementById('evidenceModalDetails').textContent = details || 'No additional explanation provided.';

            const gallery = document.getElementById('evidenceGallery');
            gallery.innerHTML = '';

            if (!evidenceList || evidenceList.length === 0) {
                gallery.innerHTML = '<div style="color:var(--text-muted);font-size:13px;padding:12px 0;">No proof files attached to this request.</div>';
            } else {
                evidenceList.forEach((ev, idx) => {
                    const card = document.createElement('div');
                    card.className = 'proof-card';

                    if (ev.is_image) {
                        card.innerHTML = `
                            <a href="${ev.url}" target="_blank" rel="noopener">
                                <img src="${ev.url}" alt="Buyer proof ${idx + 1}" loading="lazy">
                            </a>
                            <a href="${ev.url}" target="_blank" rel="noopener" class="proof-card-footer">
                                View Full Image ↗
                            </a>
                        `;
                    } else {
                        card.innerHTML = `
                            <video src="${ev.url}" controls preload="metadata"></video>
                            <a href="${ev.url}" target="_blank" rel="noopener" class="proof-card-footer">
                                Open Video ↗
                            </a>
                        `;
                    }

                    gallery.appendChild(card);
                });
            }

            document.getElementById('evidenceModalOverlay').style.display = 'flex';
        }

        function closeEvidenceModal() {
            document.getElementById('evidenceModalOverlay').style.display = 'none';
        }

        function handleEvidenceOverlayClick(e) {
            if (e.target.id === 'evidenceModalOverlay') {
                closeEvidenceModal();
            }
        }

        document.addEventListener('keydown', function (e) {
            if (e.key === 'Escape') {
                closeDenyModal();
                closeEvidenceModal();
            }
        });
    </script>
@endsection
