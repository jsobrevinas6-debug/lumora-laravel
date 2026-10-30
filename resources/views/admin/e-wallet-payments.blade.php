<x-admin-layout title="E-Wallet Payments">
    <div class="panel">
        <h2>Buyer payment submissions</h2>
        <p style="color:var(--text-muted);margin:-8px 0 18px;font-size:.9rem">GCash and Maya orders with buyer details and payment proof.</p>

        @forelse ($orders as $order)
            <section style="border:1px solid var(--border);border-radius:14px;padding:18px;margin-bottom:16px">
                <div style="display:flex;justify-content:space-between;gap:16px;flex-wrap:wrap;margin-bottom:12px">
                    <div><strong>Order {{ $order->order_number }}</strong><div style="color:var(--text-muted);font-size:.85rem">Placed {{ $order->created_at?->format('M j, Y g:i A') }}</div></div>
                    <div><span class="muted-badge">{{ strtoupper($order->payment_method) === 'PAYMAYA' ? 'Maya' : ucfirst($order->payment_method) }}</span> <span class="muted-badge">{{ ucfirst($order->payment_status) }} payment</span> <strong>PHP {{ number_format((float) $order->total, 2) }}</strong></div>
                </div>
                <div style="display:grid;grid-template-columns:repeat(auto-fit,minmax(190px,1fr));gap:12px;margin-bottom:14px;font-size:.88rem">
                    <div><strong>Buyer</strong><br>{{ $order->user?->name ?? 'Unknown' }}<br>{{ $order->user?->email ?? '' }}</div>
                    <div><strong>Order status</strong><br>{{ $order->status_label }}</div>
                    <div><strong>Seller</strong><br>{{ $order->seller?->name ?? 'Multiple / unavailable' }}</div>
                    <div><strong>Subtotal / shipping</strong><br>PHP {{ number_format((float) $order->subtotal, 2) }} / PHP {{ number_format((float) $order->shipping_fee, 2) }}</div>
                    <div><strong>Reference number ending</strong><br>{{ $order->payment_reference_last6 ? '••'.$order->payment_reference_last6 : 'Not provided' }}</div>
                </div>
                <div style="font-size:.88rem;margin-bottom:14px"><strong>Items</strong><ul style="padding-left:20px;margin-top:4px">
                    @foreach ($order->items as $item)
                        <li>{{ $item->product?->name ?? 'Product unavailable' }} × {{ $item->quantity }} — PHP {{ number_format((float) $item->subtotal, 2) }}</li>
                    @endforeach
                </ul></div>
                <div><strong style="font-size:.88rem">Buyer payment screenshot</strong><br>
                    @if ($order->payment_proof_available)
                        <a href="{{ route('admin.e-wallet-payments.proof', $order) }}" target="_blank" rel="noopener" style="display:inline-block;margin-top:8px"><img src="{{ route('admin.e-wallet-payments.proof', $order) }}" alt="Payment proof for order {{ $order->order_number }}" style="max-width:280px;max-height:220px;object-fit:contain;border:1px solid var(--border);border-radius:10px"></a>
                    @elseif ($order->payment_proof_path)
                        <p style="color:var(--text-muted);font-size:.85rem;margin-top:6px">The receipt file is missing from the configured storage. Ask the buyer to submit the receipt again.</p>
                    @else
                        <p style="color:var(--text-muted);font-size:.85rem;margin-top:6px">No screenshot was attached to this order.</p>
                    @endif
                </div>
                @if ($order->payment_status === 'pending' && $order->status === 'pending')
                    <div style="display:flex;gap:10px;margin-top:16px;flex-wrap:wrap">
                        <form method="POST" action="{{ route('admin.e-wallet-payments.approve', $order) }}">
                            @csrf
                            <button class="btn btn-dark" type="submit" @disabled(!$order->payment_proof_available || !preg_match('/^\d{6}$/', (string) $order->payment_reference_last6))>Approve payment</button>
                        </form>
                        <form method="POST" action="{{ route('admin.e-wallet-payments.reject', $order) }}" onsubmit="return confirm('Reject this payment and cancel the order?')">
                            @csrf
                            <button class="btn btn-danger" type="submit">Reject and cancel order</button>
                        </form>
                    </div>
                @endif
            </section>
        @empty
            <p style="color:var(--text-muted)">No GCash or Maya payments have been submitted yet.</p>
        @endforelse

        @if ($orders->hasPages())
            <div style="margin-top:18px">{{ $orders->links() }}</div>
        @endif
    </div>
</x-admin-layout>
