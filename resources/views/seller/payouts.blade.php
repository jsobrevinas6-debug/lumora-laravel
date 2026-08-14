@extends('layouts.seller')

@section('title', 'Payouts / Earnings')

@section('content')
    @if (session('success'))
        <div class="alert-success">{{ session('success') }}</div>
    @endif
    @if (session('error'))
        <div class="alert-error">{{ session('error') }}</div>
    @endif

    <div class="stats-grid">
        <div class="stat-card">
            <div class="stat-icon icon-sales">₱</div>
            <div class="stat-label">Total Revenue</div>
            <div class="stat-value">PHP {{ number_format($totalSales, 2) }}</div>
        </div>
        <div class="stat-card">
            <div class="stat-icon icon-orders">🧾</div>
            <div class="stat-label">Total Sales (Orders)</div>
            <div class="stat-value">{{ $totalOrders }}</div>
        </div>
        <div class="stat-card">
            <div class="stat-icon icon-products">💰</div>
            <div class="stat-label">Available Balance</div>
            <div class="stat-value">PHP {{ number_format($availableBalance, 2) }}</div>
        </div>
    </div>

    {{-- Current payout method --}}
    @if ($payoutMethod)
        <div class="current-method-card">
            <div>
                <div style="font-size:13px; color:var(--text-muted); margin-bottom:6px;">Current Payout Method</div>
                @if ($payoutMethod->method === 'gcash')
                    <span class="method-badge badge-gcash">GCash</span>
                @elseif ($payoutMethod->method === 'paymaya')
                    <span class="method-badge badge-paymaya">Maya</span>
                @else
                    <span class="method-badge badge-bank">🏦 {{ $payoutMethod->bank_name }}</span>
                @endif
                <div style="font-size:13.5px; color:var(--text-muted); margin-top:8px;">
                    {{ $payoutMethod->account_name }} &middot; {{ $payoutMethod->account_number }}
                </div>
            </div>
        </div>
    @endif

    <div class="earnings-actions">
        <button type="button" class="btn-outline" onclick="document.getElementById('methodModal').style.display='flex'">
            {{ $payoutMethod ? 'Update Payout Method' : 'Set Payout Method' }}
        </button>
        <button type="button" class="btn-solid" onclick="document.getElementById('requestModal').style.display='flex'">
            Request Payout
        </button>
    </div>

    {{-- Payout history --}}
    <div class="panel">
        <h2>Payout History</h2>
        <table>
            <thead>
                <tr>
                    <th>Date</th>
                    <th>Amount</th>
                    <th>Method</th>
                    <th>Status</th>
                </tr>
            </thead>
            <tbody>
                @forelse ($payoutHistory as $payout)
                    <tr>
                        <td>{{ \Carbon\Carbon::parse($payout->created_at)->format('M d, Y') }}</td>
                        <td>PHP {{ number_format($payout->amount, 2) }}</td>
                        <td>
                            @if ($payout->method === 'gcash') GCash
                            @elseif ($payout->method === 'paymaya') Maya
                            @else Bank Transfer @endif
                        </td>
                        <td><span class="status-pill status-{{ $payout->status }}">{{ ucfirst($payout->status) }}</span></td>
                    </tr>
                @empty
                    <tr><td colspan="4" style="text-align:center;color:#999;padding:20px;">No payout requests yet.</td></tr>
                @endforelse
            </tbody>
        </table>
    </div>

    {{-- Set/Update Payout Method Modal --}}
    <div id="methodModal" class="modal-overlay">
        <div class="modal-box">
            <h2>Payout Method</h2>
            <form action="{{ route('seller.payouts.saveMethod') }}" method="POST" class="modal-form">
                @csrf
                <select name="method" id="methodSelect" required onchange="document.getElementById('bankNameField').style.display = this.value === 'bank_transfer' ? 'block' : 'none'">
                    <option value="">Select method</option>
                    <option value="gcash" {{ $payoutMethod?->method === 'gcash' ? 'selected' : '' }}>GCash</option>
                    <option value="paymaya" {{ $payoutMethod?->method === 'paymaya' ? 'selected' : '' }}>Maya (PayMaya)</option>
                    <option value="bank_transfer" {{ $payoutMethod?->method === 'bank_transfer' ? 'selected' : '' }}>Bank Transfer</option>
                </select>
                <input type="text" name="account_name" placeholder="Account name" value="{{ $payoutMethod->account_name ?? '' }}" required>
                <input type="text" name="account_number" placeholder="Mobile / account number" value="{{ $payoutMethod->account_number ?? '' }}" required>
                <input type="text" name="bank_name" id="bankNameField" placeholder="Bank name" value="{{ $payoutMethod->bank_name ?? '' }}" style="display:{{ $payoutMethod?->method === 'bank_transfer' ? 'block' : 'none' }};">
                <div class="modal-btn-row">
                    <button type="button" class="btn-cancel" onclick="document.getElementById('methodModal').style.display='none'">Cancel</button>
                    <button type="submit" class="btn-solid">Save</button>
                </div>
            </form>
        </div>
    </div>

    {{-- Request Payout Modal --}}
    <div id="requestModal" class="modal-overlay">
        <div class="modal-box">
            <h2>Request Payout</h2>
            <p style="font-size:13.5px; color:var(--text-muted); margin-bottom:14px;">
                Available balance: <strong>PHP {{ number_format($availableBalance, 2) }}</strong>
            </p>
            <form action="{{ route('seller.payouts.request') }}" method="POST" class="modal-form">
                @csrf
                <input type="number" name="amount" placeholder="Amount (PHP)" min="100" step="0.01" max="{{ $availableBalance }}" required>
                <div class="modal-btn-row">
                    <button type="button" class="btn-cancel" onclick="document.getElementById('requestModal').style.display='none'">Cancel</button>
                    <button type="submit" class="btn-solid">Submit Request</button>
                </div>
            </form>
        </div>
    </div>
@endsection