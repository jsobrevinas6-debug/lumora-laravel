<x-admin-layout :title="'Platform Settings'">

    <div style="display:grid; grid-template-columns:1fr 1fr; gap:22px; align-items:start;">

        {{-- Announcements --}}
        <div class="panel" style="margin-bottom:0;">
            <div style="display:flex; justify-content:space-between; align-items:center; margin-bottom:16px;">
                <h2 style="margin:0;">Announcements</h2>
                <button type="button" class="btn btn-dark" onclick="document.getElementById('newAnnouncementModal').style.display='flex'">+ New</button>
            </div>

            @forelse ($announcements as $a)
                <div style="border:1px solid var(--border); border-radius:12px; padding:14px 16px; margin-bottom:10px;">
                    <div style="display:flex; justify-content:space-between; align-items:start; margin-bottom:6px;">
                        <strong style="font-size:14.5px;">{{ $a->title }}</strong>
                        <span class="muted-badge">{{ ucfirst($a->audience) }}</span>
                    </div>
                    <p style="font-size:13px; color:var(--text-muted); margin-bottom:8px; line-height:1.5;">{{ Str::limit($a->body, 140) }}</p>
                    <div style="display:flex; justify-content:space-between; align-items:center;">
                        <span style="font-size:12px; color:var(--text-muted);">{{ \Carbon\Carbon::parse($a->created_at)->format('M d, Y') }} &middot; {{ $a->is_published ? 'Published' : 'Unpublished' }}</span>
                        <form action="{{ route('admin.settings.announcements.toggle', $a->id) }}" method="POST">
                            @csrf
                            @method('PATCH')
                            <button type="submit" class="btn btn-outline" style="font-size:.78rem;">{{ $a->is_published ? 'Unpublish' : 'Publish' }}</button>
                        </form>
                    </div>
                </div>
            @empty
                <p style="color:var(--text-muted); font-size:13.5px;">No announcements yet.</p>
            @endforelse
        </div>

        {{-- Platform Policies --}}
        <div class="panel" style="margin-bottom:0;">
            <h2>Platform Policies</h2>

            @foreach ($policies as $p)
                <div style="display:flex; justify-content:space-between; align-items:center; border:1px solid var(--border); border-radius:12px; padding:14px 16px; margin-bottom:10px;">
                    <div>
                        <strong style="font-size:14.5px;">{{ $p->title }}</strong>
                        <div style="font-size:12px; color:var(--text-muted); margin-top:3px;">
                            Version {{ $p->version }} &middot; updated {{ \Carbon\Carbon::parse($p->updated_at)->format('M d, Y') }}
                        </div>
                    </div>
                    <button type="button" class="btn btn-outline" onclick="openPolicyModal('{{ $p->id }}', {{ Js::from($p->title) }}, {{ Js::from($p->content) }})">Edit</button>
                </div>
            @endforeach
        </div>

    </div>

    {{-- New Announcement Modal --}}
    <div id="newAnnouncementModal" style="display:none; position:fixed; inset:0; background:rgba(43,28,34,.5); align-items:center; justify-content:center; z-index:50;">
        <div style="background:#fff; border-radius:18px; padding:28px; width:460px; max-width:90%;">
            <h2 style="font-size:18px; font-weight:800; margin-bottom:18px;">New Announcement</h2>
            <form action="{{ route('admin.settings.announcements.store') }}" method="POST" style="display:flex; flex-direction:column; gap:12px;">
                @csrf
                <input type="text" name="title" placeholder="Title" required style="border:1px solid var(--border); border-radius:8px; padding:10px 12px; font-size:14px; font-family:inherit;">
                <textarea name="body" placeholder="Announcement text" rows="5" required style="border:1px solid var(--border); border-radius:8px; padding:10px 12px; font-size:14px; font-family:inherit; resize:vertical;"></textarea>
                <select name="audience" required style="border:1px solid var(--border); border-radius:8px; padding:10px 12px; font-size:14px; font-family:inherit;">
                    <option value="all">All users</option>
                    <option value="sellers">Sellers only</option>
                    <option value="buyers">Buyers only</option>
                </select>
                <div style="display:flex; gap:10px; margin-top:6px;">
                    <button type="button" class="btn btn-outline" style="flex:1;" onclick="document.getElementById('newAnnouncementModal').style.display='none'">Cancel</button>
                    <button type="submit" class="btn btn-dark" style="flex:1;">Post</button>
                </div>
            </form>
        </div>
    </div>

    {{-- Edit Policy Modal --}}
    <div id="editPolicyModal" style="display:none; position:fixed; inset:0; background:rgba(43,28,34,.5); align-items:center; justify-content:center; z-index:50;">
        <div style="background:#fff; border-radius:18px; padding:28px; width:640px; max-width:92%;">
            <h2 id="policyModalTitle" style="font-size:18px; font-weight:800; margin-bottom:18px;">Edit Policy</h2>
            <form id="policyForm" method="POST" style="display:flex; flex-direction:column; gap:12px;">
                @csrf
                @method('PATCH')
                <textarea name="content" id="policyContent" rows="14" required style="border:1px solid var(--border); border-radius:8px; padding:10px 12px; font-size:13.5px; font-family:inherit; resize:vertical; line-height:1.6;"></textarea>
                <div style="display:flex; gap:10px; margin-top:6px;">
                    <button type="button" class="btn btn-outline" style="flex:1;" onclick="document.getElementById('editPolicyModal').style.display='none'">Cancel</button>
                    <button type="submit" class="btn btn-dark" style="flex:1;">Save (creates new version)</button>
                </div>
            </form>
        </div>
    </div>

    <script>
        function openPolicyModal(id, title, content) {
            document.getElementById('policyModalTitle').textContent = 'Edit ' + title;
            document.getElementById('policyContent').value = content;
            document.getElementById('policyForm').action = '/admin/settings/policies/' + id;
            document.getElementById('editPolicyModal').style.display = 'flex';
        }
    </script>

</x-admin-layout>