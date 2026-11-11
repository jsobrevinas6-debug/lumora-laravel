@extends('layouts.seller')

@section('title', 'Orders')

@section('content')
    @if (session('success'))
        <div class="alert-success">
            {{ session('success') }}
        </div>
    @endif

    @if (session('error'))
        <div class="alert-error" style="background:#ffe6e6;color:#8a1f1f;padding:12px 16px;border-radius:8px;margin-bottom:16px;">
            {{ session('error') }}
        </div>
    @endif

    @php
        $statusLabels = [
            'pending' => 'Pending',
            'processing' => 'Processing',
            'packed' => 'Packed',
            'shipped' => 'Shipped',
            'out_for_delivery' => 'Out for Delivery',
            'delivered' => 'Delivered',
            'cancelled' => 'Cancelled',
            'returned' => 'Returned',
        ];

        $statusColors = [
            'pending' => 'var(--terra-1)',
            'processing' => 'var(--terra-1)',
            'packed' => 'var(--sage-2)',
            'shipped' => 'var(--sage-2)',
            'out_for_delivery' => 'var(--sage-2)',
            'delivered' => 'var(--sage-2)',
            'cancelled' => 'var(--coral)',
            'returned' => '#8B7A80',
        ];

        $currentStatus = $currentStatus ?? request('status', 'all');
        $tabCounts = $tabCounts ?? [];
    @endphp

    <style>
        .order-tabs-bar {
            display: flex;
            align-items: center;
            justify-content: space-between;
            gap: 16px;
            flex-wrap: wrap;
            margin-bottom: 20px;
        }
        .order-tabs {
            display: flex;
            gap: 8px;
            flex-wrap: wrap;
            align-items: center;
        }
        .order-tab-btn {
            display: inline-flex;
            align-items: center;
            gap: 6px;
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
        .order-tab-btn:hover {
            border-color: var(--maroon);
            color: var(--maroon);
        }
        .order-tab-btn.active {
            background: var(--maroon);
            border-color: var(--maroon);
            color: #fff;
        }
        .order-tab-badge {
            display: inline-block;
            padding: 1px 7px;
            border-radius: 999px;
            font-size: 11px;
            font-weight: 700;
            background: var(--bg);
            color: var(--text-dark);
        }
        .order-tab-btn.active .order-tab-badge {
            background: rgba(255,255,255,0.25);
            color: #fff;
        }
        .order-tab-badge.badge-alert {
            background: var(--coral);
            color: #fff;
        }
        .order-search-form {
            display: flex;
            gap: 8px;
            align-items: center;
        }
        .order-search-input {
            padding: 8px 14px;
            border: 1px solid var(--border);
            border-radius: 999px;
            font-size: 13px;
            background: #fff;
            width: 220px;
            font-family: inherit;
        }
        .order-search-input:focus {
            outline: none;
            border-color: var(--maroon);
        }
        .return-badge-pill {
            display: inline-flex;
            align-items: center;
            gap: 4px;
            padding: 3px 8px;
            border-radius: 999px;
            font-size: 11px;
            font-weight: 700;
            margin-top: 4px;
            text-decoration: none;
        }
        .return-badge-pending {
            background: #FFF4E5;
            color: #B45309;
            border: 1px solid #FDE68A;
        }
        .return-badge-approved {
            background: #ECFDF5;
            color: #065F46;
            border: 1px solid #A7F3D0;
        }
        .return-badge-denied {
            background: #FEF2F2;
            color: #991B1B;
            border: 1px solid #FECACA;
        }
    </style>

    <div class="order-tabs-bar">
        <div class="order-tabs">
            <a href="{{ route('seller.orders.index', ['status' => 'all']) }}" class="order-tab-btn {{ $currentStatus === 'all' ? 'active' : '' }}">
                <span>All Orders</span>
                <span class="order-tab-badge">{{ $tabCounts['all'] ?? 0 }}</span>
            </a>
            <a href="{{ route('seller.orders.index', ['status' => 'pending']) }}" class="order-tab-btn {{ $currentStatus === 'pending' ? 'active' : '' }}">
                <span>Pending</span>
                <span class="order-tab-badge">{{ $tabCounts['pending'] ?? 0 }}</span>
            </a>
            <a href="{{ route('seller.orders.index', ['status' => 'packed']) }}" class="order-tab-btn {{ $currentStatus === 'packed' ? 'active' : '' }}">
                <span>Packed</span>
                <span class="order-tab-badge">{{ $tabCounts['packed'] ?? 0 }}</span>
            </a>
            <a href="{{ route('seller.orders.index', ['status' => 'shipped']) }}" class="order-tab-btn {{ $currentStatus === 'shipped' ? 'active' : '' }}">
                <span>Shipped</span>
                <span class="order-tab-badge">{{ $tabCounts['shipped'] ?? 0 }}</span>
            </a>
            <a href="{{ route('seller.orders.index', ['status' => 'delivered']) }}" class="order-tab-btn {{ $currentStatus === 'delivered' ? 'active' : '' }}">
                <span>Delivered</span>
                <span class="order-tab-badge">{{ $tabCounts['delivered'] ?? 0 }}</span>
            </a>
            <a href="{{ route('seller.orders.index', ['status' => 'returns']) }}" class="order-tab-btn {{ $currentStatus === 'returns' ? 'active' : '' }}">
                <span>Return / Refund</span>
                <span class="order-tab-badge {{ ($tabCounts['returns'] ?? 0) > 0 ? 'badge-alert' : '' }}">{{ $tabCounts['returns'] ?? 0 }}</span>
            </a>
        </div>

        <form method="GET" action="{{ route('seller.orders.index') }}" class="order-search-form">
            <input type="hidden" name="status" value="{{ $currentStatus }}">
            <input type="search" name="search" class="order-search-input" value="{{ $search ?? '' }}" placeholder="Search order #, buyer...">
            @if(!empty($search))
                <a href="{{ route('seller.orders.index', ['status' => $currentStatus]) }}" style="font-size:12px;color:var(--text-muted);text-decoration:none;">Clear</a>
            @endif
        </form>
    </div>

    <div class="panel">
        <table>
            <thead>
                <tr>
                    <th>Order</th>
                    <th>Buyer</th>
                    <th>Date</th>
                    <th>Subtotal</th>
                    <th>Payment Method</th>
                    <th>Voucher</th>
                    <th>Status</th>
                    <th>Packing</th>
                    <th></th>
                </tr>
            </thead>

            <tbody>
                @forelse ($orders as $o)
                    @php
                        $status = $o->status ?? 'pending';
                        $statusLabel = $statusLabels[$status] ?? ucfirst(str_replace('_', ' ', $status));
                        $statusColor = $statusColors[$status] ?? 'var(--terra-1)';

                        $rawPayment = strtolower($o->payment_method ?? 'cod');
                        $paymentLabel = match ($rawPayment) {
                            'cod' => 'COD',
                            'gcash' => 'GCash',
                            'maya', 'paymaya' => 'PayMaya',
                            'bank_transfer' => 'Bank Transfer',
                            'card' => 'Card',
                            default => strtoupper($o->payment_method ?? 'COD'),
                        };

                        $paymentBadgeStyle = match ($rawPayment) {
                            'cod' => 'background:#7B6E74;color:#fff;',
                            'gcash' => 'background:#005ce6;color:#fff;',
                            'maya', 'paymaya' => 'background:#00a651;color:#fff;',
                            default => 'background:var(--maroon);color:#fff;',
                        };
                    @endphp

                    <tr>
                        <td>
                            <div style="font-weight:700;">
                                @if (!empty($o->order_number))
                                    {{ $o->order_number }}
                                @else
                                    #{{ $o->order_id }}
                                @endif
                            </div>

                            @if ($o->unseen_count > 0)
                                <span class="stock-badge" style="background:var(--coral);">
                                    New
                                </span>
                            @endif

                            @if (!empty($o->return_request_id))
                                <div>
                                    @if ($o->return_request_status === 'pending')
                                        <span class="return-badge-pill return-badge-pending" title="Buyer requested return: {{ $o->return_request_reason }}">
                                            ⚠️ Return Requested
                                        </span>
                                    @elseif ($o->return_request_status === 'approved')
                                        <span class="return-badge-pill return-badge-approved" title="Return approved">
                                            ✓ Return Approved
                                        </span>
                                    @elseif ($o->return_request_status === 'denied')
                                        <span class="return-badge-pill return-badge-denied" title="Return denied">
                                            ✕ Return Denied
                                        </span>
                                    @endif
                                </div>
                            @elseif ($status === 'returned')
                                <div>
                                    <span class="return-badge-pill return-badge-approved">
                                        ✓ Returned
                                    </span>
                                </div>
                            @endif
                        </td>

                        <td>{{ $o->buyer_name }}</td>

                        <td>
                            {{ \Carbon\Carbon::parse($o->order_date)->format('M d, Y') }}
                        </td>

                        <td>
                            PHP {{ number_format($o->seller_subtotal, 2) }}
                        </td>

                        <td>
                            <span class="stock-badge" style="{{ $paymentBadgeStyle }};font-weight:600;">
                                {{ $paymentLabel }}
                            </span>
                        </td>

                        <td>
                            @if (!empty($o->voucher_code))
                                <span class="stock-badge" style="background:var(--sage-2);">{{ $o->voucher_code }}</span>
                                <div style="font-size:12px;color:var(--text-muted);margin-top:4px;">
                                    @if (($o->voucher_type ?? '') === 'shipping' || (float) $o->shipping_discount > 0)
                                        Free shipping (PHP {{ number_format((float) $o->shipping_discount, 2) }})
                                    @else
                                        Discount - PHP {{ number_format((float) $o->voucher_discount, 2) }}
                                    @endif
                                </div>
                            @else
                                <span style="color:#999;">None</span>
                            @endif
                        </td>

                        <td>
                            <span class="stock-badge" style="background:{{ $statusColor }};">
                                {{ $statusLabel }}
                            </span>
                        </td>

                        <td>
                            @if ($o->unpacked_count == 0)
                                <span class="stock-badge" style="background:var(--sage-2);">
                                    Items Packed
                                </span>
                            @else
                                <span class="stock-badge" style="background:var(--terra-1);">
                                    {{ $o->unpacked_count }} Unpacked
                                </span>
                            @endif
                        </td>

                        <td style="display:flex;gap:6px;align-items:center;justify-content:flex-end;flex-wrap:wrap;">
                            <a href="{{ route('seller.orders.show', $o->order_id) }}"
                               class="edit-stock-btn"
                               style="text-decoration:none;display:inline-block;">
                                View
                            </a>

                            @if (!empty($o->return_request_id))
                                <a href="{{ route('seller.orders.show', $o->order_id) }}#return-section"
                                   class="edit-stock-btn"
                                   style="text-decoration:none;display:inline-block;background:{{ $o->return_request_status === 'pending' ? 'var(--coral)' : 'var(--text-muted)' }};">
                                    {{ $o->return_request_status === 'pending' ? 'Review Return' : 'Return Info' }}
                                </a>
                            @endif

                            @if (!in_array($status, ['packed', 'shipped', 'out_for_delivery', 'delivered', 'cancelled', 'returned'], true))
                                <form action="{{ route('seller.orders.pack', $o->order_id) }}"
                                      method="POST"
                                      style="display:inline;">
                                    @csrf

                                    <button type="submit"
                                            class="edit-stock-btn"
                                            onclick="return confirm('Mark this order as packed?')">
                                        Mark as Packed
                                    </button>
                                </form>
                            @endif
                        </td>
                    </tr>
                @empty
                    <tr>
                        <td colspan="9" style="text-align:center;color:#999;padding:28px 20px;">
                            <div style="font-size:24px;margin-bottom:6px;">📦</div>
                            <div style="font-weight:600;font-size:14px;color:var(--text-dark);">No orders found</div>
                            <div style="font-size:12px;color:var(--text-muted);margin-top:4px;">
                                @if($currentStatus === 'returns')
                                    You have no return or refund requests under this filter.
                                @else
                                    No orders match the selected filter.
                                @endif
                            </div>
                        </td>
                    </tr>
                @endforelse
            </tbody>
        </table>
    </div>
@endsection
