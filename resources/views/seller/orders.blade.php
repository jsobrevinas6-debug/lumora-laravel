@extends('layouts.seller')

@section('title', 'Orders')

@section('content')
    @if (session('success'))
        <div class="alert-success">{{ session('success') }}</div>
    @endif

    <div class="panel">
        <table>
            <thead>
                <tr>
                    <th>Order</th>
                    <th>Buyer</th>
                    <th>Date</th>
                    <th>Subtotal</th>
                    <th>Status</th>
                    <th></th>
                </tr>
            </thead>
            <tbody>
                @forelse ($orders as $o)
                    <tr>
                        <td>
                            #{{ $o->order_id }}
                            @if ($o->unseen_count > 0)
                                <span class="stock-badge" style="background:var(--coral);">New</span>
                            @endif
                        </td>
                        <td>{{ $o->buyer_name }}</td>
                        <td>{{ \Carbon\Carbon::parse($o->order_date)->format('M d, Y') }}</td>
                        <td>PHP {{ number_format($o->seller_subtotal, 2) }}</td>
                        <td>
                            @if ($o->unpacked_count == 0)
                                <span class="stock-badge" style="background:var(--sage-2);">Packed</span>
                            @else
                                <span class="stock-badge" style="background:var(--terra-1);">Pending</span>
                            @endif
                        </td>
                        <td>
                            <a href="{{ route('seller.orders.show', $o->order_id) }}" class="edit-stock-btn" style="text-decoration:none;display:inline-block;">View</a>
                        </td>
                    </tr>
                @empty
                    <tr><td colspan="6" style="text-align:center;color:#999;padding:20px;">No orders yet.</td></tr>
                @endforelse
            </tbody>
        </table>
    </div>
@endsection