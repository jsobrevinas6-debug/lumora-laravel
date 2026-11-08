<x-admin-layout title="Return / Refund">
    <div class="panel">
        <h2>Customer Return / Refund Requests</h2>
        <p style="color:var(--text-muted);margin:-8px 0 18px;font-size:.88rem">Review the buyer’s reason and proof. Approving a return queues a dispatch notification for Lumora Logistics.</p>
        <div style="overflow-x:auto">
            <table>
                <thead><tr><th>Submitted</th><th>Order</th><th>Buyer</th><th>Reason</th><th>Request</th><th>Logistics</th><th>Actions</th></tr></thead>
                <tbody>
                    @forelse ($requests as $returnRequest)
                        <tr>
                            <td>{{ $returnRequest->created_at->format('M d, Y') }}</td>
                            <td>{{ $returnRequest->order->order_number }}<br><small>PHP {{ number_format((float) $returnRequest->order->total, 2) }}</small></td>
                            <td>{{ $returnRequest->buyer->name }}<br><small>{{ $returnRequest->buyer->email }}</small></td>
                            <td>{{ ucwords(str_replace('_', ' ', $returnRequest->reason)) }}<br><small>{{ $returnRequest->details }}</small>
                                @if ($returnRequest->admin_note)<br><small><strong>Admin note:</strong> {{ $returnRequest->admin_note }}</small>@endif
                            </td>
                            <td><span class="muted-badge">{{ ucfirst($returnRequest->status) }}</span></td>
                            <td>
                                @if ($returnRequest->logisticsNotification)
                                    <span class="match-badge">Queued for Lumora Logistics</span>
                                @else
                                    <span class="muted-badge">Not queued</span>
                                @endif
                            </td>
                            <td>
                                <details>
                                    <summary class="btn btn-outline">Review proof ({{ $returnRequest->evidence->count() }})</summary>
                                    <div style="position:absolute;z-index:5;background:white;border:1px solid var(--border);border-radius:12px;padding:14px;max-width:360px;box-shadow:0 8px 28px #45132a20">
                                        <strong>Items</strong>
                                        <ul style="padding:8px 0 10px 18px">@foreach ($returnRequest->order->items as $item)<li>{{ $item->product?->name ?? 'Product unavailable' }} × {{ $item->quantity }}</li>@endforeach</ul>
                                        <strong>Evidence</strong>
                                        <div style="display:flex;gap:8px;flex-wrap:wrap;margin-top:8px">
                                            @forelse ($returnRequest->evidence as $proof)
                                                @php($proofUrl = route('admin.returns.evidence', [$returnRequest, $proof->id]))
                                                <a href="{{ $proofUrl }}" target="_blank" rel="noopener" style="display:block;border:1px solid var(--border);padding:5px;border-radius:8px">
                                                    @if (str_starts_with($proof->mime_type, 'image/'))<img src="{{ $proofUrl }}" alt="Buyer proof" style="width:80px;height:80px;object-fit:cover">@else<video src="{{ $proofUrl }}" controls style="width:180px;max-height:120px"></video>@endif
                                                </a>
                                            @empty <span>No proof attached</span> @endforelse
                                        </div>
                                    </div>
                                </details>
                                @if ($returnRequest->status === 'pending')
                                    <form method="POST" action="{{ route('admin.returns.approve', $returnRequest) }}" style="display:inline-block;margin-top:6px">@csrf<button class="btn btn-dark" type="submit">Approve</button></form>
                                    <form method="POST" action="{{ route('admin.returns.deny', $returnRequest) }}" style="margin-top:6px">@csrf<textarea name="admin_note" required maxlength="1000" placeholder="Reason for denial" style="width:180px;display:block;border:1px solid var(--border);border-radius:8px;padding:6px;margin-bottom:5px"></textarea><button class="btn btn-danger" type="submit">Deny</button></form>
                                @endif
                            </td>
                        </tr>
                    @empty
                        <tr><td colspan="7" style="text-align:center;color:var(--text-muted);padding:24px">No return/refund requests submitted.</td></tr>
                    @endforelse
                </tbody>
            </table>
        </div>
        <div style="margin-top:18px">{{ $requests->links() }}</div>
    </div>
</x-admin-layout>
