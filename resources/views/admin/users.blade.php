<x-admin-layout title="Users">
    @php
        $roleTabs = ['all' => 'All users', 'buyer' => 'Buyers', 'seller' => 'Sellers', 'admin' => 'Admins'];
        $reasonLabels = [
            'policy_violation' => 'Policy violation', 'suspicious_activity' => 'Suspicious activity',
            'user_request' => 'User request', 'fraud' => 'Fraud', 'terms_violation' => 'Terms violation', 'other' => 'Other',
        ];
        $normalized = fn ($value) => strtolower(str_replace([' ', '.', '-'], '', trim((string) $value)));
        $normalizedPhone = fn ($value) => str_replace([' ', '-', '(', ')', '+', '.'], '', trim((string) $value));
        $isVerified = fn ($user) => (bool) ($user->email_verified || $user->email_verified_at);
        $displayStatus = fn ($user) => in_array($user->status, ['suspended', 'banned'], true) ? 'Suspended' : ($user->status === 'deactivated' ? 'Deactivated' : ($isVerified($user) ? 'Active' : 'Email not verified'));
        $statusClass = fn ($status) => match ($status) { 'Suspended' => 'is-suspended', 'Deactivated' => 'is-deactivated', 'Email not verified' => 'is-unverified', default => 'is-active' };
        $userDetails = $users->getCollection()->mapWithKeys(function ($user) use ($normalized, $normalizedPhone, $duplicateNames, $duplicateStores, $duplicatePhones, $isVerified, $displayStatus, $reasonLabels) {
            $status = $displayStatus($user);
            $nameKey = $normalized($user->name);
            $storeKey = $normalized($user->shop_name);
            $phoneKey = $normalizedPhone($user->contact_number);
            $duplicate = ($nameKey !== '' && in_array($nameKey, $duplicateNames, true))
                || ($storeKey !== '' && in_array($storeKey, $duplicateStores, true))
                || ($phoneKey !== '' && in_array($phoneKey, $duplicatePhones, true));
            return [$user->id => [
                'id' => $user->id, 'name' => $user->name, 'initial' => mb_strtoupper(mb_substr(trim($user->name) ?: '?', 0, 1)),
                'role' => ucfirst($user->role), 'status' => $status,
                'status_until' => in_array($user->status, ['suspended', 'banned'], true) ? $user->suspended_until?->format('M j, Y g:i A') : null,
                'email' => $user->email, 'verified' => $isVerified($user), 'phone' => $user->contact_number ?: 'Not provided',
                'location' => collect([$user->barangay, $user->municipality, $user->province])->filter()->implode(', ') ?: 'Not provided',
                'joined' => $user->created_at?->format('M j, Y'), 'joined_relative' => $user->created_at?->diffForHumans(),
                'last_active' => $user->last_login_at?->format('M j, Y g:i A') ?: 'Never signed in',
                'orders' => (int) $user->orders_count, 'seller_orders' => (int) $user->sold_orders_count,
                'products' => (int) $user->products_count, 'live_products' => (int) $user->live_products_count,
                'total_spent' => number_format((float) ($user->total_spent ?? 0), 2),
                'total_sales' => number_format((float) ($user->total_sales ?? 0), 2), 'duplicate' => $duplicate,
                'can_manage' => $user->role !== 'admin' && (int) $user->id !== (int) Auth::id(),
                'history' => $user->statusLogs->map(fn ($log) => [
                    'action' => ucfirst(str_replace('_', ' ', $log->action)), 'reason' => $reasonLabels[$log->reason] ?? ($log->reason ? ucfirst(str_replace('_', ' ', $log->reason)) : null),
                    'note' => $log->note, 'until' => $log->until?->format('M j, Y g:i A'),
                    'date' => $log->created_at?->format('M j, Y g:i A'), 'admin' => $log->admin?->name ?: 'System',
                ])->values(),
            ]];
        });
    @endphp

    <section class="users-page" aria-labelledby="users-title">
        <div class="users-heading">
            <div><p class="users-eyebrow">Accounts & access</p><h2 id="users-title">Manage users</h2><p class="users-subtitle">Review account activity and manage marketplace access.</p></div>
            <a class="users-export" href="{{ route('admin.users.export', request()->query()) }}" aria-label="Export users matching the current filters as CSV">↓ <span>Export CSV</span></a>
        </div>

        @if (session('flash_success'))<div class="users-flash" role="status">{{ session('flash_success') }}</div>@endif
        @if ($errors->any())<div class="users-error" role="alert">{{ $errors->first() }}</div>@endif

        <div class="users-stats">
            <article class="users-stat"><span class="stat-mark">◎</span><div><span class="stat-title">Total users</span><strong>{{ number_format($stats['total']) }}</strong><small>{{ number_format($stats['new_this_week']) }} new this week</small></div></article>
            <article class="users-stat"><span class="stat-mark stat-rose">♡</span><div><span class="stat-title">Buyers</span><strong>{{ number_format($stats['buyers']) }}</strong><small>Marketplace customers</small></div></article>
            <article class="users-stat"><span class="stat-mark stat-sage">✦</span><div><span class="stat-title">Active sellers</span><strong>{{ number_format($stats['sellers']) }}</strong><small>Currently active accounts</small></div></article>
            <article class="users-stat"><span class="stat-mark stat-alert">!</span><div><span class="stat-title">Restricted accounts</span><strong>{{ number_format($stats['suspended_deactivated']) }}</strong><small>Suspended or deactivated</small></div></article>
        </div>

        <div class="users-panel">
            <nav class="users-tabs" aria-label="Filter by role">
                @foreach ($roleTabs as $role => $label)
                    @php $count = $role === 'all' ? $stats['total'] : (int) $roleCounts->get($role, 0); @endphp
                    <a href="{{ route('admin.users', array_merge(request()->except(['page', 'role']), ['role' => $role])) }}" class="users-tab {{ $filters['role'] === $role ? 'selected' : '' }}" @if($filters['role'] === $role) aria-current="page" @endif>{{ $label }} <span>{{ number_format($count) }}</span></a>
                @endforeach
            </nav>
            <form class="users-filters" method="GET" action="{{ route('admin.users') }}">
                <input type="hidden" name="role" value="{{ $filters['role'] }}">
                <label class="users-search"><span aria-hidden="true">⌕</span><input type="search" name="q" value="{{ $filters['q'] }}" placeholder="Search name, store, email or phone" aria-label="Search users"></label>
                <select name="status" aria-label="Filter by status">
                    @foreach (['all' => 'All statuses', 'active' => 'Active', 'email-unverified' => 'Email not verified', 'suspended' => 'Suspended', 'deactivated' => 'Deactivated'] as $key => $label)<option value="{{ $key }}" @selected($filters['status'] === $key)>{{ $label }}</option>@endforeach
                </select>
                <select name="sort" aria-label="Sort users">
                    @foreach (['newest' => 'Newest', 'oldest' => 'Oldest', 'name' => 'Name A–Z', 'last_active' => 'Last active'] as $key => $label)<option value="{{ $key }}" @selected($filters['sort'] === $key)>{{ $label }}</option>@endforeach
                </select>
                <button type="submit" class="users-filter-submit">Apply</button>
            </form>

            <div class="users-table-wrap">
                <table class="users-table">
                    <thead><tr><th>User</th><th>Email</th><th>Role</th><th>Status</th><th>Joined</th><th>Last active</th><th>Activity</th><th>Actions</th></tr></thead>
                    <tbody>
                    @forelse ($users as $u)
                        @php
                            $status = $displayStatus($u);
                            $nameKey = $normalized($u->name); $storeKey = $normalized($u->shop_name); $phoneKey = $normalizedPhone($u->contact_number);
                            $possibleDuplicate = ($nameKey !== '' && in_array($nameKey, $duplicateNames, true)) || ($storeKey !== '' && in_array($storeKey, $duplicateStores, true)) || ($phoneKey !== '' && in_array($phoneKey, $duplicatePhones, true));
                            $canManage = $u->role !== 'admin' && (int) $u->id !== (int) Auth::id();
                        @endphp
                        <tr class="users-row" data-user-row="{{ $u->id }}" tabindex="0" aria-label="View {{ $u->name }} details">
                            <td data-label="User"><div class="user-cell"><span class="user-avatar">{{ mb_strtoupper(mb_substr(trim($u->name) ?: '?', 0, 1)) }}</span><span class="user-main"><strong>{{ $u->name }} @if((int)$u->id === (int)Auth::id())<em class="you-label">You</em>@endif</strong><small>{{ $u->shop_name ?: collect([$u->municipality, $u->province])->filter()->implode(', ') ?: 'Lumora account' }}</small>@if($possibleDuplicate)<span class="duplicate-hint" title="Another account has a matching normalized name, store name, or phone">⚠ Possible duplicate</span>@endif</span></div></td>
                            <td data-label="Email"><span class="email-value">{{ $u->email }}</span><small class="verify-state {{ $isVerified($u) ? 'verified' : 'not-verified' }}">{{ $isVerified($u) ? '✓ Verified' : '○ Not verified' }}</small></td>
                            <td data-label="Role"><span class="role-pill role-{{ $u->role }}">{{ ucfirst($u->role) }}</span></td>
                            <td data-label="Status"><span class="status-pill {{ $statusClass($status) }}">{{ $status }}</span>@if(in_array($u->status, ['suspended','banned'], true) && $u->suspended_until)<small class="status-until">until {{ $u->suspended_until->format('M j, Y') }}</small>@endif</td>
                            <td data-label="Joined"><span class="joined-date">{{ $u->created_at?->format('M j, Y') }}</span><small>{{ $u->created_at?->diffForHumans() }}</small></td>
                            <td data-label="Last active">{{ $u->last_login_at?->diffForHumans() ?: 'Never' }}</td>
                            <td data-label="Activity">@if($u->role === 'buyer'){{ number_format($u->orders_count) }} orders @elseif($u->role === 'seller'){{ number_format($u->products_count) }} products @else — @endif</td>
                            <td data-label="Actions"><div class="row-actions"><button type="button" class="view-user" data-open-user="{{ $u->id }}">View</button>@if($canManage)<details class="user-menu"><summary aria-label="More actions for {{ $u->name }}">⋯</summary><div class="user-menu-list"><button type="button" data-copy-email="{{ $u->email }}">Copy email</button>
                                @if($canManage)
                                    @if(!in_array($u->status, ['suspended','banned','deactivated'], true))<button type="button" data-user-action="suspend" data-user-id="{{ $u->id }}">Suspend</button>@endif
                                    @if($u->status !== 'deactivated')<button type="button" data-user-action="deactivate" data-user-id="{{ $u->id }}" class="danger-action">Deactivate</button>@endif
                                    @if(in_array($u->status, ['suspended','banned','deactivated'], true))<button type="button" data-user-action="reactivate" data-user-id="{{ $u->id }}">Reactivate</button>@endif
                                @endif
                            </div></details>@endif</div></td>
                        </tr>
                    @empty
                        <tr><td colspan="8"><div class="users-empty"><span>⌕</span><strong>No users found</strong><small>Try changing your search or filters.</small></div></td></tr>
                    @endforelse
                    </tbody>
                </table>
            </div>
            @if($users->hasPages())<div class="users-pagination">{{ $users->links() }}</div>@endif
        </div>
    </section>

    <div class="user-drawer-backdrop" id="userDrawerBackdrop" hidden></div>
    <aside class="user-drawer" id="userDrawer" role="dialog" aria-modal="true" aria-labelledby="drawerName" hidden>
        <div class="drawer-heading"><div><span class="drawer-kicker">User profile</span><button type="button" class="drawer-close" data-close-drawer aria-label="Close details">×</button></div><div class="drawer-user-heading"><span class="user-avatar drawer-avatar" id="drawerInitial"></span><div><h2 id="drawerName"></h2><div class="drawer-badges"><span class="role-pill" id="drawerRole"></span><span class="status-pill" id="drawerStatus"></span></div></div></div></div>
        <div class="drawer-content">
            <section class="drawer-section"><h3>Contact</h3><dl><div><dt>Email</dt><dd id="drawerEmail"></dd></div><div><dt>Phone</dt><dd id="drawerPhone"></dd></div><div><dt>Location</dt><dd id="drawerLocation"></dd></div></dl></section>
            <section class="drawer-section"><h3>Account</h3><dl><div><dt>Joined</dt><dd id="drawerJoined"></dd></div><div><dt>Last active</dt><dd id="drawerLastActive"></dd></div></dl><div class="drawer-role-stats" id="drawerStats"></div></section>
            <section class="drawer-section"><h3>Account history</h3><div class="history-list" id="drawerHistory"></div></section>
        </div>
        <div class="drawer-actions" id="drawerActions"></div>
    </aside>

    <div class="action-modal-backdrop" id="actionModalBackdrop" hidden>
        <section class="action-modal" role="dialog" aria-modal="true" aria-labelledby="actionModalTitle">
            <button type="button" class="drawer-close" data-close-modal aria-label="Close dialog">×</button>
            <span class="drawer-kicker">Account access</span><h2 id="actionModalTitle"></h2><p id="actionModalDescription"></p>
            <form method="POST" id="suspendForm" action="" hidden>
                @csrf
                <label>Reason<select name="reason" required>@foreach($suspendReasons as $reason)<option value="{{ $reason }}">{{ $reasonLabels[$reason] ?? ucfirst($reason) }}</option>@endforeach</select></label>
                <label>Message to the user<textarea name="message" rows="3" required maxlength="2000" placeholder="Explain why the account is being suspended"></textarea></label>
                <label>Duration<select name="duration" required><option value="7">7 days</option><option value="30">30 days</option><option value="indefinite">Until reactivated</option></select></label>
                <button type="submit" class="modal-submit">Suspend account</button>
            </form>
            <form method="POST" id="deactivateForm" action="" hidden>
                @csrf
                <label>Reason<select name="reason" required>@foreach($deactivateReasons as $reason)<option value="{{ $reason }}">{{ $reasonLabels[$reason] ?? ucfirst($reason) }}</option>@endforeach</select></label>
                <label>Message to the user<textarea name="message" rows="3" required maxlength="2000" placeholder="Explain why the account is being deactivated"></textarea></label>
                <label>Type <strong>DEACTIVATE</strong> to confirm<input name="confirmation" id="deactivateConfirmation" required autocomplete="off" placeholder="DEACTIVATE"></label>
                <p class="open-orders-warning">Open orders will not be cancelled automatically.</p>
                <button type="submit" class="modal-submit danger-submit" id="deactivateSubmit" disabled>Deactivate account</button>
            </form>
            <form method="POST" id="reactivateForm" action="" hidden>
                @csrf @method('PATCH')
                <p>Restore this account to active access? Email verification is still required if the address has not been verified.</p>
                <button type="submit" class="modal-submit">Reactivate account</button>
            </form>
        </section>
    </div>

    <style>
        .users-page{--u-maroon:#5B1A35;--u-rose:#B96562;--u-surface:#fff;--u-border:#F0E2DA;--u-muted:#8B7A80;color:#2B1C22}
        .users-heading{display:flex;align-items:center;justify-content:space-between;gap:18px;margin:0 0 22px}.users-eyebrow,.drawer-kicker{color:#B96562;font-size:11px;font-weight:700;letter-spacing:.12em;text-transform:uppercase}.users-heading h2{margin:4px 0;font-size:23px;font-weight:700;color:#3C1B2C}.users-subtitle{color:var(--u-muted);font-size:13px}.users-export{display:inline-flex;align-items:center;gap:8px;padding:10px 15px;border:1px solid var(--u-border);border-radius:10px;background:#fff;color:var(--u-maroon);font-size:13px;font-weight:600;text-decoration:none;white-space:nowrap}.users-export:hover{background:#FBF1EC;border-color:#D9B5B4}
        .users-flash,.users-error{margin:0 0 16px;padding:12px 15px;border-radius:11px;font-size:13px}.users-flash{background:#eef3ec;color:#4f6e4b}.users-error{background:#fff0ee;color:#a64139}
        .users-stats{display:grid;grid-template-columns:repeat(4,minmax(0,1fr));gap:16px;margin-bottom:20px}.users-stat{display:flex;align-items:center;gap:14px;padding:18px;background:#fff;border:1px solid var(--u-border);border-radius:16px;box-shadow:0 4px 18px rgba(91,26,53,.035)}.stat-mark{width:43px;height:43px;display:grid;place-items:center;border-radius:13px;background:#5B1A35;color:#fff;font-size:23px}.stat-mark.stat-rose{background:#B96562}.stat-mark.stat-sage{background:#71856B}.stat-mark.stat-alert{background:#D98A5E}.users-stat>div{display:grid;gap:2px}.stat-title{color:var(--u-muted);font-size:12px}.users-stat strong{font-size:22px;color:#2B1C22}.users-stat small{color:var(--u-muted);font-size:10px}
        .users-panel{background:#fff;border:1px solid var(--u-border);border-radius:16px;overflow:visible;box-shadow:0 4px 18px rgba(91,26,53,.035)}.users-tabs{display:flex;gap:6px;padding:0 20px;border-bottom:1px solid var(--u-border);overflow:auto}.users-tab{display:flex;align-items:center;gap:8px;padding:15px 10px 12px;border-bottom:2px solid transparent;color:var(--u-muted);font-size:12px;text-decoration:none;white-space:nowrap}.users-tab.selected{border-color:#5B1A35;color:#5B1A35;font-weight:700}.users-tab span{padding:2px 7px;border-radius:99px;background:#F7F0EE;color:#80636B;font-size:10px}.users-filters{display:flex;align-items:center;gap:10px;padding:16px 20px}.users-search{display:flex;align-items:center;gap:9px;min-width:220px;flex:1;padding:0 12px;border:1px solid var(--u-border);border-radius:9px;color:#9A8289}.users-search span{font-size:22px}.users-search input{width:100%;height:39px;border:0;outline:0;background:transparent;color:#2B1C22;font:inherit;font-size:12px}.users-filters select,.action-modal select,.action-modal textarea,.action-modal input{min-height:40px;padding:8px 11px;border:1px solid var(--u-border);border-radius:9px;background:#fff;color:#392933;font:inherit;font-size:12px}.users-filters select{min-width:150px}.users-filter-submit{height:40px;padding:0 16px;border:0;border-radius:9px;background:#5B1A35;color:#fff;font:inherit;font-size:12px;font-weight:600;cursor:pointer}
        .users-table-wrap{width:100%;overflow-x:auto}.users-table{width:100%;border-collapse:collapse}.users-table th{padding:11px 12px;background:#FCF8F6;color:#8B7A80;text-align:left;text-transform:uppercase;letter-spacing:.045em;font-size:9px;font-weight:700;white-space:nowrap}.users-table td{padding:13px 12px;border-bottom:1px solid #F4ECE8;color:#4a3a40;vertical-align:middle;font-size:11px}.users-table tr:last-child td{border-bottom:0}.users-table tbody tr:hover td{background:#FFFCFA}.users-row{cursor:pointer}.users-row:focus-visible{outline:2px solid #B96562;outline-offset:-2px}.user-cell{display:flex;align-items:center;gap:10px;min-width:155px}.user-avatar{width:35px;height:35px;flex:0 0 35px;display:grid;place-items:center;border-radius:50%;background:#F3DDE2;color:#5B1A35;font-size:13px;font-weight:700}.user-main{display:flex;flex-direction:column;gap:3px;min-width:0}.user-main strong{max-width:200px;overflow:hidden;color:#33242A;text-overflow:ellipsis;white-space:nowrap;font-size:11px}.user-main small,.users-table td small{display:block;color:#97878C;font-size:9px}.email-value{display:block;max-width:190px;overflow:hidden;text-overflow:ellipsis;white-space:nowrap}.verify-state{margin-top:3px}.verify-state.verified{color:#648161}.verify-state.not-verified{color:#B87848}.role-pill,.status-pill{display:inline-flex;align-items:center;padding:4px 8px;border-radius:99px;font-size:9px;font-weight:600;white-space:nowrap}.role-buyer{background:#F5E4E8;color:#8C4563}.role-seller{background:#E9F0E6;color:#55714E}.role-admin{background:#EEE6F3;color:#684675}.is-active{background:#EAF1E8;color:#597453}.is-unverified{background:#FFF3E3;color:#9A6A37}.is-suspended{background:#FFF1DE;color:#A76926}.is-deactivated{background:#FBE9E5;color:#AA4B40}.status-until{margin-top:3px}.joined-date{white-space:nowrap}.duplicate-hint{color:#B87848;font-size:9px}.you-label{padding:2px 5px;border-radius:99px;background:#F2ECEE;color:#826A72;font-size:8px;font-style:normal}.row-actions{display:flex;align-items:center;gap:8px}.view-user{padding:6px 9px;border:1px solid #E8D9D4;border-radius:7px;background:white;color:#5B1A35;font:inherit;font-size:10px;font-weight:600;cursor:pointer}.user-menu{position:relative}.user-menu summary{width:27px;height:27px;display:grid;place-items:center;border:1px solid #E8D9D4;border-radius:7px;color:#5B1A35;cursor:pointer;list-style:none;font-size:19px;line-height:1}.user-menu summary::-webkit-details-marker{display:none}.user-menu-list{position:absolute;z-index:10;right:0;top:31px;min-width:145px;padding:5px;border:1px solid var(--u-border);border-radius:10px;background:#fff;box-shadow:0 10px 28px #3513221c}.user-menu-list button{display:block;width:100%;padding:8px;border:0;border-radius:6px;background:transparent;color:#49373e;text-align:left;font:inherit;font-size:11px;cursor:pointer}.user-menu-list button:hover{background:#FBF1EC}.user-menu-list .danger-action{color:#A64A3F}.users-empty{display:grid;justify-items:center;gap:5px;padding:42px 16px;color:#8B7A80}.users-empty span{font-size:25px}.users-empty strong{color:#5B1A35;font-size:14px}.users-empty small{font-size:11px}.users-pagination{padding:16px 20px;border-top:1px solid var(--u-border)}
        .user-drawer-backdrop,.action-modal-backdrop{position:fixed;inset:0;z-index:100;background:rgba(39,20,30,.42);backdrop-filter:blur(2px)}.user-drawer{position:fixed;top:0;right:0;z-index:101;width:min(500px,100vw);height:100vh;display:flex;flex-direction:column;background:#FFFEFD;box-shadow:-15px 0 45px #35132224;animation:drawer-in .22s ease-out}.user-drawer[hidden],.user-drawer-backdrop[hidden],.action-modal-backdrop[hidden]{display:none}@keyframes drawer-in{from{transform:translateX(20px);opacity:.8}to{transform:translateX(0);opacity:1}}.drawer-heading{padding:24px 25px 20px;border-bottom:1px solid var(--u-border);background:#FCF8F6}.drawer-heading>div:first-child{display:flex;justify-content:space-between;align-items:center}.drawer-close{width:32px;height:32px;border:1px solid var(--u-border);border-radius:50%;background:white;color:#6b4b58;font-size:22px;line-height:1;cursor:pointer}.drawer-user-heading{display:flex;align-items:center;gap:13px;margin-top:17px}.drawer-avatar{width:52px;height:52px;flex-basis:52px;font-size:18px}.drawer-user-heading h2{margin:0 0 7px;color:#382431;font-size:20px}.drawer-badges{display:flex;gap:6px}.drawer-content{flex:1;overflow:auto;padding:5px 25px 20px}.drawer-section{padding:17px 0;border-bottom:1px solid var(--u-border)}.drawer-section h3{margin:0 0 12px;color:#5B1A35;font-size:12px}.drawer-section dl{display:grid;gap:10px;margin:0}.drawer-section dl>div{display:flex;justify-content:space-between;gap:16px;font-size:11px}.drawer-section dt{color:#8B7A80}.drawer-section dd{margin:0;color:#3b2a31;text-align:right;overflow-wrap:anywhere}.drawer-role-stats{display:grid;grid-template-columns:repeat(3,1fr);gap:8px;margin-top:14px}.drawer-role-stats div{padding:10px;border-radius:9px;background:#FCF6F4}.drawer-role-stats strong,.drawer-role-stats small{display:block}.drawer-role-stats strong{color:#5B1A35;font-size:14px}.drawer-role-stats small{margin-top:3px;color:#8B7A80;font-size:9px}.history-list{display:grid;gap:0}.history-item{position:relative;padding:0 0 15px 17px;border-left:1px solid #E7CDD2}.history-item:last-child{border-left-color:transparent;padding-bottom:0}.history-item:before{content:'';position:absolute;top:3px;left:-4px;width:7px;height:7px;border-radius:50%;background:#B96562}.history-item strong{display:block;color:#423038;font-size:10px}.history-item small{display:block;margin-top:3px;color:#8B7A80;font-size:9px;line-height:1.45}.history-empty{color:#8B7A80;font-size:11px}.drawer-actions{display:flex;gap:9px;padding:15px 25px;border-top:1px solid var(--u-border);background:#fff}.drawer-actions button{flex:1;min-height:39px}
        .action-modal-backdrop{z-index:110;display:grid;place-items:center;padding:16px}.action-modal{position:relative;width:min(480px,100%);max-height:90vh;overflow:auto;padding:25px;border:1px solid var(--u-border);border-radius:18px;background:#fff;box-shadow:0 20px 60px #35132235}.action-modal>.drawer-close{position:absolute;top:16px;right:16px}.action-modal h2{margin:6px 35px 6px 0;color:#412134;font-size:20px}.action-modal>p{margin:0 0 18px;color:#8B7A80;font-size:12px}.action-modal form{display:grid;gap:13px;margin-top:16px}.action-modal form[hidden]{display:none}.action-modal label{display:grid;gap:6px;color:#57434b;font-size:11px;font-weight:600}.action-modal select,.action-modal textarea,.action-modal input{width:100%;font-size:12px}.action-modal textarea{resize:vertical}.action-modal label strong{color:#A64A3F}.modal-submit{min-height:42px;margin-top:3px;border:0;border-radius:9px;background:#5B1A35;color:white;font:inherit;font-size:12px;font-weight:600;cursor:pointer}.modal-submit:disabled{opacity:.45;cursor:not-allowed}.danger-submit{background:#A84D41}.open-orders-warning{padding:10px;border-radius:8px;background:#FFF5E8;color:#94652D;font-size:11px}.action-modal #reactivateForm p{color:#57434b;font-size:12px;line-height:1.5}
        @media(max-width:1100px){.users-stats{gap:10px}.users-stat{padding:14px}.users-filters{flex-wrap:wrap}.users-search{flex-basis:100%}}
        @media(max-width:900px){.users-table thead{display:none}.users-table,.users-table tbody{display:block}.users-table tbody{padding:10px}.users-table .users-row{display:grid;grid-template-columns:repeat(2,minmax(0,1fr));gap:8px 14px;margin:0 0 10px;padding:13px;border:1px solid var(--u-border);border-radius:12px;background:white}.users-table .users-row td{display:flex;min-width:0;align-items:center;justify-content:space-between;gap:10px;padding:5px 2px;border:0;font-size:11px}.users-table .users-row td:first-child{grid-column:1/-1}.users-table .users-row td[data-label="Actions"]{justify-content:flex-end}.users-table .users-row td:before{content:attr(data-label);color:#8B7A80;font-size:9px;font-weight:600;text-transform:uppercase}.users-table .users-row td:first-child:before{display:none}.user-cell{width:100%}.user-main{flex:1}.users-table .users-row td:has(.row-actions):before{display:none}.users-empty{display:grid!important}.users-filters select{flex:1;min-width:130px}.users-filter-submit{flex:0 0 auto}}
        @media(max-width:680px){.users-heading{align-items:flex-start}.users-heading h2{font-size:20px}.users-export{padding:9px}.users-stats{grid-template-columns:repeat(2,minmax(0,1fr));gap:9px}.users-stat{gap:9px;padding:12px}.stat-mark{width:35px;height:35px}.users-stat strong{font-size:18px}.users-stat small{font-size:9px}.users-tabs{padding:0 9px}.users-tab{padding:13px 7px 10px;font-size:10px}.users-filters{padding:12px;gap:7px}.users-filters select{font-size:10px}.drawer-heading{padding:18px}.drawer-content{padding:5px 18px 20px}.drawer-actions{padding:12px 18px}}
    </style>
    <script>
        const adminUserDetails = {{ \Illuminate\Support\Js::from($userDetails) }};
        const drawer = document.getElementById('userDrawer');
        const drawerBackdrop = document.getElementById('userDrawerBackdrop');
        const actionBackdrop = document.getElementById('actionModalBackdrop');
        let activeDrawerUser = null;
        const escapeHtml = (value) => String(value ?? '').replace(/[&<>"']/g, (char) => ({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#039;'}[char]));
        const setPill = (element, label, prefix) => { element.textContent = label; element.className = prefix + ' ' + (label === 'Suspended' ? 'is-suspended' : label === 'Deactivated' ? 'is-deactivated' : label === 'Email not verified' ? 'is-unverified' : label === 'Active' ? 'is-active' : 'role-' + label.toLowerCase()); };
        function openUserDrawer(id) {
            const user = adminUserDetails[id]; if (!user) return;
            activeDrawerUser = user; document.getElementById('drawerInitial').textContent = user.initial;
            document.getElementById('drawerName').textContent = user.name;
            setPill(document.getElementById('drawerRole'), user.role, 'role-pill');
            setPill(document.getElementById('drawerStatus'), user.status, 'status-pill');
            if (user.status_until) document.getElementById('drawerStatus').textContent += ' · until ' + user.status_until;
            document.getElementById('drawerEmail').textContent = user.email + (user.verified ? ' · Verified' : ' · Not verified');
            document.getElementById('drawerPhone').textContent = user.phone;
            document.getElementById('drawerLocation').textContent = user.location;
            document.getElementById('drawerJoined').textContent = user.joined + ' · ' + user.joined_relative;
            document.getElementById('drawerLastActive').textContent = user.last_active;
            const stats = user.role === 'Buyer'
                ? [['Orders', user.orders], ['Total spent', '₱' + user.total_spent]]
                : user.role === 'Seller' ? [['Live products', user.live_products], ['Orders', user.seller_orders], ['Total sales', '₱' + user.total_sales]]
                : [['Orders', user.orders], ['Products', user.products]];
            document.getElementById('drawerStats').innerHTML = stats.map(([label,value]) => '<div><strong>'+escapeHtml(value)+'</strong><small>'+escapeHtml(label)+'</small></div>').join('');
            const history = document.getElementById('drawerHistory');
            history.innerHTML = user.history.length ? user.history.map(item => '<div class="history-item"><strong>'+escapeHtml(item.action)+' · '+escapeHtml(item.date)+'</strong><small>By '+escapeHtml(item.admin)+(item.reason?' · '+escapeHtml(item.reason):'')+(item.note?' · '+escapeHtml(item.note):'')+(item.until?' · Until '+escapeHtml(item.until):'')+'</small></div>').join('') : '<p class="history-empty">No account status history yet.</p>';
            const actions = document.getElementById('drawerActions'); actions.innerHTML = '';
            if (user.can_manage) {
                if (user.status === 'Suspended' || user.status === 'Deactivated') actions.append(makeDrawerAction('Reactivate', 'reactivate', user.id));
                else { actions.append(makeDrawerAction('Suspend', 'suspend', user.id)); actions.append(makeDrawerAction('Deactivate', 'deactivate', user.id)); }
            }
            drawer.hidden = false; drawerBackdrop.hidden = false; document.body.style.overflow = 'hidden';
            drawer.querySelector('[data-close-drawer]').focus();
        }
        function makeDrawerAction(label, action, id) { const button = document.createElement('button'); button.type='button'; button.className='view-user'; button.textContent=label; button.dataset.userAction=action; button.dataset.userId=id; if(action==='deactivate') button.classList.add('danger-action'); button.addEventListener('click',()=>openActionModal(action,id)); return button; }
        function closeDrawer() { drawer.hidden=true; drawerBackdrop.hidden=true; document.body.style.overflow=''; }
        function openActionModal(action, id) {
            if (!activeDrawerUser || Number(activeDrawerUser.id) !== Number(id)) openUserDrawer(id);
            const user = adminUserDetails[id]; if (!user?.can_manage) return;
            const forms = {suspend: document.getElementById('suspendForm'), deactivate: document.getElementById('deactivateForm'), reactivate: document.getElementById('reactivateForm')};
            Object.values(forms).forEach(form => form.hidden = true);
            const modalTitle = document.getElementById('actionModalTitle'); const description = document.getElementById('actionModalDescription');
            const base = '/admin/users/' + encodeURIComponent(id) + '/';
            if (action === 'suspend') { modalTitle.textContent='Suspend '+user.name+'?'; description.textContent='They will be signed out and receive an email with the reason and message.'; forms.suspend.action=base+'suspend'; forms.suspend.hidden=false; }
            if (action === 'deactivate') { modalTitle.textContent='Deactivate '+user.name+'?'; description.textContent='This closes account access. Existing orders will remain open.'; forms.deactivate.action=base+'deactivate'; forms.deactivate.hidden=false; document.getElementById('deactivateConfirmation').value=''; document.getElementById('deactivateSubmit').disabled=true; }
            if (action === 'reactivate') { modalTitle.textContent='Reactivate '+user.name+'?'; description.textContent='Restore this user’s marketplace account access.'; forms.reactivate.action=base+'reactivate'; forms.reactivate.hidden=false; }
            closeDrawer(); actionBackdrop.hidden=false;
            actionBackdrop.querySelector('form:not([hidden]) button[type="submit"]')?.focus();
        }
        document.querySelectorAll('[data-user-row]').forEach(row => {
            row.addEventListener('click', event => { if (event.target.closest('button,details,a,form')) return; openUserDrawer(row.dataset.userRow); });
            row.addEventListener('keydown', event => { if ((event.key==='Enter'||event.key===' ') && !event.target.closest('button,details')) { event.preventDefault(); openUserDrawer(row.dataset.userRow); } });
        });
        document.querySelectorAll('[data-open-user]').forEach(button => button.addEventListener('click', () => openUserDrawer(button.dataset.openUser)));
        document.querySelectorAll('[data-user-action]').forEach(button => button.addEventListener('click', event => { event.stopPropagation(); openActionModal(button.dataset.userAction, button.dataset.userId); }));
        document.querySelectorAll('[data-copy-email]').forEach(button => button.addEventListener('click', async () => { try { await navigator.clipboard.writeText(button.dataset.copyEmail); button.textContent='Copied'; setTimeout(()=>button.textContent='Copy email',1200); } catch { window.prompt('Copy this email address', button.dataset.copyEmail); } }));
        document.querySelectorAll('[data-close-drawer]').forEach(button=>button.addEventListener('click',closeDrawer)); drawerBackdrop.addEventListener('click',closeDrawer);
        document.querySelectorAll('[data-close-modal]').forEach(button=>button.addEventListener('click',()=>actionBackdrop.hidden=true)); actionBackdrop.addEventListener('click',event=>{if(event.target===actionBackdrop)actionBackdrop.hidden=true;});
        document.getElementById('deactivateConfirmation').addEventListener('input', event=>{document.getElementById('deactivateSubmit').disabled=event.target.value!=='DEACTIVATE';});
        document.addEventListener('keydown',event=>{if(event.key==='Escape'){if(!actionBackdrop.hidden)actionBackdrop.hidden=true;else if(!drawer.hidden)closeDrawer();}});
        const requestedUserId = new URLSearchParams(window.location.search).get('user'); if (requestedUserId && adminUserDetails[requestedUserId]) openUserDrawer(requestedUserId);
    </script>
</x-admin-layout>
