<x-buyer-profile.section-card title="Security" id="account-settings" class="profile-scroll-section" data-profile-section>
    <form method="post" action="{{ route('password.update') }}">
        @csrf
        @method('put')

        <div class="profile-grid">
            <x-buyer-profile.field label="Current Password" for="update_password_current_password" :error="$errors->updatePassword->get('current_password')[0] ?? null">
                <input id="update_password_current_password" name="current_password" type="password" class="profile-input" autocomplete="current-password">
            </x-buyer-profile.field>

            <x-buyer-profile.field label="New Password" for="update_password_password" :error="$errors->updatePassword->get('password')[0] ?? null">
                <input id="update_password_password" name="password" type="password" class="profile-input" autocomplete="new-password">
            </x-buyer-profile.field>

            <x-buyer-profile.field label="Confirm Password" for="update_password_password_confirmation" :error="$errors->updatePassword->get('password_confirmation')[0] ?? null">
                <input id="update_password_password_confirmation" name="password_confirmation" type="password" class="profile-input" autocomplete="new-password">
            </x-buyer-profile.field>
        </div>

        <div class="password-actions">
            @if (session('status') === 'password-updated')
                <span class="saved-message">Saved.</span>
            @endif

            <button type="submit" class="btn-primary">
                <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" aria-hidden="true"><rect x="3" y="11" width="18" height="11" rx="2"/><path d="M7 11V7a5 5 0 0 1 10 0v4"/></svg>
                Change Password
            </button>
        </div>
    </form>
</x-buyer-profile.section-card>
