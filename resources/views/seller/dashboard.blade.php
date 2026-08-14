@extends('layouts.seller')

@section('title', 'Dashboard')

@section('content')
    <div class="stats-grid">
        <div class="stat-card">
            <div class="stat-icon icon-sales">₱</div>
            <div class="stat-label">Total Sales</div>
            <div class="stat-value">PHP {{ number_format($totalSales, 2) }}</div>
        </div>
        <div class="stat-card">
            <div class="stat-icon icon-orders">🧾</div>
            <div class="stat-label">Total Orders</div>
            <div class="stat-value">{{ $totalOrders }}</div>
        </div>
        <div class="stat-card">
            <div class="stat-icon icon-products">📦</div>
            <div class="stat-label">My Products</div>
            <div class="stat-value">{{ $totalProducts }}</div>
        </div>
    </div>

    <div class="panel">
        <h2>Low Stock Products</h2>
        <table>
            <thead><tr><th>Product</th><th>Stock</th></tr></thead>
            <tbody>
                @forelse ($lowStock as $p)
                <tr>
                    <td>{{ $p->name }}</td>
                    <td><span class="stock-badge">{{ $p->stock }}</span></td>
                </tr>
                @empty
                <tr><td colspan="2" style="text-align:center;color:#999;padding:20px;">No low-stock products.</td></tr>
                @endforelse
            </tbody>
        </table>
    </div>
@endsection