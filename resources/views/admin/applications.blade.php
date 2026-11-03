<x-admin-layout title="Seller Applications">
    <style>
        .seller-apps { --sa-ink:#2B1C22; --sa-muted:#66565C; --sa-maroon:#5B1A35; --sa-green:#1E6B4A; --sa-red:#9B2315; color:var(--sa-ink); }
        .sa-heading { margin:-8px 0 22px; color:var(--sa-muted); font-size:.9rem; }
        .sa-stats { display:grid; grid-template-columns:repeat(4,minmax(0,1fr)); gap:14px; margin-bottom:20px; }
        .sa-stat,.sa-card { background:#fff; border:1px solid var(--border); border-radius:24px; box-shadow:0 4px 18px rgba(91,26,53,.04); }
        .sa-stat { min-height:112px; padding:19px 21px; }
        .sa-stat-label { color:var(--sa-muted); font-size:.84rem; font-weight:600; }
        .sa-stat-value { display:block; margin:5px 0 2px; font-size:1.75rem; line-height:1.2; font-weight:800; }
        .sa-stat-note { color:var(--sa-muted); font-size:.77rem; }
        .sa-stat.pending { border-color:#F1D08D; }
        .sa-stat.pending .sa-stat-value,.sa-stat.pending .sa-stat-label { color:#8B4E00; }
        .sa-tabs { display:flex; gap:8px; padding:0 18px; border-bottom:1px solid var(--border); overflow-x:auto; }
        .sa-tab { min-height:54px; display:flex; align-items:center; gap:9px; padding:0 12px; border-bottom:3px solid transparent; color:var(--sa-muted); font-weight:700; text-decoration:none; white-space:nowrap; }
        .sa-tab.active { color:var(--sa-maroon); border-color:var(--sa-maroon); }
        .sa-tab-count { min-width:27px; padding:3px 8px; border-radius:999px; background:#F5E8ED; color:var(--sa-maroon); text-align:center; font-size:.72rem; }
        .sa-layout { display:grid; grid-template-columns:minmax(0,1fr) minmax(325px,390px); gap:18px; align-items:start; }
        .sa-card { min-width:0; overflow:hidden; }
        .sa-toolbar { display:grid; grid-template-columns:minmax(230px,1.5fr) minmax(140px,.8fr) minmax(145px,.9fr) auto; gap:10px; padding:18px 20px; border-bottom:1px solid var(--border); }
        .sa-input { min-height:46px; width:100%; padding:9px 12px; border:1px solid #DDCCC6; border-radius:12px; background:#fff; color:var(--sa-ink); font:500 .84rem Poppins,sans-serif; }
        .sa-input:focus,.sa-button:focus-visible,.sa-tab:focus-visible,.sa-table a:focus-visible,.sa-table button:focus-visible { outline:3px solid #9B6A80; outline-offset:2px; }
        .sa-search-wrap { position:relative; }
        .sa-search-wrap input { padding-left:40px; }
        .sa-search-icon { position:absolute; left:13px; top:14px; color:var(--sa-muted); pointer-events:none; }
        .sa-table-wrap { overflow-x:auto; width:100%; }
        .sa-table { width:100%; min-width:890px; border-collapse:collapse; }
        .sa-table th { padding:13px 14px; background:#FBF7F5; color:#59474D; font-size:.72rem; letter-spacing:.04em; text-align:left; text-transform:uppercase; white-space:nowrap; }
        .sa-table td { padding:13px 14px; border-bottom:1px solid var(--border); vertical-align:middle; font-size:.82rem; }
        .sa-table tbody tr:last-child td { border-bottom:0; }
        .sa-table tr[data-application-row] { cursor:pointer; }
        .sa-table tr[data-application-row]:hover td,.sa-table tr.selected td { background:#FCF0F3; }
        .sa-applicant { display:flex; align-items:center; gap:10px; min-width:210px; }
        .sa-avatar { width:46px; height:46px; flex:0 0 46px; display:grid; place-items:center; border-radius:50%; background:#E8DDC0; color:#392930; font-weight:800; font-size:1rem; }
        .sa-applicant-name { display:block; color:var(--sa-ink); font-weight:750; }
        .sa-sub { display:block; margin-top:3px; color:var(--sa-muted); font-size:.75rem; }
        .sa-status,.sa-history-chip { display:inline-flex; align-items:center; min-height:26px; padding:3px 10px; border-radius:999px; font-size:.72rem; font-weight:700; white-space:nowrap; }
        .sa-status.pending { background:#FFF1D2; color:#804900; }
        .sa-status.approved { background:#E2F2E9; color:#15553A; }
        .sa-status.rejected { background:#FCE8E5; color:#8A2117; }
        .sa-status.archived { background:#F0EAEC; color:#59474D; }
        .sa-history-chip { margin-top:4px; background:#FFF1D2; color:#804900; }
        .sa-applied { white-space:nowrap; }
        .sa-actions { display:flex; align-items:center; justify-content:flex-end; gap:6px; white-space:nowrap; }
        .sa-button { min-height:44px; display:inline-flex; align-items:center; justify-content:center; gap:7px; padding:8px 13px; border:1px solid #E8D4CE; border-radius:12px; background:#fff; color:var(--sa-ink); font:700 .8rem Poppins,sans-serif; text-decoration:none; cursor:pointer; }
        .sa-button:hover { background:#FCF7F5; }
        .sa-button.primary { border-color:var(--sa-maroon); background:var(--sa-maroon); color:#fff; }
        .sa-button.approve { border-color:var(--sa-green); background:var(--sa-green); color:#fff; }
        .sa-button.reject { border-color:#D88E85; background:#fff; color:var(--sa-red); }
        .sa-button.icon { width:44px; padding:0; }
        .sa-button.icon.approve { border:0; }
        .sa-button.icon svg { width:18px; height:18px; }
        .sa-empty { padding:36px 18px; color:var(--sa-muted); text-align:center; }
        .sa-pagination { display:flex; align-items:center; flex-wrap:wrap; gap:7px; padding:14px 18px; }
        .sa-pagination-info { margin-right:auto; color:var(--sa-muted); font-size:.78rem; }
        .sa-page-link { min-width:44px; min-height:44px; display:grid; place-items:center; padding:0 10px; border:1px solid var(--border); border-radius:11px; background:#fff; color:var(--sa-maroon); text-decoration:none; font-size:.8rem; font-weight:700; }
        .sa-page-link.current { border-color:var(--sa-maroon); background:var(--sa-maroon); color:#fff; }
        .sa-page-link[aria-disabled="true"] { color:#766B6E; background:#F8F4F2; pointer-events:none; }
        .sa-panel { position:sticky; top:18px; max-height:calc(100vh - 36px); overflow:auto; padding:22px; }
        .sa-panel[hidden] { display:none; }
        .sa-panel-top { display:flex; justify-content:space-between; align-items:flex-start; gap:12px; }
        .sa-eyebrow { color:var(--sa-muted); font-size:.7rem; font-weight:750; letter-spacing:.06em; text-transform:uppercase; }
        .sa-panel h2 { margin:4px 0 2px; color:var(--sa-ink); font-size:1.24rem; line-height:1.35; overflow-wrap:anywhere; }
        .sa-panel-date { color:var(--sa-muted); font-size:.8rem; }
        .sa-detail-box { display:grid; gap:10px; margin:18px 0; padding:16px; border-radius:16px; background:#FBF7F5; }
        .sa-detail-row { display:flex; justify-content:space-between; gap:14px; color:var(--sa-muted); font-size:.8rem; }
        .sa-detail-row strong { max-width:65%; color:var(--sa-ink); text-align:right; overflow-wrap:anywhere; }
        .sa-panel-section { margin-top:18px; }
        .sa-panel-section h3 { margin-bottom:8px; font-size:.88rem; font-weight:800; }
        .sa-shop-description { white-space:pre-wrap; color:#493A3F; font-size:.84rem; line-height:1.6; }
        .sa-documents { display:grid; gap:8px; }
        .sa-document { min-height:58px; display:flex; align-items:center; justify-content:space-between; gap:12px; padding:8px 10px 8px 14px; border:1px solid #E8D4CE; border-radius:13px; font-size:.8rem; }
        .sa-checks { display:grid; gap:9px; list-style:none; margin:0; padding:0; }
        .sa-checks li { display:flex; align-items:flex-start; gap:9px; color:var(--sa-ink); font-size:.78rem; line-height:1.5; }
        .sa-check-mark.pass { color:var(--sa-green); font-weight:800; }
        .sa-check-mark.warn { color:#8B4E00; font-weight:800; }
        .sa-panel label { display:block; margin:13px 0 5px; color:var(--sa-ink); font-size:.78rem; font-weight:700; }
        .sa-note { min-height:82px; resize:vertical; }
        .sa-panel-actions { display:grid; grid-template-columns:1fr 1fr; gap:9px; margin-top:14px; }
        .sa-reject-fields { margin-top:12px; }
        .sa-reject-fields .sa-input { margin-bottom:0; }
        .sa-panel-actions form { min-width:0; }
        .sa-panel-actions .sa-button { width:100%; }
        .sa-flash { margin-bottom:14px; }
        .sa-error { margin:10px 20px 0; color:var(--sa-red); font-size:.78rem; }
        @media (max-width:1200px) { .sa-layout { grid-template-columns:minmax(0,1fr) 340px; } .sa-toolbar { grid-template-columns:1fr 1fr; } }
        @media (max-width:900px) { .sa-stats { grid-template-columns:repeat(2,minmax(0,1fr)); } .sa-layout { grid-template-columns:1fr; } .sa-panel { position:static; max-height:none; } }
        @media (max-width:600px) { .sa-stats { gap:8px; } .sa-stat { min-height:100px; padding:15px; } .sa-stat-value { font-size:1.45rem; } .sa-toolbar { grid-template-columns:1fr; padding:14px; } .sa-pagination-info { flex-basis:100%; } .sa-panel { padding:17px; } }
    </style>

    <div class="seller-apps">
        <p class="sa-heading">Review who wants to sell on the marketplace and approve or reject their applications.</p>

        <section class="sa-stats" aria-label="Seller application statistics">
            <article class="sa-stat pending"><div class="sa-stat-label">Pending review</div><strong class="sa-stat-value">{{ number_format($pendingCount) }}</strong><span class="sa-stat-note">{{ $oldestWaiting ? 'Oldest waiting '.$oldestWaiting : 'No applications waiting' }}</span></article>
            <article class="sa-stat"><div class="sa-stat-label">Approved sellers</div><strong class="sa-stat-value">{{ number_format($approvedSellerCount) }}</strong><span class="sa-stat-note">{{ number_format($approvedThisWeek) }} this week</span></article>
            <article class="sa-stat"><div class="sa-stat-label">Rejected</div><strong class="sa-stat-value">{{ number_format($rejectedLast30Days) }}</strong><span class="sa-stat-note">Last 30 days</span></article>
            <article class="sa-stat"><div class="sa-stat-label">Approval rate</div><strong class="sa-stat-value">{{ $approvalRate }}%</strong><span class="sa-stat-note">Last 30 days</span></article>
        </section>

        @if (session('flash_success'))<div class="success-box sa-flash" role="status">{{ session('flash_success') }}</div>@endif
        @if ($errors->any())<div class="approval-retry" role="alert">{{ $errors->first() }} <a class="sa-button primary" href="{{ route('admin.applications', request()->query()) }}">Try again</a></div>@endif

        <div class="sa-layout">
            <section class="sa-card" aria-label="Seller applications">
                <nav class="sa-tabs" aria-label="Application status">
                    @foreach (['all' => 'All', 'pending' => 'Pending', 'approved' => 'Approved', 'rejected' => 'Rejected'] as $tab => $label)
                        <a class="sa-tab {{ $status === $tab ? 'active' : '' }}" href="{{ route('admin.applications', array_merge(request()->except('page'), ['status' => $tab])) }}" @if ($status === $tab) aria-current="page" @endif>
                            {{ $label }} <span class="sa-tab-count">{{ number_format((int) $tabCounts[$tab]) }}</span>
                        </a>
                    @endforeach
                </nav>

                <form method="GET" action="{{ route('admin.applications') }}" class="sa-toolbar" id="sellerApplicationFilters">
                    <input type="hidden" name="status" value="{{ $status }}">
                    <label class="sr-only" for="sellerApplicationSearch">Search store, owner or email</label>
                    <div class="sa-search-wrap"><svg class="sa-search-icon" width="18" height="18" viewBox="0 0 24 24" fill="none" aria-hidden="true"><circle cx="11" cy="11" r="7" stroke="currentColor" stroke-width="2"/><path d="m16 16 4 4" stroke="currentColor" stroke-width="2" stroke-linecap="round"/></svg><input class="sa-input" id="sellerApplicationSearch" name="q" type="search" value="{{ $filters['q'] }}" maxlength="120" placeholder="Search store, owner or email"></div>
                    <label class="sr-only" for="sellerApplicationPeriod">Filter by application date</label>
                    <select class="sa-input" id="sellerApplicationPeriod" name="period"><option value="any" @selected($filters['period'] === 'any')>Any time</option><option value="today" @selected($filters['period'] === 'today')>Today</option><option value="7" @selected($filters['period'] === '7')>Last 7 days</option><option value="30" @selected($filters['period'] === '30')>Last 30 days</option></select>
                    <label class="sr-only" for="sellerApplicationSort">Sort applications</label>
                    <select class="sa-input" id="sellerApplicationSort" name="sort"><option value="oldest" @selected($filters['sort'] === 'oldest')>Oldest first</option><option value="newest" @selected($filters['sort'] === 'newest')>Newest first</option></select>
                    <noscript><button type="submit" class="sa-button primary">Apply</button></noscript>
                </form>

                @if ($applications->isEmpty())
                    <div class="sa-empty">No {{ $status === 'all' ? '' : $status.' ' }}applications match these filters.</div>
                @else
                    <div class="sa-table-wrap">
                        <table class="sa-table">
                            <thead><tr><th scope="col">Applicant</th><th scope="col">Email</th><th scope="col">Status</th><th scope="col">Applied</th><th scope="col" style="text-align:right">Actions</th></tr></thead>
                            <tbody>
                            @foreach ($applications as $application)
                                @php
                                    $emailVerified = (bool) $application->email_is_verified;
                                    $historyCount = (int) ($application->application_count ?? 1);
                                    $date = \Carbon\Carbon::parse($application->created_at);
                                    $appliedAgo = $date->diffForHumans();
                                    $docIdUrl = route('admin.applications.documents', [$application->id, 'id_document']);
                                    $permitUrl = route('admin.applications.documents', [$application->id, 'business_permit']);
                                @endphp
                                <tr data-application-row tabindex="0" data-id="{{ $application->id }}">
                                    <td><div class="sa-applicant"><span class="sa-avatar" aria-hidden="true">{{ \Illuminate\Support\Str::upper(mb_substr($application->business_name ?: $application->owner_name, 0, 1)) }}</span><span><span class="sa-applicant-name">{{ $application->business_name ?: 'Store name not provided' }}</span><span class="sa-sub">{{ $application->owner_name }}</span>@if ($historyCount > 1)<span class="sa-history-chip">{{ $historyCount - 1 }} earlier {{ \Illuminate\Support\Str::plural('application', $historyCount - 1) }}</span>@endif</span></div></td>
                                    <td>{{ $application->email }}</td>
                                    <td><span class="sa-status {{ in_array($application->status, ['pending','approved','rejected'], true) ? $application->status : 'archived' }}">{{ ucfirst($application->status) }}</span></td>
                                    <td class="sa-applied">{{ $date->format('M j, Y') }}<span class="sa-sub">{{ $appliedAgo }}</span></td>
                                    <td><div class="sa-actions">
                                        <button class="sa-button" type="button" data-view-application data-store="{{ $application->business_name ?? '' }}" data-owner="{{ $application->owner_name }}" data-email="{{ $application->email }}" data-phone="{{ $application->contact_number ?? 'Not provided' }}" data-category="{{ $application->category ?? '' }}" data-description="{{ $application->shop_description ?: ($application->reason ?? '') }}" data-applied="{{ $date->format('M j, Y · g:i A') }} · {{ $appliedAgo }}" data-status="{{ $application->status }}" data-email-verified="{{ $emailVerified ? '1' : '0' }}" data-application-count="{{ $historyCount }}" data-approved-count="{{ (int) ($application->approved_application_count ?? 0) }}" data-rejected-count="{{ (int) ($application->rejected_application_count ?? 0) }}" data-id-document="{{ $docIdUrl }}" data-permit-document="{{ $permitUrl }}" data-id-available="{{ $application->has_id_document ? '1' : '0' }}" data-permit-available="{{ $application->has_business_permit ? '1' : '0' }}" data-rejection-reason="{{ $application->rejection_reason ?? '' }}" data-admin-note="{{ $application->admin_note ?? '' }}">{{ $application->status === 'pending' ? 'Review' : 'View' }}</button>
                                        @if ($application->status === 'pending')
                                            <form method="POST" action="{{ route('admin.applications.approve', $application->id) }}" onsubmit="return confirm('Approve this seller and activate their seller access?')">@csrf<button class="sa-button icon approve" type="submit" aria-label="Approve {{ $application->business_name }}" title="Approve seller"><svg viewBox="0 0 24 24" fill="none" aria-hidden="true"><path d="m5 12 4.5 4.5L19 7" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"/></svg></button></form>
                                            <button type="button" class="sa-button icon reject" data-open-review-reject aria-label="Reject {{ $application->business_name }}" title="Reject seller"><svg viewBox="0 0 24 24" fill="none" aria-hidden="true"><path d="m6 6 12 12M18 6 6 18" stroke="currentColor" stroke-width="2" stroke-linecap="round"/></svg></button>
                                            <form method="POST" action="{{ route('admin.applications.archive', $application->id) }}" onsubmit="return confirm('Archive this application?')">@csrf<button class="sa-button" type="submit" aria-label="Archive {{ $application->business_name }}" title="Archive application">Archive</button></form>
                                        @endif
                                    </div></td>
                                </tr>
                            @endforeach
                            </tbody>
                        </table>
                    </div>
                    <div class="sa-pagination" aria-label="Application pages">
                        <span class="sa-pagination-info">Showing {{ $applications->firstItem() }}–{{ $applications->lastItem() }} of {{ $applications->total() }}</span>
                        <a class="sa-page-link" href="{{ $applications->previousPageUrl() ?? '#' }}" aria-label="Previous page" aria-disabled="{{ $applications->onFirstPage() ? 'true' : 'false' }}">Previous</a>
                        @foreach ($applications->getUrlRange(max(1, $applications->currentPage() - 2), min($applications->lastPage(), $applications->currentPage() + 2)) as $pageNumber => $url)
                            <a class="sa-page-link {{ $pageNumber === $applications->currentPage() ? 'current' : '' }}" href="{{ $url }}" @if ($pageNumber === $applications->currentPage()) aria-current="page" @endif>{{ $pageNumber }}</a>
                        @endforeach
                        <a class="sa-page-link" href="{{ $applications->nextPageUrl() ?? '#' }}" aria-label="Next page" aria-disabled="{{ !$applications->hasMorePages() ? 'true' : 'false' }}">Next</a>
                    </div>
                @endif
            </section>

            <aside class="sa-card sa-panel" id="applicationPanel" hidden aria-label="Seller application review panel">
                <div class="sa-panel-top"><div><div class="sa-eyebrow" id="panelEyebrow">Reviewing application</div><h2 id="panelStore"></h2><div class="sa-panel-date" id="panelApplied"></div></div><button class="sa-button icon" type="button" id="closeApplicationPanel" aria-label="Close review panel" title="Close">×</button></div>
                <div id="applicationPanelContent"><p class="sa-sub">Select Review to inspect an application.</p></div>
            </aside>
        </div>
    </div>

    <script>
        (() => {
            const panel = document.getElementById('applicationPanel');
            const content = document.getElementById('applicationPanelContent');
            const escapeHtml = (value) => String(value ?? '').replace(/[&<>"']/g, (char) => ({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#039;'}[char]));
            const openPanel = (button, focusReject = false) => {
                const d = button.dataset;
                const pending = d.status === 'pending';
                const verified = d.emailVerified === '1';
                const duplicateCount = Number(d.applicationCount || 1);
                const idAvailable = d.idAvailable === '1';
                const permitAvailable = d.permitAvailable === '1';
                document.getElementById('panelStore').textContent = d.store || 'Store name not provided';
                document.getElementById('panelApplied').textContent = `Applied ${d.applied || ''}`;
                document.getElementById('panelEyebrow').textContent = pending ? 'Reviewing application' : `${d.status} application`;
                const documentCard = (label, url, available) => available
                    ? `<div class="sa-document"><span>${label}</span><a class="sa-button" href="${escapeHtml(url)}" target="_blank" rel="noopener">Open</a></div>`
                    : `<div class="sa-document"><span>${label}</span><span class="sa-sub">Not uploaded</span></div>`;
                content.innerHTML = `<div class="sa-detail-box"><div class="sa-detail-row"><span>Owner</span><strong>${escapeHtml(d.owner)}</strong></div><div class="sa-detail-row"><span>Email</span><strong>${escapeHtml(d.email)}</strong></div><div class="sa-detail-row"><span>Phone</span><strong>${escapeHtml(d.phone)}</strong></div><div class="sa-detail-row"><span>Sells</span><strong>${escapeHtml(d.category || 'Not provided')}</strong></div></div>
                    <section class="sa-panel-section"><h3>About the shop</h3><p class="sa-shop-description">${escapeHtml(d.description || 'The applicant has not added a shop description.')}</p></section>
                    <section class="sa-panel-section"><h3>Documents</h3><div class="sa-documents">${documentCard('Valid ID',d.idDocument,idAvailable)}${documentCard('Business permit',d.permitDocument,permitAvailable)}</div></section>
                    <section class="sa-panel-section"><h3>Quick checks</h3><ul class="sa-checks"><li><span class="sa-check-mark ${verified?'pass':'warn'}">${verified?'✓':'!'}</span><span>Email ${verified?'is verified':'has not been verified'}.</span></li><li><span class="sa-check-mark ${duplicateCount===1?'pass':'warn'}">${duplicateCount===1?'✓':'!'}</span><span>${duplicateCount===1?'No earlier applications from this account.':`${duplicateCount-1} earlier application(s) from this account.`}</span></li><li><span class="sa-check-mark ${idAvailable&&permitAvailable?'pass':'warn'}">${idAvailable&&permitAvailable?'✓':'!'}</span><span>${Number(idAvailable)+Number(permitAvailable)} of 2 required documents uploaded and available.</span></li></ul></section>
                    ${d.status==='rejected'?`<section class="sa-panel-section"><h3>Previous decision</h3><p class="sa-shop-description"><strong>Reason:</strong> ${escapeHtml(d.rejectionReason||'Not recorded')}<br>${escapeHtml(d.adminNote||'')}</p></section>`:''}
                    ${pending?`<div class="sa-reject-fields"><label for="applicationRejectReason">Reason if rejecting</label><select class="sa-input" id="applicationRejectReason" name="reason" form="applicationRejectForm" required><option value="">Choose a reason</option><option>Invalid business documents</option><option>Incomplete application</option><option>Duplicate application</option><option>Invalid seller information</option><option>Does not meet seller requirements</option><option>Other</option></select><label for="applicationRejectNote">Additional note (optional)</label><textarea class="sa-input sa-note" id="applicationRejectNote" name="note" form="applicationRejectForm" maxlength="2000" placeholder="Add a note for the applicant"></textarea></div><div class="sa-panel-actions"><form method="POST" action="/admin/applications/${escapeHtml(button.closest('tr').dataset.id)}/reject" id="applicationRejectForm"><input type="hidden" name="_token" value="${escapeHtml(document.querySelector('meta[name="csrf-token"]')?.content||'')}"><button class="sa-button reject" type="submit">Reject</button></form><form method="POST" action="/admin/applications/${escapeHtml(button.closest('tr').dataset.id)}/approve" onsubmit="return confirm('Approve this seller and activate seller access?')"><input type="hidden" name="_token" value="${escapeHtml(document.querySelector('meta[name="csrf-token"]')?.content||'')}"><button class="sa-button approve" type="submit">Approve seller</button></form></div>`:''}`;
                panel.hidden = false;
                document.querySelectorAll('[data-application-row]').forEach((row) => row.classList.toggle('selected', row.dataset.id === button.closest('tr').dataset.id));
                panel.scrollIntoView({behavior:'smooth',block:'nearest'});
                if (focusReject) setTimeout(() => document.getElementById('applicationRejectReason')?.focus(), 40);
                document.getElementById('applicationRejectForm')?.addEventListener('submit', (event) => {
                    const reason = document.getElementById('applicationRejectReason').value;
                    if (!reason || !confirm(`Reject this application for “${d.store}” with reason “${reason}”?`)) event.preventDefault();
                });
            };
            document.querySelectorAll('[data-view-application]').forEach((button) => button.addEventListener('click', () => openPanel(button)));
            document.querySelectorAll('[data-open-review-reject]').forEach((button) => button.addEventListener('click', () => openPanel(button.closest('tr').querySelector('[data-view-application]'), true)));
            document.querySelectorAll('[data-application-row]').forEach((row) => {
                row.addEventListener('click', (event) => { if (event.target.closest('button,form,a,input')) return; const button=row.querySelector('[data-view-application]'); if(button) openPanel(button); });
                row.addEventListener('keydown', (event) => { if (event.key === 'Enter' && event.target === row) { event.preventDefault(); const button=row.querySelector('[data-view-application]'); if(button) openPanel(button); } });
            });
            document.getElementById('closeApplicationPanel')?.addEventListener('click', () => { panel.hidden=true; document.querySelector('[data-view-application]')?.focus(); });
            document.addEventListener('keydown', (event) => { if (event.key === 'Escape' && panel && !panel.hidden) { panel.hidden=true; document.querySelector('[data-view-application]')?.focus(); } });
            document.getElementById('sellerApplicationFilters')?.addEventListener('submit', (event) => { event.currentTarget.setAttribute('aria-busy','true'); });
            document.querySelectorAll('#sellerApplicationPeriod,#sellerApplicationSort').forEach((select) => select.addEventListener('change', () => document.getElementById('sellerApplicationFilters').requestSubmit()));
            document.getElementById('sellerApplicationSearch')?.addEventListener('keydown', (event) => { if (event.key === 'Enter') document.getElementById('sellerApplicationFilters').requestSubmit(); });
        })();
    </script>
</x-admin-layout>
