@extends('layouts.seller')

@section('title', 'Order ' . ($order->order_number ?? '#' . $order->id))

@section('content')
    @if (session('success'))
        <div class="alert-success">{{ session('success') }}</div>
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
            'returned' => '#999',
        ];

        $status = $order->status ?? 'pending';
        $statusLabel = $statusLabels[$status] ?? ucfirst(str_replace('_', ' ', $status));
        $statusColor = $statusColors[$status] ?? 'var(--terra-1)';

        $rawPayment = strtolower($order->payment_method ?? 'cod');
        $paymentLabel = match ($rawPayment) {
            'cod' => 'COD',
            'gcash' => 'GCash',
            'maya', 'paymaya' => 'PayMaya',
            'bank_transfer' => 'Bank Transfer',
            'card' => 'Card',
            default => strtoupper($order->payment_method ?? 'COD'),
        };

        $paymentBadgeStyle = match ($rawPayment) {
            'cod' => 'background:#7B6E74;color:#fff;',
            'gcash' => 'background:#005ce6;color:#fff;',
            'maya', 'paymaya' => 'background:#00a651;color:#fff;',
            default => 'background:var(--maroon);color:#fff;',
        };

        $allPacked = $items->every(fn ($item) => $item->packed_at !== null);

        $canMarkPacked = ! in_array($status, [
            'packed',
            'shipped',
            'out_for_delivery',
            'delivered',
            'cancelled',
            'returned',
        ], true);
    @endphp

    <div class="panel">
        <div style="display:flex;justify-content:space-between;align-items:flex-start;margin-bottom:18px;">
            <div>
                <h2 style="margin-bottom:2px;">
                    Order {{ $order->order_number ?? '#' . $order->id }}
                </h2>

                <div style="font-size:13px;color:var(--text-muted);">
                    {{ \Carbon\Carbon::parse($order->created_at)->format('M d, Y g:i A') }}
                </div>
            </div>

            <div style="display:flex;gap:8px;align-items:center;">
                <span class="stock-badge" style="{{ $paymentBadgeStyle }};font-weight:600;">
                    {{ $paymentLabel }}
                </span>

                <span class="stock-badge" style="background:{{ $statusColor }};">
                    {{ $statusLabel }}
                </span>

                @if ($allPacked && $status !== 'packed')
                    <span class="stock-badge" style="background:var(--sage-2);">
                        Items Packed
                    </span>
                @endif
            </div>
        </div>

        <table style="margin-bottom:20px;">
            <thead>
                <tr>
                    <th>Product</th>
                    <th>Qty</th>
                    <th>Price</th>
                    <th>Packing</th>
                </tr>
            </thead>

            <tbody>
                @foreach ($items as $item)
                    <tr>
                        <td>{{ $item->product_name }}</td>
                        <td>x{{ $item->quantity }}</td>
                        <td>PHP {{ number_format($item->price * $item->quantity, 2) }}</td>
                        <td>
                            @if ($item->packed_at)
                                <span class="stock-badge" style="background:var(--sage-2);">Packed</span>
                            @else
                                <span class="stock-badge" style="background:var(--terra-1);">Pending</span>
                            @endif
                        </td>
                    </tr>
                @endforeach

                <tr>
                    <td colspan="2" style="font-weight:700;border-bottom:none;">Total</td>
                    <td colspan="2" style="font-weight:700;border-bottom:none;">
                        PHP {{ number_format($items->sum(fn ($item) => $item->price * $item->quantity), 2) }}
                    </td>
                </tr>

                <tr>
                    <td colspan="2" style="border-bottom:none;color:var(--text-muted);">Payment Method</td>
                    <td colspan="2" style="border-bottom:none;">
                        <span class="stock-badge" style="{{ $paymentBadgeStyle }};font-weight:600;">{{ $paymentLabel }}</span>
                    </td>
                </tr>

                @if (!empty($order->voucher_code))
                    <tr>
                        <td colspan="2" style="border-bottom:none;color:var(--text-muted);">Voucher used by buyer</td>
                        <td colspan="2" style="border-bottom:none;">
                            <span class="stock-badge" style="background:var(--sage-2);">{{ $order->voucher_code }}</span>
                        </td>
                    </tr>
                    @if ((float) $order->voucher_discount > 0)
                        <tr>
                            <td colspan="2" style="border-bottom:none;color:var(--text-muted);">Voucher discount</td>
                            <td colspan="2" style="border-bottom:none;color:var(--coral);font-weight:600;">- PHP {{ number_format((float) $order->voucher_discount, 2) }}</td>
                        </tr>
                    @endif
                    @if ((float) $order->shipping_discount > 0)
                        <tr>
                            <td colspan="2" style="border-bottom:none;color:var(--text-muted);">Free shipping</td>
                            <td colspan="2" style="border-bottom:none;color:var(--sage-2);font-weight:600;">Shipping waived (PHP {{ number_format((float) $order->shipping_discount, 2) }})</td>
                        </tr>
                    @endif
                @endif
            </tbody>
        </table>

        <div style="border-top:1px solid var(--border);padding-top:14px;margin-bottom:20px;font-size:13.5px;color:var(--text-muted);line-height:1.7;">
            <div>
                {{ $order->buyer_name }} &middot; {{ $order->contact_number ?? '—' }}
            </div>

            <div>
                {{ collect([
                    $order->house_number,
                    $order->street,
                    $order->barangay,
                    $order->municipality,
                    $order->province,
                ])->filter()->implode(', ') ?: 'No address on file' }}
            </div>
        </div>

        <div style="display:flex;gap:12px;flex-wrap:wrap;">
            @if ($canMarkPacked)
                <form action="{{ route('seller.orders.pack', $order->id) }}" method="POST">
                    @csrf

                    <button type="submit"
                            class="btn-solid"
                            onclick="return confirm('Mark this order as packed?')">
                        Mark as Packed
                    </button>
                </form>
            @endif

            <a href="{{ route('seller.orders.waybill', $order->id) }}"
               target="_blank"
               rel="noopener"
               class="btn-outline"
               style="text-decoration:none;display:inline-block;">
                Print waybill
            </a>

            @if ($returnRequest)
                <a href="#return-section" class="btn-outline" style="border-color:var(--coral);color:var(--coral);text-decoration:none;">
                    Jump to Return Request
                </a>
            @endif
        </div>
    </div>

    @if ($returnRequest)
        <div class="panel" id="return-section" style="margin-top:24px;border:1.5px solid {{ $returnRequest->status === 'pending' ? 'var(--coral)' : ($returnRequest->status === 'approved' ? 'var(--sage-1)' : '#DC2626') }};">
            <div style="display:flex;justify-content:space-between;align-items:center;flex-wrap:wrap;gap:12px;margin-bottom:18px;">
                <div style="display:flex;align-items:center;gap:10px;">
                    <div style="width:36px;height:36px;border-radius:10px;background:{{ $returnRequest->status === 'pending' ? '#FFF4E5' : ($returnRequest->status === 'approved' ? '#ECFDF5' : '#FEF2F2') }};display:flex;align-items:center;justify-content:center;font-size:18px;">
                        @if ($returnRequest->status === 'pending')
                            ⚠️
                        @elseif ($returnRequest->status === 'approved')
                            ✓
                        @else
                            ✕
                        @endif
                    </div>
                    <div>
                        <h2 style="margin:0;font-size:18px;color:var(--text-dark);">Customer Return / Refund Request</h2>
                        <div style="font-size:12px;color:var(--text-muted);margin-top:2px;">
                            Submitted by {{ $returnRequest->buyer->name ?? 'Buyer' }} on {{ $returnRequest->created_at->format('M d, Y · g:i A') }}
                        </div>
                    </div>
                </div>

                <div>
                    @if ($returnRequest->status === 'pending')
                        <span class="status-pill status-pending" style="font-size:13px;padding:6px 14px;">
                            Pending Seller Review
                        </span>
                    @elseif ($returnRequest->status === 'approved')
                        <span class="status-pill status-approved" style="font-size:13px;padding:6px 14px;background:#ECFDF5;color:#065F46;">
                            ✓ Return Approved
                        </span>
                    @elseif ($returnRequest->status === 'denied')
                        <span class="status-pill status-rejected" style="font-size:13px;padding:6px 14px;">
                            ✕ Return Denied
                        </span>
                    @endif
                </div>
            </div>

            <!-- Details Box -->
            <div style="background:var(--bg);border-radius:12px;padding:16px 18px;margin-bottom:20px;border:1px solid var(--border);">
                <div style="display:grid;grid-template-columns:repeat(auto-fit, minmax(220px, 1fr));gap:16px;margin-bottom:14px;">
                    <div>
                        <span style="font-size:11.5px;color:var(--text-muted);text-transform:uppercase;font-weight:700;display:block;margin-bottom:4px;">Return Reason</span>
                        <strong style="font-size:14px;color:var(--maroon);">
                            {{ ucwords(str_replace('_', ' ', $returnRequest->reason)) }}
                        </strong>
                    </div>

                    <div>
                        <span style="font-size:11.5px;color:var(--text-muted);text-transform:uppercase;font-weight:700;display:block;margin-bottom:4px;">Logistics Dispatch</span>
                        @if ($returnRequest->logisticsNotification)
                            <span class="status-pill status-paid" style="font-size:11px;">Queued for Lumora Logistics</span>
                        @else
                            <span class="status-pill status-pending" style="font-size:11px;">Pending Approval</span>
                        @endif
                    </div>

                    @if ($returnRequest->reviewed_at)
                        <div>
                            <span style="font-size:11.5px;color:var(--text-muted);text-transform:uppercase;font-weight:700;display:block;margin-bottom:4px;">Reviewed On</span>
                            <span style="font-size:13px;font-weight:600;">
                                {{ \Carbon\Carbon::parse($returnRequest->reviewed_at)->format('M d, Y · g:i A') }}
                            </span>
                        </div>
                    @endif
                </div>

                <div>
                    <span style="font-size:11.5px;color:var(--text-muted);text-transform:uppercase;font-weight:700;display:block;margin-bottom:4px;">Buyer's Explanation</span>
                    <p style="font-size:13.5px;color:var(--text-dark);line-height:1.6;margin:0;white-space:pre-wrap;">{{ $returnRequest->details }}</p>
                </div>

                @if ($returnRequest->admin_note)
                    <div style="margin-top:14px;padding-top:12px;border-top:1px dashed var(--border);">
                        <span style="font-size:11.5px;color:var(--text-muted);text-transform:uppercase;font-weight:700;display:block;margin-bottom:4px;">Review Note</span>
                        <div style="font-size:13px;color:var(--maroon);font-weight:600;">
                            {{ $returnRequest->admin_note }}
                        </div>
                    </div>
                @endif
            </div>

            <!-- Evidence Gallery -->
            <div style="margin-bottom:22px;">
                <div style="display:flex;justify-content:space-between;align-items:center;margin-bottom:10px;">
                    <h3 style="font-size:14px;font-weight:700;color:var(--text-dark);margin:0;">
                        Buyer's Photo / Video Evidence ({{ $returnRequest->evidence->count() }})
                    </h3>
                    <span style="font-size:12px;color:var(--text-muted);">Click on any item to view high-resolution proof</span>
                </div>

                <div style="display:flex;gap:12px;flex-wrap:wrap;">
                    @forelse ($returnRequest->evidence as $proof)
                        @php
                            $proofUrl = route('seller.returns.evidence', [$returnRequest, $proof->id]);
                        @endphp
                        <a href="{{ $proofUrl }}" target="_blank" rel="noopener" style="position:relative;border:1px solid var(--border);border-radius:10px;overflow:hidden;background:#fff;display:block;text-decoration:none;transition:transform .15s ease,box-shadow .15s ease;" onmouseover="this.style.transform='scale(1.03)';this.style.boxShadow='0 4px 14px rgba(0,0,0,0.1)'" onmouseout="this.style.transform='none';this.style.boxShadow='none'">
                            @if (str_starts_with($proof->mime_type, 'image/'))
                                <img src="{{ $proofUrl }}" alt="Buyer proof" style="width:110px;height:110px;object-fit:cover;display:block;">
                                <span style="position:absolute;bottom:4px;right:4px;background:rgba(0,0,0,0.6);color:#fff;font-size:10px;padding:2px 5px;border-radius:4px;">Photo</span>
                            @else
                                <div style="width:110px;height:110px;display:flex;flex-direction:column;align-items:center;justify-content:center;background:#2B1C22;color:#fff;">
                                    <span style="font-size:24px;">▶</span>
                                    <span style="font-size:10px;margin-top:4px;">Play Video</span>
                                </div>
                            @endif
                        </a>
                    @empty
                        <div style="color:var(--text-muted);font-size:13px;padding:12px 0;">
                            No photo or video proof attached with this return request.
                        </div>
                    @endforelse
                </div>
            </div>

            <!-- Actions Bar -->
            @if ($returnRequest->status === 'pending')
                <div style="display:flex;gap:12px;align-items:center;flex-wrap:wrap;padding-top:16px;border-top:1px solid var(--border);">
                    <form method="POST" action="{{ route('seller.returns.approve', $returnRequest) }}" style="display:inline;" onsubmit="return confirm('Approve this return request?\n\nThe order status will become Returned and Lumora Logistics will be queued to pick up the parcel from the buyer.')">
                        @csrf
                        <button type="submit" class="btn-solid" style="background:#065F46;display:inline-flex;align-items:center;gap:6px;">
                            <span>✓</span> Approve Return Request
                        </button>
                    </form>

                    <button type="button" class="btn-outline" style="border-color:#DC2626;color:#DC2626;" onclick="document.getElementById('orderDenyModal').style.display='flex'">
                        <span>✕</span> Deny Request
                    </button>

                    <a href="{{ route('seller.returns.index') }}" class="btn-outline" style="text-decoration:none;display:inline-block;">
                        View All Returns
                    </a>
                </div>

                <!-- Denial Modal -->
                <div id="orderDenyModal" class="modal-overlay">
                    <div class="modal-box" style="width:460px;">
                        <h2 style="color:var(--maroon);">Deny Return Request</h2>
                        <p style="font-size:12.5px;color:var(--text-muted);margin:-10px 0 16px;line-height:1.5;">
                            Please explain why you are declining the customer's return request. This note will be sent directly to the buyer.
                        </p>
                        <form method="POST" action="{{ route('seller.returns.deny', $returnRequest) }}" class="modal-form">
                            @csrf
                            <label for="order_seller_note" style="font-size:12px;font-weight:700;color:var(--text-dark);">Reason for Denial (Required)</label>
                            <textarea id="order_seller_note" name="seller_note" required maxlength="1000" rows="4" placeholder="e.g. Item was verified functional and serial number matched before packing. Please refer to unboxing policy..." style="border:1px solid var(--border);border-radius:8px;padding:10px;font-size:13px;width:100%;font-family:inherit;resize:vertical;"></textarea>

                            <div class="modal-btn-row">
                                <button type="button" class="btn-cancel" onclick="document.getElementById('orderDenyModal').style.display='none'">Cancel</button>
                                <button type="submit" class="btn-solid" style="background:#DC2626;">Confirm Denial</button>
                            </div>
                        </form>
                    </div>
                </div>
            @elseif ($returnRequest->status === 'approved')
                @php
                    $courierName = !empty($order->courier ?? null)
                        ? $order->courier
                        : (\Illuminate\Support\Facades\Schema::hasTable('order_status_histories')
                            ? \Illuminate\Support\Facades\DB::table('order_status_histories')
                            ->where('order_id', $order->id)
                            ->whereNotNull('courier_name')
                            ->where('courier_name', '!=', '')
                            ->latest('id')
                            ->value('courier_name')
                            : null);
                @endphp
                <div style="background:#ECFDF5;border:1px solid #A7F3D0;border-radius:10px;padding:14px 16px;font-size:13px;color:#065F46;display:flex;align-items:flex-start;gap:12px;">
                    <span style="font-size:20px;line-height:1;">✓</span>
                    <div>
                        <strong>Return Approved & Dispatched.</strong> Order marked as returned and automatically assigned to delivering courier {{ $courierName ? "({$courierName})" : '' }} for reverse logistics pickup.
                    </div>
                </div>
            @elseif ($returnRequest->status === 'denied')
                <div style="background:#FEF2F2;border:1px solid #FECACA;border-radius:10px;padding:12px 16px;font-size:13px;color:#991B1B;display:flex;align-items:center;gap:10px;">
                    <span style="font-size:18px;">✕</span>
                    <div>
                        <strong>Return Denied.</strong> Customer was notified of the rejection with note: "{{ $returnRequest->admin_note }}".
                    </div>
                </div>
            @endif
        </div>
    @endif
@endsection
