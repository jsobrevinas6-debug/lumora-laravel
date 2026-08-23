<x-admin-layout title="Users">
    <div class="panel">
        <h2>All Users</h2>

        @if(session('flash_success'))
            <div style="background:#5C7355;color:#fff;padding:10px 14px;border-radius:6px;margin-bottom:16px;">
                {{ session('flash_success') }}
            </div>
        @endif

        <table>
            <thead>
                <tr><th>Name</th><th>Email</th><th>Role</th><th>Status</th><th>Joined</th><th>Actions</th></tr>
            </thead>
            <tbody>
                @forelse ($users as $u)
                <tr>
                    <td>{{ $u->name }}</td>
                    <td>{{ $u->email }}</td>
                    <td>
                        <span class="badge" style="background:{{ match($u->role) { 'admin' => '#5B1A35', 'seller' => '#5C7355', default => '#D98A5E' } }}">
                            {{ ucfirst($u->role) }}
                        </span>
                    </td>
                    <td>
                        <span class="badge" style="background:{{ match($u->status) { 'active' => '#5C7355', 'suspended' => '#D9A94E', 'deactivated' => '#B85C3B', default => '#8B7A80' } }}">
                            {{ ucfirst($u->status) }}
                        </span>
                    </td>
                    <td>{{ \Carbon\Carbon::parse($u->created_at)->format('M d, Y') }}</td>
                    <td>
                        <button type="button" class="btn-link" onclick="openProfileModal({{ $u->id }})">View</button>

                        <div id="profile-data-{{ $u->id }}" style="display:none;">
                            <p><strong>Name:</strong> {{ $u->first_name }} {{ $u->last_name }}</p>
                            <p><strong>Email:</strong> {{ $u->email }} {{ $u->email_verified ? '(verified)' : '(not verified)' }}</p>
                            <p><strong>Contact:</strong> {{ $u->contact_number ?? '—' }}</p>
                            <p><strong>Date of Birth:</strong> {{ $u->date_of_birth ? \Carbon\Carbon::parse($u->date_of_birth)->format('M d, Y') : '—' }}</p>
                            @if($u->role === 'seller')
                                <p><strong>Shop Name:</strong> {{ $u->shop_name ?? '—' }}</p>
                                <p><strong>Shop Description:</strong> {{ $u->shop_description ?? '—' }}</p>
                            @endif
                            <p><strong>Role:</strong> {{ ucfirst($u->role) }}</p>
                            <p><strong>Status:</strong> {{ ucfirst($u->status) }}</p>
                            <p><strong>Joined:</strong> {{ \Carbon\Carbon::parse($u->created_at)->format('M d, Y') }}</p>
                        </div>

                        @if($u->status !== 'active')
                            <a href="{{ route('admin.users.action', [$u->id, 'activate']) }}"
                               class="btn-link"
                               style="color:#5C7355;"
                               onclick="return confirm('Activate this account?')">Activate</a>
                        @endif

                        @if($u->status !== 'suspended')
                            <a href="{{ route('admin.users.action', [$u->id, 'suspend']) }}"
                               class="btn-link"
                               style="color:#D9A94E;"
                               onclick="return confirm('Suspend this account?')">Suspend</a>
                        @endif

                        @if($u->status !== 'deactivated')
                            <a href="{{ route('admin.users.action', [$u->id, 'deactivate']) }}"
                               class="btn-link"
                               style="color:#B85C3B;"
                               onclick="return confirm('Deactivate this account?')">Deactivate</a>
                        @endif
                    </td>
                </tr>
                @empty
                <tr><td colspan="6" style="text-align:center;color:#999;padding:20px;">No users found.</td></tr>
                @endforelse
            </tbody>
        </table>
    </div>

    <!-- Profile Modal -->
    <div id="profile-modal-overlay" style="display:none;position:fixed;inset:0;background:rgba(0,0,0,.5);z-index:999;">
        <div style="background:#fff;max-width:480px;margin:80px auto;padding:24px;border-radius:8px;position:relative;">
            <button type="button" onclick="closeProfileModal()" style="position:absolute;top:12px;right:16px;background:none;border:none;font-size:20px;cursor:pointer;">&times;</button>
            <h3 style="margin-top:0;">User Profile</h3>
            <div id="profile-modal-content"></div>
        </div>
    </div>

    <style>
        .btn-link {
            background: none;
            border: none;
            padding: 4px 6px;
            margin-right: 4px;
            cursor: pointer;
            font-size: 13px;
            text-decoration: underline;
            color: #5B1A35;
        }
    </style>

    <script>
        function openProfileModal(id) {
            const src = document.getElementById('profile-data-' + id);
            document.getElementById('profile-modal-content').innerHTML = src.innerHTML;
            document.getElementById('profile-modal-overlay').style.display = 'block';
        }
        function closeProfileModal() {
            document.getElementById('profile-modal-overlay').style.display = 'none';
        }
    </script>
</x-admin-layout>