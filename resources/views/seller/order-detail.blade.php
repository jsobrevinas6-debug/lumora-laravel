@extends('layouts.seller')

@section('title', 'Order #' . $order->id)

@section('content')
    @if (session('success'))
        <div class="alert-success">{{ session('success') }}</div>
    @endif

    <div class="panel">
        <div style="display:flex;justify-content:space-between;align-items:flex-start;margin-bottom:18px;">
            <div>
                <h2 style="margin-bottom:2px;">Order #{{ $order->id }}</h2>
                <div style="font-size:13px;color:var(--text-muted);">{{ \Carbon\Carbon::parse($order->created_at)->format('M d, Y g:i A') }}</div>
            </div>
            @php $allPacked = $items->every(fn($i) => $i->packed_at !== null); @endphp
            <span class="stock-badge" style="background:{{ $allPacked ? 'var(--sage-2)' : 'var(--terra-1)' }};">
                {{ $allPacked ? 'Packed' : 'Pending' }}
            </span>
        </div>

        <table style="margin-bottom:20px;">
            <thead>
                <tr><th>Product</th><th>Qty</th><th>Price</th></tr>
            </thead>
            <tbody>
                @foreach ($items as $item)
                    <tr>
                        <td>{{ $item->product_name }}</td>
                        <td>x{{ $item->quantity }}</td>
                        <td>PHP {{ number_format($item->price * $item->quantity, 2) }}</td>
                    </tr>
                @endforeach
                <tr>
                    <td colspan="2" style="font-weight:700;border-bottom:none;">Total</td>
                    <td style="font-weight:700;border-bottom:none;">PHP {{ number_format($items->sum(fn($i) => $i->price * $i->quantity), 2) }}</td>
                </tr>
            </tbody>
        </table>

        <div style="border-top:1px solid var(--border);padding-top:14px;margin-bottom:20px;font-size:13.5px;color:var(--text-muted);line-height:1.7;">
            <div>{{ $order->buyer_name }} &middot; {{ $order->contact_number ?? '—' }}</div>
            <div>
                {{ collect([$order->house_number, $order->street, $order->barangay, $order->municipality, $order->province])->filter()->implode(', ') ?: 'No address on file' }}
            </div>
        </div>

        <div style="display:flex;gap:12px;">
            @if (!$allPacked)
                <form action="{{ route('seller.orders.pack', $order->id) }}" method="POST">
                    @csrf
                    <button type="submit" class="btn-solid">Mark as packed</button>
                </form>
            @endif
            <a href="{{ route('seller.orders.waybill', $order->id) }}" class="btn-outline" style="text-decoration:none;display:inline-block;">Print waybill</a>
        </div>
    </div>
@endsection