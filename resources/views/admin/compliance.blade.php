<x-admin-layout title="Compliance">
    <div class="panel">
        <h2>Seller Compliance</h2>
        <table>
            <thead>
                <tr>
                    <th>Product</th>
                    <th>Seller</th>
                    <th>Product Category</th>
                    <th>Registered Category</th>
                    <th>Status</th>
                    <th>Warnings</th>
                    <th>Actions</th>
                </tr>
            </thead>
            <tbody>
                @forelse ($products as $p)
                    @php
                        $hasRegisteredCategory = !is_null($p->registered_category);
                        $isMismatch = $hasRegisteredCategory && $p->product_category !== $p->registered_category;
                        $sellerWarnings = $warningsBySeller->get($p->seller_id, collect());
                    @endphp
                    <tr>
                        <td>{{ $p->product_name }}</td>
                        <td>{{ $p->seller_name }}</td>
                        <td>{{ $p->product_category ?? '—' }}</td>
                        <td>
                            @if ($hasRegisteredCategory)
                                {{ $p->registered_category }}
                                @if ($isMismatch)
                                    <span class="mismatch-badge">Mismatch</span>
                                @else
                                    <span class="match-badge">Match</span>
                                @endif
                            @else
                                <span class="muted-badge">No category on file</span>
                            @endif
                        </td>
                        <td>
                            <span class="badge" style="background:{{ match($p->product_status) { 'active' => '#5C7355', 'flagged' => '#B85C3B', default => '#8B7A80' } }}">
                                {{ ucfirst($p->product_status) }}
                            </span>
                        </td>
                        <td>
                            <button type="button" class="btn-link" onclick="openHistoryModal({{ $p->seller_id }})">
                                {{ $sellerWarnings->count() }} {{ Str::plural('warning', $sellerWarnings->count()) }}
                            </button>

                            <div id="history-data-{{ $p->seller_id }}" style="display:none;">
                                @forelse ($sellerWarnings as $w)
                                    <div style="padding:8px 0;border-bottom:1px solid var(--border);">
                                        <div style="font-size:.78rem;color:var(--text-muted);">{{ \Carbon\Carbon::parse($w->created_at)->format('M d, Y g:i A') }}</div>
                                        <div>{{ $w->reason }}</div>
                                    </div>
                                @empty
                                    <p style="color:var(--text-muted);">No warnings logged for this seller yet.</p>
                                @endforelse
                            </div>
                        </td>
                        <td>
                            @if ($p->product_status !== 'flagged')
                                <a href="{{ route('admin.compliance.flag', $p->product_id) }}"
                                   class="btn btn-danger"
                                   onclick="return confirm('Flag this product as prohibited? It will be hidden from the storefront.')">Flag</a>
                            @else
                                <a href="{{ route('admin.compliance.clear', $p->product_id) }}"
                                   class="btn btn-outline"
                                   onclick="return confirm('Clear this flag and set the product back to active?')">Clear</a>
                            @endif

                            <button type="button" class="btn btn-outline" onclick="openWarnModal({{ $p->seller_id }}, {{ $p->product_id }}, '{{ addslashes($p->seller_name) }}')">Warn Seller</button>

                            @if ($p->seller_status !== 'suspended')
                                <a href="{{ route('admin.users.action', [$p->seller_id, 'suspend']) }}"
                                   class="btn btn-danger"
                                   onclick="return confirm('Suspend this seller\'s account?')">Suspend</a>
                            @endif
                        </td>
                    </tr>
                @empty
                    <tr><td colspan="7" style="text-align:center;color:#999;padding:20px;">No products found.</td></tr>
                @endforelse
            </tbody>
        </table>
    </div>

    <!-- Warn Seller Modal -->
    <div id="warn-modal-overlay" style="display:none;position:fixed;inset:0;background:rgba(0,0,0,.5);z-index:999;">
        <div style="background:#fff;max-width:440px;margin:80px auto;padding:24px;border-radius:8px;position:relative;">
            <button type="button" onclick="closeWarnModal()" style="position:absolute;top:12px;right:16px;background:none;border:none;font-size:20px;cursor:pointer;">&times;</button>
            <h3 style="margin-top:0;">Warn <span id="warn-seller-name"></span></h3>
            <form method="POST" id="warn-form">
                @csrf
                <input type="hidden" name="product_id" id="warn-product-id">
                <textarea name="reason" required placeholder="Explain the compliance issue (e.g. product doesn't match registered category, prohibited item, etc.)" style="width:100%;height:100px;padding:10px;border:1px solid var(--border);border-radius:8px;font-family:inherit;margin-top:12px;"></textarea>
                <div style="display:flex;gap:10px;margin-top:14px;">
                    <button type="button" onclick="closeWarnModal()" style="flex:1;padding:10px;border-radius:8px;border:1px solid var(--border);background:transparent;font-family:inherit;">Cancel</button>
                    <button type="submit" class="btn btn-dark" style="flex:1;padding:10px;border:none;">Send Warning</button>
                </div>
            </form>
        </div>
    </div>

    <!-- Warning History Modal -->
    <div id="history-modal-overlay" style="display:none;position:fixed;inset:0;background:rgba(0,0,0,.5);z-index:999;">
        <div style="background:#fff;max-width:480px;margin:80px auto;padding:24px;border-radius:8px;position:relative;max-height:70vh;overflow-y:auto;">
            <button type="button" onclick="closeHistoryModal()" style="position:absolute;top:12px;right:16px;background:none;border:none;font-size:20px;cursor:pointer;">&times;</button>
            <h3 style="margin-top:0;">Warning History</h3>
            <div id="history-modal-content"></div>
        </div>
    </div>

    <style>
        .btn-link {
            background: none;
            border: none;
            padding: 4px 6px;
            cursor: pointer;
            font-size: 13px;
            text-decoration: underline;
            color: #5B1A35;
        }
    </style>

    <script>
        function openWarnModal(sellerId, productId, sellerName) {
            document.getElementById('warn-seller-name').textContent = sellerName;
            document.getElementById('warn-product-id').value = productId;
            document.getElementById('warn-form').action = '/admin/compliance/seller/' + sellerId + '/warn';
            document.getElementById('warn-modal-overlay').style.display = 'block';
        }
        function closeWarnModal() {
            document.getElementById('warn-modal-overlay').style.display = 'none';
        }
        function openHistoryModal(sellerId) {
            const src = document.getElementById('history-data-' + sellerId);
            document.getElementById('history-modal-content').innerHTML = src.innerHTML;
            document.getElementById('history-modal-overlay').style.display = 'block';
        }
        function closeHistoryModal() {
            document.getElementById('history-modal-overlay').style.display = 'none';
        }
    </script>
</x-admin-layout>