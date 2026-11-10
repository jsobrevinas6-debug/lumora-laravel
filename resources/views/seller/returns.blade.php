@extends('layouts.seller')

@section('title', 'Return / Refund Requests')

@section('content')
    @if (session('success'))
        <div class="alert-success">{{ session('success') }}</div>
    @endif
    @if ($errors->any())
        <div class="alert-error">{{ $errors->first() }}</div>
    @endif

    <div class="panel">
        <h2>Customer Return / Refund Requests</h2>
        <p style="color:var(--text-muted);margin:-8px 0 18px;font-size:.88rem">Review requests for your items. Approving a return queues a dispatch notification for Lumora Logistics.</p>
        <div style="overflow-x:auto">
            <table>
                <thead><tr><th>Submitted</th><th>Order</th><th>Buyer</th><th>Reason</th><th>Status</th><th>Logistics</th><th>Actions</th></tr></thead>
                <tbody>
                    @forelse ($requests as $returnRequest)
                        <tr>
                            <td>{{ $returnRequest->created_at->format('M d, Y') }}</td>
                            <td>{{ $returnRequest->order->order_number }}<br><small>PHP {{ number_format((float) $returnRequest->order->total, 2) }}</small></td>
                            <td>{{ $returnRequest->buyer->name }}<br><small>{{ $returnRequest->buyer->email }}</small></td>
                            <td>{{ ucwords(str_replace('_', ' ', $returnRequest->reason)) }}<br><small>{{ $returnRequest->details }}</small>
                                @if ($returnRequest->admin_note)<br><small><strong>Review note:</strong> {{ $returnRequest->admin_note }}</small>@endif
                            </td>
                            <td><span class="status-pill status-{{ $returnRequest->status === 'approved' ? 'approved' : ($returnRequest->status === 'denied' ? 'rejected' : 'pending') }}">{{ ucfirst($returnRequest->status) }}</span></td>
                            <td>@if ($returnRequest->logisticsNotification)<span class="status-pill status-paid">Queued</span>@else<span class="status-pill status-pending">Not queued</span>@endif</td>
                            <td>
                                <details>
                                    <summary class="btn-outline" style="cursor:pointer">Review proof ({{ $returnRequest->evidence->count() }})</summary>
                                    <div style="position:absolute;z-index:5;background:white;border:1px solid var(--border);border-radius:12px;padding:14px;max-width:360px;box-shadow:0 8px 28px #45132a20">
                                        <strong>Your items in this order</strong>
                                        <ul style="padding:8px 0 10px 18px">@foreach ($returnRequest->order->items->where('seller_id', auth()->id()) as $item)<li>{{ $item->product?->name ?? 'Product unavailable' }} × {{ $item->quantity }}</li>@endforeach</ul>
                                        <strong>Buyer evidence</strong>
                                        <div style="display:flex;gap:8px;flex-wrap:wrap;margin-top:8px">
                                            @forelse ($returnRequest->evidence as $proof)
                                                @php($proofUrl = route('seller.returns.evidence', [$returnRequest, $proof->id]))
                                                <a href="{{ $proofUrl }}" target="_blank" rel="noopener" style="display:block;border:1px solid var(--border);padding:5px;border-radius:8px">
                                                    @if (str_starts_with($proof->mime_type, 'image/'))<img src="{{ $proofUrl }}" alt="Buyer proof" style="width:80px;height:80px;object-fit:cover">@else<video src="{{ $proofUrl }}" controls style="width:180px;max-height:120px"></video>@endif
                                                </a>
                                            @empty <span>No proof attached</span> @endforelse
                                        </div>
                                    </div>
                                </details>
                                @if ($returnRequest->status === 'pending')
                                    <form method="POST" action="{{ route('seller.returns.approve', $returnRequest) }}" style="margin-top:6px" onsubmit="return confirm('Approve this return and notify Lumora Logistics?')">@csrf<button class="btn-solid" type="submit">Approve</button></form>
                                    <form method="POST" action="{{ route('seller.returns.deny', $returnRequest) }}" style="margin-top:6px">@csrf<textarea name="seller_note" required maxlength="1000" placeholder="Reason for denial" style="width:180px;display:block;border:1px solid var(--border);border-radius:8px;padding:6px;margin-bottom:5px"></textarea><button class="btn-outline" type="submit">Deny</button></form>
                                @endif
                            </td>
                        </tr>
                    @empty
                        <tr><td colspan="7" style="text-align:center;color:var(--text-muted);padding:24px">No return/refund requests for your orders.</td></tr>
                    @endforelse
                </tbody>
            </table>
        </div>
        <div style="margin-top:18px">{{ $requests->links() }}</div>
    </div>
@endsection
