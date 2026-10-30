<x-admin-layout title="Payout Requests">
    <style>
        .payout-stats { display:grid; grid-template-columns:repeat(auto-fit,minmax(190px,1fr)); gap:18px; margin-bottom:22px; }
        .payout-stat { background:#fff; border:1px solid var(--border); border-radius:var(--radius); padding:20px; }
        .payout-stat span { display:block; color:var(--text-muted); font-size:13px; margin-bottom:8px; }
        .payout-stat strong { font-size:21px; }
        .payout-note { margin-bottom:18px; color:var(--text-muted); font-size:13px; }
        .payout-tabs { display:flex; flex-wrap:wrap; gap:8px; margin-bottom:20px; }
        .payout-tab { min-height:40px; display:inline-flex; align-items:center; padding:7px 13px; border:1px solid var(--border); border-radius:999px; color:var(--text-dark); text-decoration:none; font-size:13px; }
        .payout-tab.active { color:#fff; background:var(--maroon); border-color:var(--maroon); }
        .payout-card { padding:20px; border:1px solid var(--border); border-radius:14px; margin-bottom:14px; }
        .payout-head { display:flex; justify-content:space-between; align-items:flex-start; gap:14px; flex-wrap:wrap; margin-bottom:14px; }
        .payout-head h2 { margin:0 0 3px; font-size:16px; }
        .payout-meta { color:var(--text-muted); font-size:12px; }
        .payout-amount { font-size:20px; font-weight:800; }
        .payout-details { display:grid; grid-template-columns:repeat(auto-fit,minmax(180px,1fr)); gap:12px; font-size:13px; margin-bottom:16px; }
        .payout-details strong { display:block; margin-bottom:3px; }
        .payout-actions { display:flex; align-items:flex-end; gap:10px; flex-wrap:wrap; padding-top:14px; border-top:1px solid var(--border); }
        .payout-actions form { display:flex; align-items:flex-end; gap:8px; flex-wrap:wrap; }
        .payout-actions input,.payout-actions textarea { min-height:38px; padding:7px 10px; border:1px solid var(--border); border-radius:8px; font:inherit; font-size:12px; }
        .payout-actions textarea { width:min(320px,70vw); min-height:38px; }
        .status-pill { display:inline-block; padding:4px 10px; border-radius:999px; background:#f2ecee; color:var(--text-muted); font-size:12px; }
        .status-pill.pending { background:#fff1d6; color:#7a4f00; }
        .status-pill.approved { background:#e8eefb; color:#35517c; }
        .status-pill.paid { background:#e5f3e9; color:#38634b; }
        .status-pill.rejected { background:#fbeee8; color:#a3432e; }
        .empty-payouts { padding:24px 0; color:var(--text-muted); text-align:center; }
        @media (max-width:900px) { .payout-stats { grid-template-columns:repeat(2,minmax(0,1fr)); } }
        @media (max-width:520px) { .payout-stats { grid-template-columns:1fr; } .payout-card { padding:16px; } .payout-actions form { width:100%; } .payout-actions input,.payout-actions textarea { width:100%; } }
    </style>

    <div class="payout-stats">
        <div class="payout-stat"><span>Pending requests ({{ $pendingCount }})</span><strong>PHP {{ number_format((float) $pendingAmount, 2) }}</strong></div>
        <div class="payout-stat"><span>Approved, awaiting transfer</span><strong>PHP {{ number_format((float) $approvedAmount, 2) }}</strong></div>
        <div class="payout-stat"><span>Paid to sellers</span><strong>PHP {{ number_format((float) $paidAmount, 2) }}</strong></div>
        <div class="payout-stat"><span>Confirmed e-wallet receipts</span><strong>PHP {{ number_format((float) $confirmedWalletReceipts, 2) }}</strong></div>
        <div class="payout-stat"><span>Estimated funds after payout commitments</span><strong>PHP {{ number_format((float) $estimatedUnallocatedFunds, 2) }}</strong></div>
    </div>

    <div class="panel">
        <h2>Seller payout requests</h2>
        <p class="payout-note">Review the payout details. Complete the transfer through your payment provider before marking a request as paid. Receipt and remaining-funds totals are bookkeeping estimates based on admin-approved e-wallet orders, not live provider balances. This page does not send money automatically.</p>
        <nav class="payout-tabs" aria-label="Filter payout requests">
            @foreach (['pending' => 'Pending', 'approved' => 'Approved', 'paid' => 'Paid', 'rejected' => 'Rejected', 'all' => 'All'] as $key => $label)
                <a class="payout-tab {{ $status === $key ? 'active' : '' }}" href="{{ route('admin.payout-requests.index', ['status' => $key]) }}">{{ $label }}</a>
            @endforeach
        </nav>

        @forelse ($payouts as $payout)
            <section class="payout-card">
                <div class="payout-head">
                    <div>
                        <h2>{{ $payout->seller_name }}</h2>
                        <div class="payout-meta">{{ $payout->seller_email }} · Request #{{ $payout->id }} · {{ \Carbon\Carbon::parse($payout->created_at)->format('M j, Y g:i A') }}</div>
                    </div>
                    <div style="text-align:right"><span class="status-pill {{ $payout->status }}">{{ ucfirst($payout->status) }}</span><div class="payout-amount">PHP {{ number_format((float) $payout->amount, 2) }}</div></div>
                </div>
                <div class="payout-details">
                    <div><strong>Payout method</strong>{{ $payout->method === 'gcash' ? 'GCash' : ($payout->method === 'paymaya' ? 'Maya' : 'Bank transfer') }}</div>
                    <div><strong>Account name</strong>{{ $payout->account_name }}</div>
                    <div><strong>Account number</strong>{{ $payout->account_number }}</div>
                    @if ($payout->bank_name)<div><strong>Bank</strong>{{ $payout->bank_name }}</div>@endif
                    @if ($payout->paid_at)<div><strong>Paid at</strong>{{ \Carbon\Carbon::parse($payout->paid_at)->format('M j, Y g:i A') }}</div>@endif
                    @if ($payout->transfer_reference)<div><strong>Transfer reference</strong>{{ $payout->transfer_reference }}</div>@endif
                    @if ($payout->rejection_reason)<div><strong>Rejection reason</strong>{{ $payout->rejection_reason }}</div>@endif
                </div>

                @if ($payout->status === 'pending')
                    <div class="payout-actions">
                        <form method="POST" action="{{ route('admin.payout-requests.approve', $payout->id) }}">
                            @csrf
                            <button class="btn btn-dark" type="submit">Approve request</button>
                        </form>
                        <form method="POST" action="{{ route('admin.payout-requests.reject', $payout->id) }}">
                            @csrf
                            <textarea name="rejection_reason" maxlength="1000" placeholder="Reason for rejection" required></textarea>
                            <button class="btn btn-danger" type="submit">Reject</button>
                        </form>
                    </div>
                @elseif ($payout->status === 'approved')
                    <div class="payout-actions">
                        <form method="POST" action="{{ route('admin.payout-requests.paid', $payout->id) }}">
                            @csrf
                            <input type="text" name="transfer_reference" maxlength="120" placeholder="Transfer reference" required>
                            <button class="btn btn-dark" type="submit">Mark as paid</button>
                        </form>
                    </div>
                @endif
            </section>
        @empty
            <div class="empty-payouts">No {{ $status === 'all' ? '' : $status }} payout requests found.</div>
        @endforelse

        @if ($payouts->hasPages())<div style="margin-top:18px">{{ $payouts->links() }}</div>@endif
    </div>
</x-admin-layout>
