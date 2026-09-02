<!DOCTYPE html>
<html>
<head>
<meta charset="utf-8">
<style>
    body { font-family: Helvetica, Arial, sans-serif; color: #2B1C22; font-size: 12px; }
    .brand { color: #5B1A35; font-size: 18px; font-weight: bold; margin-bottom: 4px; }
    .label-box { border: 2px solid #5B1A35; border-radius: 8px; padding: 20px; margin-top: 16px; }
    .row { display: table; width: 100%; margin-bottom: 16px; }
    .col { display: table-cell; width: 50%; vertical-align: top; }
    .heading { color: #8B7A80; font-size: 10px; text-transform: uppercase; margin-bottom: 4px; }
    .value { font-size: 13px; font-weight: bold; }
    .sub { font-size: 12px; color: #2B1C22; line-height: 1.6; }
    table.items { width: 100%; border-collapse: collapse; margin-top: 16px; }
    table.items th { background: #5B1A35; color: #fff; text-align: left; padding: 6px 8px; font-size: 10px; }
    table.items td { border: 1px solid #F0E2DA; padding: 6px 8px; font-size: 11px; }
    .footer { margin-top: 20px; font-size: 10px; color: #8B7A80; text-align: center; }
</style>
</head>
<body>
    <div class="brand">LUMORA — Shipping Label</div>
    <div style="font-size:11px;color:#8B7A80;">Order #{{ $order->id }} &middot; {{ \Carbon\Carbon::parse($order->created_at)->format('M d, Y') }}</div>

    <div class="label-box">
        <div class="row">
            <div class="col">
                <div class="heading">From</div>
                <div class="value">{{ $shopName }}</div>
                <div class="sub">via Lumora Marketplace</div>
            </div>
            <div class="col">
                <div class="heading">To</div>
                <div class="value">{{ $order->buyer_name }}</div>
                <div class="sub">
                    {{ $order->contact_number ?? '—' }}<br>
                    {{ collect([$order->house_number, $order->street, $order->barangay, $order->municipality, $order->province])->filter()->implode(', ') ?: 'No address on file' }}
                </div>
            </div>
        </div>

        <table class="items">
            <thead>
                <tr><th>Item</th><th>Qty</th><th>Amount</th></tr>
            </thead>
            <tbody>
                @foreach ($items as $item)
                    <tr>
                        <td>{{ $item->product_name }}</td>
                        <td>{{ $item->quantity }}</td>
                        <td>PHP {{ number_format($item->price * $item->quantity, 2) }}</td>
                    </tr>
                @endforeach
                <tr>
                    <td colspan="2" style="font-weight:bold;">Total</td>
                    <td style="font-weight:bold;">PHP {{ number_format($total, 2) }}</td>
                </tr>
            </tbody>
        </table>
    </div>

    <div class="footer">Generated via Lumora Marketplace &middot; Order #{{ $order->id }}</div>
</body>
</html>