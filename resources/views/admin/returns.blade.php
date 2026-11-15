<x-admin-layout title="Return / Refund Requests">
    <div class="panel">
        <div style="display:flex;justify-content:space-between;align-items:flex-start;flex-wrap:wrap;gap:12px;margin-bottom:14px;">
            <div>
                <h2>Customer Return / Refund & Dispute Arbitration</h2>
                <p style="color:var(--text-muted);margin:4px 0 0;font-size:.88rem">
                    Review return claims and escalated buyer disputes. Admin arbitration can approve refunds, dispatch Lumora Logistics pickup, or sustain/deny pending or disputed claims.
                </p>
            </div>
        </div>

        <div style="display:flex;flex-wrap:wrap;gap:8px;margin-bottom:16px;">
            @php
                $statusFilter = $status ?? 'all';
                $counts = $tabCounts ?? [];
                $adminTabs = [
                    'all' => 'All',
                    'disputed' => 'Disputes',
                    'pending' => 'Pending',
                    'approved' => 'Approved',
                    'denied' => 'Denied',
                ];
            @endphp
            @foreach ($adminTabs as $tabKey => $tabLabel)
                <a href="{{ route('admin.returns.index', $tabKey === 'all' ? [] : ['status' => $tabKey]) }}"
                   class="btn {{ $statusFilter === $tabKey ? 'btn-primary' : 'btn-outline' }}"
                   style="font-size:12px;padding:6px 12px;text-decoration:none;">
                    {{ $tabLabel }} ({{ number_format((int) ($counts[$tabKey] ?? 0)) }})
                </a>
            @endforeach
        </div>

        <div style="overflow-x:auto">
            <table>
                <thead>
                    <tr>
                        <th style="width:125px;">Submitted</th>
                        <th style="width:145px;">Order</th>
                        <th style="width:155px;">Buyer</th>
                        <th style="min-width:185px;">Items to Return</th>
                        <th style="min-width:210px;">Reason, Solution & Details</th>
                        <th style="width:110px;">Proof</th>
                        <th style="width:155px;">Status & Refund</th>
                        <th style="min-width:170px;">Courier & Pickup</th>
                        <th style="width:160px;text-align:right;">Arbitration</th>
                    </tr>
                </thead>
                <tbody>
                    @forelse ($requests as $returnRequest)
                        @php
                            $order = $returnRequest->order;
                            $deliveringCourier = $order->statusHistories?->whereNotNull('courier_name')->first()?->courier_name
                                ?: ($order->courier ?: 'Assigned Delivery Courier');
                        @endphp
                        <tr>
                            <td>
                                <div>{{ $returnRequest->created_at->format('M d, Y') }}</div>
                                <small style="color:var(--text-muted);">{{ $returnRequest->created_at->format('g:i A') }}</small>
                            </td>

                            <td>
                                <strong>#{{ $order->order_number }}</strong>
                                <br>
                                <small style="color:var(--text-muted);">Total: PHP {{ number_format((float) $order->total, 2) }}</small>
                            </td>

                            <td>
                                <div><strong>{{ $returnRequest->buyer->name ?? 'Buyer' }}</strong></div>
                                <small style="color:var(--text-muted);">{{ $returnRequest->buyer->email ?? '' }}</small>
                                @if (!empty($order->contact_number))
                                    <br><small style="color:var(--text-muted);">📞 {{ $order->contact_number }}</small>
                                @endif
                            </td>

                            <td>
                                <ul style="padding-left:14px;margin:0;font-size:12px;line-height:1.45;color:var(--text-dark);">
                                    @forelse ($order->items as $item)
                                        <li>
                                            <strong>{{ $item->quantity }}×</strong> {{ $item->product?->name ?? 'Product Item' }}
                                            <span style="color:var(--text-muted);">(PHP {{ number_format((float) $item->price, 2) }})</span>
                                        </li>
                                    @empty
                                        <li style="color:var(--text-muted);">No items recorded</li>
                                    @endforelse
                                </ul>
                            </td>

                            <td>
                                <div style="display:flex;flex-wrap:wrap;gap:5px;margin-bottom:4px;">
                                    <span class="muted-badge" style="background:#FFF0EB;color:#B85C3B;border:1px solid #FCD9CC;display:inline-block;padding:2px 8px;border-radius:6px;font-size:11.5px;font-weight:700;">
                                        {{ ucwords(str_replace('_', ' ', $returnRequest->reason)) }}
                                    </span>
                                    <span class="muted-badge" style="background:#F3E8FF;color:#6B21A8;border:1px solid #E9D5FF;display:inline-block;padding:2px 8px;border-radius:6px;font-size:11px;font-weight:700;">
                                        {{ ($returnRequest->preferred_solution ?? 'refund') === 'exchange' ? 'Exchange' : 'Refund' }}
                                    </span>
                                </div>
                                <div style="font-size:12px;color:var(--text-dark);line-height:1.4;">
                                    {{ $returnRequest->details ?: 'No additional notes from buyer.' }}
                                </div>
                                @if (($returnRequest->dispute_status ?? null) === 'under_arbitration')
                                    <div style="font-size:11px;color:#92400E;margin-top:4px;padding:4px 6px;background:#FEF3C7;border-left:2px solid #F59E0B;">
                                        <strong>Buyer Dispute:</strong> {{ $returnRequest->dispute_notes ?: 'Escalated for Admin arbitration.' }}
                                    </div>
                                @endif
                                @if ($returnRequest->admin_note)
                                    <div style="font-size:11px;color:var(--text-muted);margin-top:4px;padding:4px 6px;background:#F8F8F9;border-left:2px solid var(--text-muted);">
                                        <strong>Review note:</strong> {{ $returnRequest->admin_note }}
                                    </div>
                                @endif
                            </td>

                            <td>
                                @if ($returnRequest->evidence->count() > 0)
                                    @php
                                        $evidencePayload = $returnRequest->evidence->map(function ($ev) use ($returnRequest) {
                                            return [
                                                'id' => $ev->id,
                                                'mime_type' => $ev->mime_type,
                                                'url' => route('admin.returns.evidence', [$returnRequest, $ev->id]),
                                                'is_video' => !str_starts_with($ev->mime_type ?? '', 'image/'),
                                            ];
                                        })->values();
                                    @endphp
                                    <button type="button" 
                                        class="btn btn-outline" 
                                        style="font-size:11.5px;padding:5px 10px;font-weight:700;display:inline-flex;align-items:center;gap:5px;cursor:pointer;"
                                        onclick="openAdminEvidenceModal('{{ $order->order_number }}', '{{ addslashes(ucwords(str_replace('_', ' ', $returnRequest->reason))) }}', '{{ addslashes($returnRequest->details ?? '') }}', {{ json_encode($evidencePayload) }})">
                                        📷 View Proof ({{ $returnRequest->evidence->count() }})
                                    </button>
                                @else
                                    <small style="color:var(--text-muted);">None</small>
                                @endif
                            </td>

                            <td>
                                @if ($returnRequest->status === 'approved')
                                    <span class="match-badge" style="background:#ECFDF5;color:#065F46;border:1px solid #A7F3D0;display:inline-block;padding:3px 10px;border-radius:999px;font-weight:700;font-size:11.5px;">
                                        ✓ Approved
                                    </span>
                                @elseif ($returnRequest->status === 'denied')
                                    <span class="muted-badge" style="background:#FEF2F2;color:#DC2626;border:1px solid #FECACA;display:inline-block;padding:3px 10px;border-radius:999px;font-weight:700;font-size:11.5px;">
                                        ✕ Denied
                                    </span>
                                @else
                                    <span class="muted-badge" style="background:#FFFBEB;color:#D97706;border:1px solid #FDE68A;display:inline-block;padding:3px 10px;border-radius:999px;font-weight:700;font-size:11.5px;">
                                        ⏳ Pending Review
                                    </span>
                                @endif
                                @if (($returnRequest->dispute_status ?? null) === 'under_arbitration')
                                    <div style="margin-top:4px;">
                                        <span class="muted-badge" style="background:#FEF3C7;color:#92400E;border:1px solid #FCD34D;display:inline-block;padding:2px 8px;border-radius:999px;font-weight:700;font-size:10.5px;">
                                            ⚖ Dispute Escalated
                                        </span>
                                    </div>
                                @elseif (($returnRequest->dispute_status ?? null) === 'resolved_approved')
                                    <div style="margin-top:4px;font-size:10.5px;font-weight:700;color:#065F46;">Admin Overturned ✓</div>
                                @elseif (($returnRequest->dispute_status ?? null) === 'resolved_denied')
                                    <div style="margin-top:4px;font-size:10.5px;font-weight:700;color:#DC2626;">Admin Upheld Denial</div>
                                @endif
                                @if (($returnRequest->refund_status ?? null) === 'refunded' || $order->payment_status === 'refunded')
                                    <div style="margin-top:4px;font-size:11px;font-weight:700;color:#065F46;">
                                        Refunded PHP {{ number_format((float) ($returnRequest->refund_amount ?? $order->refund_amount ?? $order->total), 2) }}
                                    </div>
                                @endif
                            </td>

                            <td>
                                @if ($returnRequest->status === 'approved')
                                    <div style="font-size:12px;font-weight:700;color:var(--text-dark);">
                                        🛵 {{ $deliveringCourier }}
                                    </div>
                                    <div style="font-size:11px;color:#065F46;margin-top:2px;">
                                        Assigned to delivering courier
                                    </div>
                                @elseif ($returnRequest->status === 'denied')
                                    <div style="font-size:11.5px;color:var(--text-muted);">
                                        Claim denied
                                    </div>
                                @else
                                    <div style="font-size:12px;color:var(--text-muted);">
                                        Courier: <strong>{{ $deliveringCourier }}</strong>
                                    </div>
                                    <div style="font-size:11px;color:var(--text-muted);margin-top:2px;">
                                        Awaiting review decision
                                    </div>
                                @endif
                            </td>

                            <td style="text-align:right;">
                                @if ($returnRequest->status === 'pending' || ($returnRequest->dispute_status ?? null) === 'under_arbitration')
                                    <div style="display:flex;flex-direction:column;gap:6px;align-items:flex-end;">
                                        <form method="POST" action="{{ route('admin.returns.approve', $returnRequest) }}" onsubmit="return confirm('Approve & refund return for Order #{{ $order->order_number }} and dispatch Lumora Logistics?')">
                                            @csrf
                                            <button type="submit" class="btn btn-primary" style="font-size:11.5px;padding:5px 10px;">
                                                ✓ Approve & Refund
                                            </button>
                                        </form>
                                        <button type="button"
                                                class="btn btn-outline"
                                                style="font-size:11.5px;padding:5px 10px;color:#DC2626;border-color:#FECACA;"
                                                onclick='openAdminDenyModal("{{ route('admin.returns.deny', $returnRequest) }}", "{{ $order->order_number }}")'>
                                            ✕ Deny
                                        </button>
                                    </div>
                                @else
                                    <span style="font-size:11.5px;color:var(--text-muted);">Resolved</span>
                                @endif
                            </td>
                        </tr>
                    @empty
                        <tr>
                            <td colspan="9" style="text-align:center;color:var(--text-muted);padding:32px 20px;">
                                No return or refund requests found.
                            </td>
                        </tr>
                    @endforelse
                </tbody>
            </table>
        </div>

        <div style="margin-top:18px;">
            {{ $requests->links() }}
        </div>
    </div>

    <!-- Admin Deny Return / Dispute Modal -->
    <div id="adminDenyModalOverlay" style="display:none;position:fixed;inset:0;background:rgba(43,28,34,.55);backdrop-filter:blur(3px);align-items:center;justify-content:center;z-index:10000;padding:20px;">
        <div style="background:#fff;border-radius:14px;max-width:460px;width:100%;padding:22px;box-shadow:0 20px 50px rgba(0,0,0,.22);">
            <h3 style="margin:0 0 6px;font-size:17px;">Deny Return / Dispute Claim</h3>
            <p id="adminDenyModalSubtitle" style="margin:0 0 12px;font-size:13px;color:var(--text-muted);"></p>
            <form id="adminDenyModalForm" method="POST" action="">
                @csrf
                <label for="admin_note_input" style="display:block;font-size:12.5px;font-weight:700;margin-bottom:6px;">Admin Arbitration / Denial Reason</label>
                <textarea id="admin_note_input" name="admin_note" rows="4" required maxlength="1000" style="width:100%;border:1px solid #d1d5db;border-radius:8px;padding:10px;font-size:13px;" placeholder="Explain why this return claim or dispute is denied..."></textarea>
                <div style="display:flex;justify-content:flex-end;gap:8px;margin-top:14px;">
                    <button type="button" class="btn btn-outline" onclick="closeAdminDenyModal()">Cancel</button>
                    <button type="submit" class="btn btn-primary" style="background:#DC2626;border-color:#DC2626;">Confirm Deny</button>
                </div>
            </form>
        </div>
    </div>

    <!-- Admin Buyer Evidence Modal Lightbox -->
    <div id="adminEvidenceModalOverlay" style="display:none;position:fixed;inset:0;background:rgba(43,28,34,.65);backdrop-filter:blur(4px);align-items:center;justify-content:center;z-index:9999;padding:20px;" onclick="handleAdminEvidenceOverlayClick(event)">
        <div style="background:#fff;border-radius:18px;width:560px;max-width:100%;max-height:90vh;overflow-y:auto;box-shadow:0 16px 40px rgba(69,19,42,.25);border:1px solid var(--border);animation:adminModalFadeIn .2s ease;">
            <div style="padding:20px 24px;border-bottom:1px solid var(--border);display:flex;justify-content:space-between;align-items:center;">
                <div>
                    <h3 id="adminEvidenceModalTitle" style="font-size:17px;font-weight:800;color:var(--text-dark);margin:0;">Buyer Evidence</h3>
                    <small id="adminEvidenceModalSub" style="color:var(--text-muted);font-size:12px;">Attached photos and videos submitted by customer</small>
                </div>
                <button type="button" onclick="closeAdminEvidenceModal()" style="border:none;background:none;font-size:22px;line-height:1;cursor:pointer;color:var(--text-muted);padding:4px 8px;border-radius:8px;">&times;</button>
            </div>

            <div style="padding:20px 24px;">
                <div style="background:#FFF9F7;border:1px solid #FCD9CC;border-radius:12px;padding:14px;margin-bottom:18px;">
                    <div style="font-size:11px;font-weight:800;color:#B85C3B;text-transform:uppercase;letter-spacing:.5px;margin-bottom:4px;">Stated Return Reason</div>
                    <div id="adminEvidenceModalReason" style="font-size:13.5px;font-weight:700;color:var(--text-dark);margin-bottom:6px;">—</div>
                    <div style="font-size:11px;font-weight:800;color:var(--text-muted);text-transform:uppercase;letter-spacing:.5px;margin-bottom:4px;">Customer Explanation</div>
                    <div id="adminEvidenceModalDetails" style="font-size:12.5px;color:var(--text-dark);line-height:1.45;">—</div>
                </div>

                <div style="font-size:12.5px;font-weight:800;color:var(--text-dark);margin-bottom:10px;display:flex;align-items:center;gap:6px;">
                    <span>📷 Attached Evidence Files</span>
                </div>

                <div id="adminEvidenceGallery" style="display:grid;grid-template-columns:repeat(auto-fill, minmax(230px, 1fr));gap:14px;">
                    <!-- Dynamically populated -->
                </div>
            </div>

            <div style="padding:14px 24px;background:#FBF9F9;border-top:1px solid var(--border);display:flex;justify-content:flex-end;">
                <button type="button" class="btn btn-outline" onclick="closeAdminEvidenceModal()" style="font-weight:700;">Close</button>
            </div>
        </div>
    </div>

    <style>
        @keyframes adminModalFadeIn {
            from { opacity: 0; transform: scale(.96); }
            to { opacity: 1; transform: scale(1); }
        }
        .admin-proof-card {
            border: 1px solid var(--border);
            border-radius: 12px;
            overflow: hidden;
            background: #FAFAFA;
            box-shadow: 0 2px 8px rgba(0,0,0,0.04);
            display: flex;
            flex-direction: column;
        }
        .admin-proof-preview {
            width: 100%;
            height: 180px;
            background: #1A1A1A;
            display: flex;
            align-items: center;
            justify-content: center;
        }
        .admin-proof-preview img {
            width: 100%;
            height: 100%;
            object-fit: contain;
            display: block;
        }
        .admin-proof-preview video {
            width: 100%;
            height: 100%;
            max-height: 180px;
            display: block;
            background: #000;
        }
        .admin-proof-footer {
            padding: 8px 12px;
            display: flex;
            justify-content: space-between;
            align-items: center;
            background: #fff;
            border-top: 1px solid var(--border);
            font-size: 11.5px;
        }
    </style>

    <script>
        function openAdminEvidenceModal(orderNum, reason, details, evidenceList) {
            document.getElementById('adminEvidenceModalTitle').textContent = 'Evidence · Order #' + orderNum;
            document.getElementById('adminEvidenceModalReason').textContent = reason;
            document.getElementById('adminEvidenceModalDetails').textContent = details || 'No additional notes provided by buyer.';

            const gallery = document.getElementById('adminEvidenceGallery');
            gallery.innerHTML = '';

            if (!evidenceList || evidenceList.length === 0) {
                gallery.innerHTML = '<div style="color:var(--text-muted);font-size:13px;padding:12px 0;">No proof files attached to this request.</div>';
            } else {
                evidenceList.forEach((ev, idx) => {
                    const card = document.createElement('div');
                    card.className = 'admin-proof-card';

                    const preview = document.createElement('div');
                    preview.className = 'admin-proof-preview';

                    if (ev.is_video) {
                        const video = document.createElement('video');
                        video.src = ev.url;
                        video.controls = true;
                        video.preload = 'metadata';
                        preview.appendChild(video);
                    } else {
                        const imgLink = document.createElement('a');
                        imgLink.href = ev.url;
                        imgLink.target = '_blank';
                        imgLink.rel = 'noopener';
                        imgLink.style.display = 'block';
                        imgLink.style.width = '100%';
                        imgLink.style.height = '100%';

                        const img = document.createElement('img');
                        img.src = ev.url;
                        img.alt = 'Buyer proof ' + (idx + 1);
                        imgLink.appendChild(img);
                        preview.appendChild(imgLink);
                    }

                    const footer = document.createElement('div');
                    footer.className = 'admin-proof-footer';
                    footer.innerHTML = `
                        <span style="font-weight:700;color:var(--text-dark);">${ev.is_video ? '🎥 Video Evidence' : '📷 Photo Evidence'}</span>
                        <a href="${ev.url}" target="_blank" rel="noopener" style="color:var(--maroon);font-weight:700;text-decoration:none;">Open Full ↗</a>
                    `;

                    card.appendChild(preview);
                    card.appendChild(footer);
                    gallery.appendChild(card);
                });
            }

            document.getElementById('adminEvidenceModalOverlay').style.display = 'flex';
        }

        function closeAdminEvidenceModal() {
            const overlay = document.getElementById('adminEvidenceModalOverlay');
            if (overlay) {
                overlay.style.display = 'none';
                // Pause any videos playing
                const videos = overlay.querySelectorAll('video');
                videos.forEach(v => v.pause());
            }
        }

        function handleAdminEvidenceOverlayClick(e) {
            if (e.target.id === 'adminEvidenceModalOverlay') {
                closeAdminEvidenceModal();
            }
        }

        function openAdminDenyModal(actionUrl, orderNumber) {
            const form = document.getElementById('adminDenyModalForm');
            const sub = document.getElementById('adminDenyModalSubtitle');
            const input = document.getElementById('admin_note_input');
            if (form) form.action = actionUrl;
            if (sub) sub.textContent = 'Order #' + orderNumber + ' · Provide an arbitration reason to sustain or deny this claim.';
            if (input) input.value = '';
            document.getElementById('adminDenyModalOverlay').style.display = 'flex';
        }

        function closeAdminDenyModal() {
            const overlay = document.getElementById('adminDenyModalOverlay');
            if (overlay) overlay.style.display = 'none';
        }

        document.addEventListener('keydown', function (e) {
            if (e.key === 'Escape') {
                closeAdminEvidenceModal();
                closeAdminDenyModal();
            }
        });
    </script>
</x-admin-layout>
