<x-admin-layout title="Dashboard">
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
            <div class="stat-label">Products</div>
            <div class="stat-value">{{ $totalProducts }}</div>
        </div>
        <div class="stat-card">
            <div class="stat-icon icon-buyers">👤</div>
            <div class="stat-label">Buyers</div>
            <div class="stat-value">{{ $totalBuyers }}</div>
        </div>
    </div>

    <div class="panel">
        <h2>Pending Seller Applications</h2>
        <table>
            <thead>
                <tr><th>Applicant</th><th>Email</th><th>Business Name</th><th>Applied</th><th></th></tr>
            </thead>
            <tbody>
                @forelse ($applications as $a)
                <tr>
                    <td>{{ $a->name }}</td>
                    <td>{{ $a->email }}</td>
                    <td>{{ $a->business_name }}</td>
                    <td>{{ \Carbon\Carbon::parse($a->created_at)->format('M d, Y') }}</td>
                    <td style="text-align:right; white-space:nowrap;">
                        <form method="POST" action="{{ route('admin.applications.approve', $a->id) }}" style="display:inline-block" onsubmit="return confirm('Approve this application and activate seller access?')">@csrf<button class="btn btn-dark" type="submit">Approve</button></form>
                        <form method="POST" action="{{ route('admin.applications.archive', $a->id) }}" style="display:inline-block">@csrf<button class="btn btn-outline" type="submit">Archive</button></form>
                    </td>
                </tr>
                @empty
                <tr><td colspan="5" style="text-align:center;color:#999;padding:20px;">No pending applications.</td></tr>
                @endforelse
            </tbody>
        </table>
    </div>
</x-admin-layout>
