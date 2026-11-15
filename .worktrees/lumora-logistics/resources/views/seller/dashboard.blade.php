@extends('layouts.seller')

@section('title', 'Dashboard')

@section('content')
    @php
        $lowStockCount = method_exists($lowStock, 'total') ? $lowStock->total() : $lowStock->count();
    @endphp

    <div class="dashboard-intro">
        <div>
            <h2>Welcome back, {{ Auth::user()->first_name ?: Auth::user()->name }}</h2>
            <p>Here’s what’s happening with your store today.</p>
        </div>
        <div class="dashboard-date">{{ now()->format('M j, Y') }}</div>
    </div>

    <div class="premium-stats-grid">
        <div class="premium-stat-card">
            <div class="premium-stat-icon sales-icon"><svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" aria-hidden="true"><path d="M6 8h12l1 12H5L6 8Z"/><path d="M9 8a3 3 0 0 1 6 0"/><path d="M9 12h.01M15 12h.01"/></svg></div>
            <div class="premium-stat-label">Total Sales</div>
            <div class="premium-stat-value">PHP {{ number_format($totalSales, 2) }}</div>
        </div>
        <div class="premium-stat-card">
            <div class="premium-stat-icon orders-icon"><svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" aria-hidden="true"><rect x="5" y="3" width="14" height="18" rx="2"/><path d="M8 7h8M8 11h8M8 15h5"/></svg></div>
            <div class="premium-stat-label">Total Orders</div>
            <div class="premium-stat-value">{{ number_format($totalOrders) }}</div>
        </div>
        <div class="premium-stat-card">
            <div class="premium-stat-icon products-icon"><svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" aria-hidden="true"><path d="m12 3 8 4.5v9L12 21l-8-4.5v-9L12 3Z"/><path d="m4.5 7.5 7.5 4 7.5-4M12 12v9"/></svg></div>
            <div class="premium-stat-label">My Products</div>
            <div class="premium-stat-value">{{ number_format($totalProducts) }}</div>
        </div>
        <div class="premium-stat-card">
            <div class="premium-stat-icon alerts-icon"><svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" aria-hidden="true"><path d="M12 3 21 20H3L12 3Z"/><path d="M12 9v5M12 17h.01"/></svg></div>
            <div class="premium-stat-label">Low Stock Alerts</div>
            <div class="premium-stat-value">{{ number_format($lowStockCount) }}</div>
        </div>
    </div>

    <div class="dashboard-content-grid">
        <section class="premium-panel sales-panel">
            <div class="panel-heading-row">
                <div>
                    <h2>Sales Trend</h2>
                    <p>Track your paid sales activity over time.</p>
                </div>
                <div class="range-buttons">
                    <button type="button" id="range7Btn" class="chart-range-btn active" onclick="setRange(7)">7 Days</button>
                    <button type="button" id="range30Btn" class="chart-range-btn" onclick="setRange(30)">30 Days</button>
                </div>
            </div>
            <div class="chart-container">
                <canvas id="salesTrendChart"></canvas>
                @if (($salesTrend7['values'] ?? []) && max($salesTrend7['values']) == 0)
                    <div class="chart-empty-note">No sales data yet. Your sales trend will appear here after receiving orders.</div>
                @endif
            </div>
        </section>

        <section class="premium-panel low-stock-panel">
            <div class="panel-heading-row">
                <div>
                    <h2>Low Stock Products</h2>
                    <p>Active products with 20 units or fewer.</p>
                </div>
                <a href="{{ route('seller.products.index') }}" class="text-link">View all</a>
            </div>

            <form method="GET" action="{{ route('seller.dashboard') }}" class="low-stock-search-form">
                <input type="search" name="low_stock_search" value="{{ $lowStockSearch ?? request('low_stock_search') }}" placeholder="Search low-stock products..." aria-label="Search low-stock products">
                <button type="submit">Search</button>
                @if (($lowStockSearch ?? request('low_stock_search')) !== '')
                    <a href="{{ route('seller.dashboard') }}" class="clear-link">Clear</a>
                @endif
            </form>

            <div class="table-wrap">
                <table class="premium-table">
                    <thead><tr><th>Product</th><th>Stock</th></tr></thead>
                    <tbody>
                        @forelse ($lowStock as $product)
                            <tr>
                                <td>{{ $product->name }}</td>
                                <td><span class="stock-badge">{{ $product->stock }}</span></td>
                            </tr>
                        @empty
                            <tr><td colspan="2" class="empty-cell">{{ ($lowStockSearch ?? request('low_stock_search')) !== '' ? 'No matching low-stock products.' : 'No low-stock products.' }}</td></tr>
                        @endforelse
                    </tbody>
                </table>
            </div>

            @if ($lowStock->hasPages())
                <div class="pagination-row">
                    <span>{{ $lowStock->firstItem() }}–{{ $lowStock->lastItem() }} of {{ $lowStock->total() }}</span>
                    <div class="pagination-links">
                        @if ($lowStock->onFirstPage()) <span class="page-link disabled">‹</span> @else <a class="page-link" href="{{ $lowStock->previousPageUrl() }}">‹</a> @endif
                        @foreach ($lowStock->getUrlRange(max(1, $lowStock->currentPage() - 1), min($lowStock->lastPage(), $lowStock->currentPage() + 1)) as $page => $url)
                            @if ($page == $lowStock->currentPage()) <span class="page-link current">{{ $page }}</span> @else <a class="page-link" href="{{ $url }}">{{ $page }}</a> @endif
                        @endforeach
                        @if ($lowStock->hasMorePages()) <a class="page-link" href="{{ $lowStock->nextPageUrl() }}">›</a> @else <span class="page-link disabled">›</span> @endif
                    </div>
                </div>
            @endif
        </section>
    </div>

    <section class="premium-panel activity-panel">
        <div class="panel-heading-row">
            <div>
                <h2>Recent Activity</h2>
                <p>Your latest store updates will appear here.</p>
            </div>
        </div>
        <div class="activity-empty">
            <div class="activity-empty-icon">□</div>
            <div><strong>No recent activity yet.</strong><span>Your recent store actions will appear here.</span></div>
        </div>
    </section>

    <style>
        .dashboard-intro { display:flex; justify-content:space-between; align-items:flex-start; margin-bottom:24px; }
        .dashboard-intro h2 { margin:0 0 5px; color:var(--text-dark); font-size:22px; font-weight:800; }
        .dashboard-intro p, .panel-heading-row p { color:var(--text-muted); font-size:13px; margin:0; }
        .dashboard-date { padding:9px 14px; background:#fff; border:1px solid var(--border); border-radius:10px; color:var(--text-muted); font-size:12px; }
        .premium-stats-grid { display:grid; grid-template-columns:repeat(4, minmax(0, 1fr)); gap:18px; margin-bottom:22px; }
        .premium-stat-card { background:var(--card-bg); border:1px solid var(--border); border-radius:16px; padding:20px; box-shadow:0 5px 20px rgba(91,26,53,.045); }
        .premium-stat-icon { width:38px; height:38px; border-radius:11px; display:flex; align-items:center; justify-content:center; color:#fff; font-size:20px; font-weight:700; margin-bottom:15px; }
        .premium-stat-icon svg { width:21px; height:21px; display:block; }
        .sales-icon { background:linear-gradient(135deg,#D98A5E,#B85C3B); }
        .orders-icon { background:linear-gradient(135deg,#6E2149,#45132A); }
        .products-icon { background:linear-gradient(135deg,#88A280,#5C7355); }
        .alerts-icon { background:linear-gradient(135deg,#E98263,#C85B46); }
        .premium-stat-label { color:var(--text-muted); font-size:12.5px; margin-bottom:5px; }
        .premium-stat-value { color:var(--text-dark); font-size:22px; font-weight:800; }
        .dashboard-content-grid { display:grid; grid-template-columns:1.12fr .88fr; gap:20px; align-items:start; }
        .premium-panel { background:var(--card-bg); border:1px solid var(--border); border-radius:18px; padding:22px; box-shadow:0 5px 20px rgba(91,26,53,.045); }
        .panel-heading-row { display:flex; align-items:flex-start; justify-content:space-between; gap:12px; margin-bottom:16px; }
        .panel-heading-row h2 { margin:0 0 5px; font-size:17px; font-weight:800; }
        .range-buttons { display:flex; gap:6px; }
        .chart-range-btn { padding:6px 13px; border:1px solid var(--border); border-radius:20px; background:#fff; color:var(--text-muted); font-family:inherit; font-size:11px; cursor:pointer; }
        .chart-range-btn.active { background:var(--maroon); color:#fff; border-color:var(--maroon); }
        .chart-container { height:285px; position:relative; }
        .chart-empty-note { position:absolute; top:46%; left:50%; width:230px; transform:translate(-50%,-50%); color:var(--text-muted); font-size:12px; line-height:1.6; text-align:center; pointer-events:none; }
        .text-link { color:var(--maroon); font-size:12px; font-weight:600; text-decoration:none; white-space:nowrap; }
        .text-link:hover, .clear-link:hover { text-decoration:underline; }
        .low-stock-search-form { display:flex; gap:7px; margin-bottom:14px; }
        .low-stock-search-form input { flex:1; min-width:0; padding:9px 10px; border:1px solid var(--border); border-radius:8px; background:#fffaf9; color:var(--text-dark); font-family:inherit; font-size:12px; }
        .low-stock-search-form input:focus { outline:none; border-color:var(--maroon); box-shadow:0 0 0 3px rgba(91,26,53,.08); }
        .low-stock-search-form button { padding:8px 11px; border:0; border-radius:8px; background:var(--maroon); color:#fff; font-family:inherit; font-size:12px; font-weight:600; cursor:pointer; }
        .clear-link { align-self:center; color:var(--coral); font-size:11px; text-decoration:none; }
        .table-wrap { overflow-x:auto; }
        .premium-table { width:100%; border-collapse:collapse; }
        .premium-table th, .premium-table td { padding:11px 7px; border-bottom:1px solid var(--border); text-align:left; font-size:12.5px; }
        .premium-table th { color:var(--text-muted); font-weight:600; }
        .premium-table td:last-child, .premium-table th:last-child { text-align:right; }
        .stock-badge { display:inline-block; min-width:28px; padding:3px 8px; border-radius:20px; background:#f8e3dc; color:var(--terra-2); font-size:11px; font-weight:700; text-align:center; }
        .empty-cell { padding:30px 8px !important; color:var(--text-muted); text-align:center !important; }
        .pagination-row { display:flex; align-items:center; justify-content:space-between; gap:10px; margin-top:14px; color:var(--text-muted); font-size:10px; }
        .pagination-links { display:flex; gap:4px; }
        .page-link { display:inline-flex; align-items:center; justify-content:center; min-width:25px; height:25px; border:1px solid var(--border); border-radius:6px; color:var(--maroon); background:#fff; font-size:11px; text-decoration:none; }
        .page-link.current, .page-link:hover { color:#fff; background:var(--maroon); border-color:var(--maroon); }
        .page-link.disabled { color:#b6aaae; background:#faf7f6; }
        .activity-panel { margin-top:20px; }
        .activity-empty { display:flex; align-items:center; justify-content:center; gap:14px; min-height:92px; color:var(--text-muted); }
        .activity-empty-icon { width:42px; height:42px; border-radius:12px; display:flex; align-items:center; justify-content:center; background:#fff3ee; color:var(--coral); font-size:22px; }
        .activity-empty strong, .activity-empty span { display:block; font-size:12px; }
        .activity-empty strong { color:var(--text-dark); margin-bottom:4px; }
        @media (max-width:1100px) { .premium-stats-grid { grid-template-columns:repeat(2, minmax(0, 1fr)); } }
        @media (max-width:900px) { .dashboard-content-grid { grid-template-columns:1fr; } }
        @media (max-width:600px) { .dashboard-intro { display:block; } .dashboard-date { display:inline-block; margin-top:12px; } .premium-stats-grid { grid-template-columns:1fr; } .panel-heading-row { display:block; } .range-buttons { margin-top:12px; } }
    </style>

    <script src="https://cdnjs.cloudflare.com/ajax/libs/Chart.js/4.4.0/chart.umd.min.js"></script>
    <script>
        const trendData = {
            7: { labels: @json($salesTrend7['labels']), values: @json($salesTrend7['values']) },
            30: { labels: @json($salesTrend30['labels']), values: @json($salesTrend30['values']) }
        };
        const ctx = document.getElementById('salesTrendChart').getContext('2d');
        const gradient = ctx.createLinearGradient(0, 0, 0, 260);
        gradient.addColorStop(0, 'rgba(217, 138, 94, .25)');
        gradient.addColorStop(1, 'rgba(217, 138, 94, 0)');
        const salesChart = new Chart(ctx, {
            type: 'line',
            data: { labels: trendData[7].labels, datasets: [{ data: trendData[7].values, borderColor:'#B85C3B', backgroundColor:gradient, borderWidth:2.2, tension:.35, fill:true, pointRadius:3, pointBackgroundColor:'#B85C3B' }] },
            options: { responsive:true, maintainAspectRatio:false, plugins:{ legend:{display:false}, tooltip:{ callbacks:{ label:item => 'PHP ' + item.parsed.y.toLocaleString(undefined,{minimumFractionDigits:2}) } } }, scales:{ y:{beginAtZero:true, ticks:{callback:value=>'PHP '+value.toLocaleString()}, grid:{color:'#F0E2DA'}}, x:{grid:{display:false}} } }
        });
        function setRange(days) {
            salesChart.data.labels = trendData[days].labels;
            salesChart.data.datasets[0].data = trendData[days].values;
            salesChart.update();
            document.getElementById('range7Btn').classList.toggle('active', days === 7);
            document.getElementById('range30Btn').classList.toggle('active', days === 30);
        }
    </script>
@endsection
