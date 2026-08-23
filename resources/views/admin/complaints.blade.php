<x-admin-layout title="Complaints">
    <div class="panel">
        <h2>Complaints &amp; Disputes</h2>
        <table>
            <thead>
                <tr>
                    <th>Filed</th>
                    <th>Product</th>
                    <th>Buyer</th>
                    <th>Seller</th>
                    <th>Category</th>
                    <th>Status</th>
                    <th>Actions</th>
                </tr>
            </thead>
            <tbody>
                @forelse ($complaints as $c)
                    @php $evidence = $evidenceByComplaint->get($c->id, collect()); @endphp
                    <tr>
                        <td>{{ \Carbon\Carbon::parse($c->created_at)->format('M d, Y') }}</td>
                        <td>{{ $c->product_name }}</td>
                        <td>{{ $c->buyer_name }}</td>
                        <td>{{ $c->seller_name }}</td>
                        <td>{{ ucwords(str_replace('_', ' ', $c->category)) }}</td>
                        <td>
                            <span class="badge" style="background:{{ match($c->status) { 'pending' => '#D9A94E', 'under_review' => '#D98A5E', 'resolved' => '#5C7355', 'dismissed' => '#8B7A80', default => '#8B7A80' } }}">
                                {{ ucfirst(str_replace('_', ' ', $c->status)) }}
                            </span>
                        </td>
                        <td>
                            <button type="button" class="btn-link" onclick="openDetailModal({{ $c->id }})">View</button>

                            <div id="detail-data-{{ $c->id }}" style="display:none;">
                                <p><strong>Product:</strong> {{ $c->product_name }}</p>
                                <p><strong>Buyer:</strong> {{ $c->buyer_name }} ({{ $c->buyer_email }})</p>
                                <p><strong>Seller:</strong> {{ $c->seller_name }} ({{ $c->seller_email }})</p>
                                <p><strong>Category:</strong> {{ ucwords(str_replace('_', ' ', $c->category)) }}</p>
                                <p><strong>Description:</strong><br>{{ $c->description }}</p>
                                <p><strong>Evidence:</strong></p>
                                <div style="display:flex;gap:8px;flex-wrap:wrap;margin-bottom:10px;">
                                    @forelse ($evidence as $img)
                                        <a href="{{ asset('storage/' . $img->image_path) }}" target="_blank">
                                            <img src="{{ asset('storage/' . $img->image_path) }}" style="width:80px;height:80px;object-fit:cover;border-radius:8px;border:1px solid var(--border);">
                                        </a>
                                    @empty
                                        <p style="color:var(--text-muted);">No evidence images submitted.</p>
                                    @endforelse
                                </div>
                                @if ($c->admin_note)
                                    <p><strong>Admin note:</strong><br>{{ $c->admin_note }}</p>
                                @endif
                            </div>

                            @if (!in_array($c->status, ['resolved', 'dismissed']))
                                <button type="button" class="btn btn-dark" onclick="openResolveModal({{ $c->id }}, 'resolve')">Resolve</button>
                                <button type="button" class="btn btn-outline" onclick="openResolveModal({{ $c->id }}, 'dismiss')">Dismiss</button>
                            @endif
                        </td>
                    </tr>
                @empty
                    <tr><td colspan="7" style="text-align:center;color:#999;padding:20px;">No complaints filed yet.</td></tr>
                @endforelse
            </tbody>
        </table>
    </div>

    <!-- Complaint Detail Modal -->
    <div id="detail-modal-overlay" style="display:none;position:fixed;inset:0;background:rgba(0,0,0,.5);z-index:999;">
        <div style="background:#fff;max-width:520px;margin:60px auto;padding:24px;border-radius:8px;position:relative;max-height:75vh;overflow-y:auto;">
            <button type="button" onclick="closeDetailModal()" style="position:absolute;top:12px;right:16px;background:none;border:none;font-size:20px;cursor:pointer;">&times;</button>
            <h3 style="margin-top:0;">Complaint Details</h3>
            <div id="detail-modal-content"></div>
        </div>
    </div>

    <!-- Resolve/Dismiss Modal -->
    <div id="resolve-modal-overlay" style="display:none;position:fixed;inset:0;background:rgba(0,0,0,.5);z-index:999;">
        <div style="background:#fff;max-width:440px;margin:80px auto;padding:24px;border-radius:8px;position:relative;">
            <button type="button" onclick="closeResolveModal()" style="position:absolute;top:12px;right:16px;background:none;border:none;font-size:20px;cursor:pointer;">&times;</button>
            <h3 style="margin-top:0;" id="resolve-modal-title">Resolve Complaint</h3>
            <form method="POST" id="resolve-form">
                @csrf
                <textarea name="admin_note" required placeholder="Note on how this was handled (e.g. coordinated with seller for replacement, refund issued, etc.)" style="width:100%;height:100px;padding:10px;border:1px solid var(--border);border-radius:8px;font-family:inherit;margin-top:12px;"></textarea>
                <div style="display:flex;gap:10px;margin-top:14px;">
                    <button type="button" onclick="closeResolveModal()" style="flex:1;padding:10px;border-radius:8px;border:1px solid var(--border);background:transparent;font-family:inherit;">Cancel</button>
                    <button type="submit" class="btn btn-dark" style="flex:1;padding:10px;border:none;" id="resolve-submit-btn">Confirm</button>
                </div>
            </form>
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
        function openDetailModal(id) {
            const src = document.getElementById('detail-data-' + id);
            document.getElementById('detail-modal-content').innerHTML = src.innerHTML;
            document.getElementById('detail-modal-overlay').style.display = 'block';
        }
        function closeDetailModal() {
            document.getElementById('detail-modal-overlay').style.display = 'none';
        }
        function openResolveModal(id, action) {
            const title = action === 'resolve' ? 'Resolve Complaint' : 'Dismiss Complaint';
            document.getElementById('resolve-modal-title').textContent = title;
            document.getElementById('resolve-submit-btn').textContent = action === 'resolve' ? 'Mark Resolved' : 'Dismiss';
            document.getElementById('resolve-form').action = '/admin/complaints/' + id + '/' + action;
            document.getElementById('resolve-modal-overlay').style.display = 'block';
        }
        function closeResolveModal() {
            document.getElementById('resolve-modal-overlay').style.display = 'none';
        }
    </script>
</x-admin-layout>