<x-admin-layout title="Users">
    <div class="panel">
        <h2>All Users</h2>
        <table>
            <thead>
                <tr><th>Name</th><th>Email</th><th>Role</th><th>Status</th><th>Joined</th></tr>
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
                        <span class="badge" style="background:{{ match($u->status) { 'active' => '#5C7355', 'banned' => '#B85C3B', default => '#8B7A80' } }}">
                            {{ ucfirst($u->status) }}
                        </span>
                    </td>
                    <td>{{ \Carbon\Carbon::parse($u->created_at)->format('M d, Y') }}</td>
                </tr>
                @empty
                <tr><td colspan="5" style="text-align:center;color:#999;padding:20px;">No users found.</td></tr>
                @endforelse
            </tbody>
        </table>
    </div>
</x-admin-layout>
