<x-admin-layout title="Seller Applications">
    <div class="panel">
        <h2>All Seller Applications</h2>
        <table>
            <thead>
                <tr><th>Applicant</th><th>Email</th><th>Status</th><th>Applied</th><th></th></tr>
            </thead>
            <tbody>
                @forelse ($applications as $a)
                <tr>
                    <td>{{ $a->name }}</td>
                    <td>{{ $a->email }}</td>
                    <td>
                        <span class="badge" style="background:{{ match($a->status) { 'approved' => '#5C7355', 'rejected' => '#B85C3B', 'archived' => '#8B7A80', default => '#5B1A35' } }}">
                            {{ ucfirst($a->status) }}
                        </span>
                    </td>
                    <td>{{ \Carbon\Carbon::parse($a->created_at)->format('M d, Y') }}</td>
                    <td style="text-align:right; white-space:nowrap;">
                        @if($a->status === 'pending')
                            <a href="{{ route('admin.application', [$a->id, 'approve']) }}" class="btn btn-dark" onclick="return confirm('Approve this application?')">Approve</a>
                            <a href="{{ route('admin.application', [$a->id, 'reject']) }}" class="btn btn-danger" onclick="return confirm('Reject?')">Reject</a>
                            <a href="{{ route('admin.application', [$a->id, 'archive']) }}" class="btn btn-outline">Archive</a>
                        @endif
                    </td>
                </tr>
                @empty
                <tr><td colspan="5" style="text-align:center;color:#999;padding:20px;">No applications found.</td></tr>
                @endforelse
            </tbody>
        </table>
    </div>
</x-admin-layout>
