<!DOCTYPE html>
<html>
<head>
<meta charset="utf-8">
<style>
    body { font-family: Helvetica, Arial, sans-serif; color: #2B1C22; font-size: 11px; }
    .brand { color: #5B1A35; font-size: 15px; font-weight: bold; margin-bottom: 4px; }
    h1 { color: #5B1A35; font-size: 22px; margin: 0 0 2px; }
    .subtitle { color: #8B7A80; font-size: 10px; margin-bottom: 14px; }
    hr { border: none; border-top: 1px solid #F0E2DA; margin-bottom: 14px; }

    .stats-table { width: 100%; border-collapse: collapse; margin-bottom: 20px; }
    .stats-table td { background: #FBF1EC; border: 1px solid #F0E2DA; padding: 10px 12px; width: 33.33%; }
    .stat-label { color: #8B7A80; font-size: 9px; display: block; margin-bottom: 4px; }
    .stat-value { color: #2B1C22; font-size: 16px; font-weight: bold; }

    h2 { color: #45132A; font-size: 13px; margin: 18px 0 8px; }

    table.data { width: 100%; border-collapse: collapse; }
    table.data th { background: #5B1A35; color: #fff; text-align: left; padding: 7px 8px; font-size: 9.5px; }
    table.data td { border: 1px solid #F0E2DA; padding: 7px 8px; font-size: 9.5px; }
    table.data tr:nth-child(even) td { background: #FBF1EC; }
    .num { text-align: right; }

    .footer { margin-top: 24px; padding-top: 8px; border-top: 1px solid #F0E2DA; text-align: center; color: #8B7A80; font-size: 8px; }
</style>
</head>
<body>
    <div class="brand">LUMORA</div>
    <h1>Financial &amp; Profit Report</h1>
    <div class="subtitle">{{ $shopName }} &nbsp;|&nbsp; {{ $start->format('M d, Y') }} &ndash; {{ $end->format('M d, Y') }} &nbsp;|&nbsp; Generated {{ now()->format('M d, Y \a\t g:i A') }}</div>
    <hr>

    <table class="stats-table">
        <tr>
            <td>
                <span class="stat-label">GROSS REVENUE</span>
                <span class="stat-value">PHP {{ number_format($grossSales, 2) }}</span>
            </td>
            <td>
                <span class="stat-label">PLATFORM COMMISSION (10%)</span>
                <span class="stat-value">PHP {{ number_format($commission, 2) }}</span>
            </td>
            <td>
                <span class="stat-label">NET EARNINGS</span>
                <span class="stat-value">PHP {{ number_format($netEarnings, 2) }}</span>
            </td>
        </tr>
    </table>

    <p style="font-size:10px;color:#8B7A80;margin-bottom:16px;">Total orders in this period: <strong>{{ $totalOrders }}</strong></p>

    <h2>Payout Requests in This Period</h2>
    <table class="data">
        <thead>
            <tr>
                <th>Date</th>
                <th>Method</th>
                <th class="num">Amount</th>
                <th>Status</th>
            </tr>
        </thead>
        <tbody>
            @forelse ($payouts as $p)
                <tr>
                    <td>{{ \Carbon\Carbon::parse($p->created_at)->format('M d, Y') }}</td>
                    <td>{{ $p->method === 'gcash' ? 'GCash' : ($p->method === 'paymaya' ? 'Maya' : 'Bank Transfer') }}</td>
                    <td class="num">PHP {{ number_format($p->amount, 2) }}</td>
                    <td>{{ ucfirst($p->status) }}</td>
                </tr>
            @empty
                <tr><td colspan="4" style="text-align:center;color:#8B7A80;">No payout requests in this date range.</td></tr>
            @endforelse
        </tbody>
    </table>

    <div class="footer">Lumora Marketplace &mdash; Confidential Seller Report</div>
</body>
</html>