<x-admin-layout title="Commission">
    <div class="stats-grid">
        <div class="stat-card">
            <div class="stat-icon icon-sales">₱</div>
            <div class="stat-label">Total Platform-Wide Sales</div>
            <div class="stat-value">PHP {{ number_format($totalGrossSales, 2) }}</div>
        </div>
        <div class="stat-card">
            <div class="stat-icon" style="background:linear-gradient(135deg,#5B1A35,#45132A);">{{ $commissionRate * 100 }}%</div>
            <div class="stat-label">Total Commission Earned</div>
            <div class="stat-value">PHP {{ number_format($totalCommission, 2) }}</div>
        </div>
        <div class="stat-card">
            <div class="stat-icon icon-products">👤</div>
            <div class="stat-label">Sellers with Sales</div>
            <div class="stat-value">{{ $sellerSales->count() }}</div>
        </div>
    </div>

    <div class="panel">
        <h2>Generate Reports</h2>
        <p style="font-size:13.5px; color:var(--text-muted); margin-bottom:20px;">
            Choose a date range, then download the report you need as a PDF.
        </p>

        <form method="GET" id="reportForm">
            <div style="display:flex; gap:16px; align-items:flex-end; flex-wrap:wrap; margin-bottom:20px;">
                <div>
                    <label style="display:block; font-size:13px; font-weight:600; margin-bottom:6px;">Date Range</label>
                    <select name="range" id="rangeSelect" onchange="toggleCustom()" style="padding:9px 12px; border:1px solid var(--border); border-radius:8px; font-family:inherit; font-size:13.5px;">
                        <option value="7">Last 7 Days</option>
                        <option value="14" selected>Last 14 Days</option>
                        <option value="30">Last 30 Days</option>
                        <option value="custom">Custom Range</option>
                    </select>
                </div>

                <div id="customRangeFields" style="display:none; gap:12px;">
                    <div>
                        <label style="display:block; font-size:13px; font-weight:600; margin-bottom:6px;">Start Date</label>
                        <input type="date" name="start_date" id="start_date" style="padding:8px 12px; border:1px solid var(--border); border-radius:8px; font-family:inherit; font-size:13.5px;">
                    </div>
                    <div>
                        <label style="display:block; font-size:13px; font-weight:600; margin-bottom:6px;">End Date</label>
                        <input type="date" name="end_date" id="end_date" style="padding:8px 12px; border:1px solid var(--border); border-radius:8px; font-family:inherit; font-size:13.5px;">
                    </div>
                </div>
            </div>

            <div style="display:flex; gap:12px;">
                <button type="submit" formaction="{{ route('admin.reports.salesSummary') }}" class="btn btn-dark" style="padding:10px 18px; border:none;">
                    Download Sales Summary PDF
                </button>
                <button type="submit" formaction="{{ route('admin.reports.commission') }}" class="btn btn-dark" style="padding:10px 18px; border:none;">
                    Download Commission Report PDF
                </button>
            </div>
        </form>
    </div>

    <div class="panel">
        <h2>Commission by Seller</h2>
        <table>
            <thead>
                <tr>
                    <th>Seller</th>
                    <th>Gross Sales</th>
                    <th>Commission ({{ $commissionRate * 100 }}%)</th>
                    <th>Net Seller Earnings</th>
                </tr>
            </thead>
            <tbody>
                @forelse ($sellerSales as $s)
                    <tr>
                        <td>{{ $s->seller_name }}</td>
                        <td>PHP {{ number_format($s->gross_sales, 2) }}</td>
                        <td>PHP {{ number_format($s->commission, 2) }}</td>
                        <td>PHP {{ number_format($s->net_earnings, 2) }}</td>
                    </tr>
                @empty
                    <tr><td colspan="4" style="text-align:center;color:#999;padding:20px;">No paid sales yet.</td></tr>
                @endforelse
            </tbody>
        </table>
    </div>

    <script>
        function toggleCustom() {
            const isCustom = document.getElementById('rangeSelect').value === 'custom';
            const fields = document.getElementById('customRangeFields');
            fields.style.display = isCustom ? 'flex' : 'none';
            document.getElementById('start_date').required = isCustom;
            document.getElementById('end_date').required = isCustom;
        }
    </script>
</x-admin-layout>