<x-admin-layout title="Return / Refund Requests">
    <div class="panel">
        <div style="display:flex;justify-content:space-between;align-items:flex-start;flex-wrap:wrap;gap:12px;margin-bottom:18px;">
            <div>
                <h2>Customer Return / Refund Management</h2>
                <p style="color:var(--text-muted);margin:4px 0 0;font-size:.88rem">
                    Customer return/refund claims are reviewed directly by the respective product seller. Once approved by the seller, returns are automatically assigned to the courier who delivered the item for reverse logistics pickup.
                </p>
            </div>
        </div>

        <div style="overflow-x:auto">
            <table>
                <thead>
                    <tr>
                        <th style="width:130px;">Submitted</th>
                        <th style="width:150px;">Order</th>
                        <th style="width:160px;">Buyer</th>
                        <th style="min-width:200px;">Items to Return</th>
                        <th style="min-width:200px;">Reason & Details</th>
                        <th style="width:110px;">Proof</th>
                        <th style="width:140px;">Status</th>
                        <th style="min-width:190px;">Courier & Pickup</th>
                    </tr>
                </thead>
                <tbody>
                    @forelse ($requests as $returnRequest)
                        @php
                            $order = $returnRequest->order;
                            $deliveringCourier = $order->statusHistories?->whereNotNull('courier_name')->first()?->courier_name
                                ?: ($order->courier ?: 'Assigned Delivery Courier');
                        @endphp
                        <tr>
                            <td>
                                <div>{{ $returnRequest->created_at->format('M d, Y') }}</div>
                                <small style="color:var(--text-muted);">{{ $returnRequest->created_at->format('g:i A') }}</small>
                            </td>

                            <td>
                                <strong>#{{ $order->order_number }}</strong>
                                <br>
                                <small style="color:var(--text-muted);">Total: PHP {{ number_format((float) $order->total, 2) }}</small>
                            </td>

                            <td>
                                <div><strong>{{ $returnRequest->buyer->name ?? 'Buyer' }}</strong></div>
                                <small style="color:var(--text-muted);">{{ $returnRequest->buyer->email ?? '' }}</small>
                                @if (!empty($order->contact_number))
                                    <br><small style="color:var(--text-muted);">📞 {{ $order->contact_number }}</small>
                                @endif
                            </td>

                            <td>
                                <ul style="padding-left:14px;margin:0;font-size:12px;line-height:1.45;color:var(--text-dark);">
                                    @forelse ($order->items as $item)
                                        <li>
                                            <strong>{{ $item->quantity }}×</strong> {{ $item->product?->name ?? 'Product Item' }}
                                            <span style="color:var(--text-muted);">(PHP {{ number_format((float) $item->price, 2) }})</span>
                                        </li>
                                    @empty
                                        <li style="color:var(--text-muted);">No items recorded</li>
                                    @endforelse
                                </ul>
                            </td>

                            <td>
                                <span class="muted-badge" style="background:#FFF0EB;color:#B85C3B;border:1px solid #FCD9CC;display:inline-block;padding:2px 8px;border-radius:6px;font-size:11.5px;font-weight:700;margin-bottom:4px;">
                                    {{ ucwords(str_replace('_', ' ', $returnRequest->reason)) }}
                                </span>
                                <div style="font-size:12px;color:var(--text-dark);line-height:1.4;">
                                    {{ $returnRequest->details ?: 'No additional notes from buyer.' }}
                                </div>
                                @if ($returnRequest->admin_note)
                                    <div style="font-size:11px;color:var(--text-muted);margin-top:4px;padding:4px 6px;background:#F8F8F9;border-left:2px solid var(--text-muted);">
                                        <strong>Review note:</strong> {{ $returnRequest->admin_note }}
                                    </div>
                                @endif
                            </td>

                            <td>
                                @if ($returnRequest->evidence->count() > 0)
                                    <details>
                                        <summary class="btn btn-outline" style="font-size:11px;padding:4px 8px;cursor:pointer;">
                                            Proof ({{ $returnRequest->evidence->count() }})
                                        </summary>
                                        <div style="position:absolute;z-index:15;background:white;border:1px solid var(--border);border-radius:12px;padding:12px;max-width:320px;box-shadow:0 8px 24px rgba(69,19,42,0.15);margin-top:6px;">
                                            <strong style="font-size:12px;">Buyer Evidence:</strong>
                                            <div style="display:flex;gap:6px;flex-wrap:wrap;margin-top:6px;">
                                                @foreach ($returnRequest->evidence as $proof)
                                                    @php($proofUrl = route('admin.returns.evidence', [$returnRequest, $proof->id]))
                                                    <a href="{{ $proofUrl }}" target="_blank" rel="noopener" style="display:block;border:1px solid var(--border);padding:3px;border-radius:6px;">
                                                        @if (str_starts_with($proof->mime_type, 'image/'))
                                                            <img src="{{ $proofUrl }}" alt="Buyer proof" style="width:70px;height:70px;object-fit:cover;display:block;">
                                                        @else
                                                            <video src="{{ $proofUrl }}" controls style="width:140px;max-height:90px;display:block;"></video>
                                                        @endif
                                                    </a>
                                                @endforeach
                                            </div>
                                        </div>
                                    </details>
                                @else
                                    <small style="color:var(--text-muted);">None</small>
                                @endif
                            </td>

                            <td>
                                @if ($returnRequest->status === 'approved')
                                    <span class="match-badge" style="background:#ECFDF5;color:#065F46;border:1px solid #A7F3D0;display:inline-block;padding:3px 10px;border-radius:999px;font-weight:700;font-size:11.5px;">
                                        ✓ Approved by Seller
                                    </span>
                                @elseif ($returnRequest->status === 'denied')
                                    <span class="muted-badge" style="background:#FEF2F2;color:#DC2626;border:1px solid #FECACA;display:inline-block;padding:3px 10px;border-radius:999px;font-weight:700;font-size:11.5px;">
                                        ✕ Denied by Seller
                                    </span>
                                @else
                                    <span class="muted-badge" style="background:#FFFBEB;color:#D97706;border:1px solid #FDE68A;display:inline-block;padding:3px 10px;border-radius:999px;font-weight:700;font-size:11.5px;">
                                        ⏳ Pending Seller Review
                                    </span>
                                @endif
                            </td>

                            <td>
                                @if ($returnRequest->status === 'approved')
                                    <div style="font-size:12px;font-weight:700;color:var(--text-dark);">
                                        🛵 {{ $deliveringCourier }}
                                    </div>
                                    <div style="font-size:11px;color:#065F46;margin-top:2px;">
                                        Automatically assigned to delivering courier
                                    </div>
                                @elseif ($returnRequest->status === 'denied')
                                    <div style="font-size:11.5px;color:var(--text-muted);">
                                        Claim rejected by seller
                                    </div>
                                @else
                                    <div style="font-size:12px;color:var(--text-muted);">
                                        Courier: <strong>{{ $deliveringCourier }}</strong>
                                    </div>
                                    <div style="font-size:11px;color:var(--text-muted);margin-top:2px;">
                                        Awaiting seller decision
                                    </div>
                                @endif
                            </td>
                        </tr>
                    @empty
                        <tr>
                            <td colspan="8" style="text-align:center;color:var(--text-muted);padding:32px 20px;">
                                No return or refund requests found.
                            </td>
                        </tr>
                    @endforelse
                </tbody>
            </table>
        </div>

        <div style="margin-top:18px;">
            {{ $requests->links() }}
        </div>
    </div>
</x-admin-layout>
