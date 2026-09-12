@php
    $birthDate = old('date_of_birth', optional($user->date_of_birth)->format('Y-m-d'));
    $selectedSex = old('sex', $user->sex);
@endphp

<form id="send-verification" method="post" action="{{ route('verification.send') }}">
    @csrf
</form>

<form method="post" action="{{ route('profile.update') }}" id="profile-information-form" class="profile-form-stack">
    @csrf
    @method('patch')

    <input type="hidden" name="name" id="profile_full_name" value="{{ old('name', $user->name) }}">

    <x-buyer-profile.section-card title="Personal Information" id="personal-information">
        <div class="profile-grid">
            <x-buyer-profile.field label="First Name" for="first_name" :error="$errors->get('first_name')[0] ?? null">
                <input id="first_name" name="first_name" type="text" class="profile-input" value="{{ old('first_name', $user->first_name) }}" required autocomplete="given-name" autofocus>
            </x-buyer-profile.field>

            <x-buyer-profile.field label="Last Name" for="last_name" :error="$errors->get('last_name')[0] ?? null">
                <input id="last_name" name="last_name" type="text" class="profile-input" value="{{ old('last_name', $user->last_name) }}" required autocomplete="family-name">
            </x-buyer-profile.field>

            <x-buyer-profile.field label="Middle Initial" for="middle_initial" :error="$errors->get('middle_initial')[0] ?? null">
                <input id="middle_initial" name="middle_initial" type="text" class="profile-input" value="{{ old('middle_initial', $user->middle_initial) }}" maxlength="4" autocomplete="additional-name">
            </x-buyer-profile.field>

            <x-buyer-profile.field label="Date of Birth" for="date_of_birth" :error="$errors->get('date_of_birth')[0] ?? null">
                <input id="date_of_birth" name="date_of_birth" type="date" class="profile-input" value="{{ $birthDate }}" required>
            </x-buyer-profile.field>

            <x-buyer-profile.field label="Gender" :error="$errors->get('sex')[0] ?? null">
                <div class="profile-radio-row" role="radiogroup" aria-label="Gender">
                    <label class="profile-radio">
                        <input type="radio" name="sex" value="female" @checked($selectedSex === 'female') required>
                        <span>Female</span>
                    </label>
                    <label class="profile-radio">
                        <input type="radio" name="sex" value="male" @checked($selectedSex === 'male')>
                        <span>Male</span>
                    </label>
                </div>
            </x-buyer-profile.field>

            <x-buyer-profile.field label="Age" for="profile_age">
                <input id="profile_age" type="text" class="profile-input" value="{{ $birthDate ? \Carbon\Carbon::parse($birthDate)->age : '' }}" readonly>
            </x-buyer-profile.field>
        </div>
    </x-buyer-profile.section-card>

    <x-buyer-profile.section-card title="Contact Information" id="contact-information">
        <div class="contact-row">
            <x-buyer-profile.field label="Email" for="email" :error="$errors->get('email')[0] ?? null">
                <input id="email" name="email" type="email" class="profile-input" value="{{ old('email', $user->email) }}" required autocomplete="username">

                @if ($isGoogleAccount ?? false)
                    <span class="google-badge">
                        <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.3" aria-hidden="true"><path d="M20 6 9 17l-5-5"/></svg>
                        Verified by Google
                    </span>
                @elseif ($user instanceof \Illuminate\Contracts\Auth\MustVerifyEmail && ! $user->hasVerifiedEmail())
                    <p class="email-note">
                        Your email address is unverified.
                        <button form="send-verification">Resend verification email</button>
                    </p>
                @endif

                @if (session('status') === 'verification-link-sent')
                    <p class="email-note">A new verification link has been sent to your email address.</p>
                @endif
            </x-buyer-profile.field>

            <x-buyer-profile.field label="Phone Number" for="contact_number" :error="$errors->get('contact_number')[0] ?? null">
                <input id="contact_number" name="contact_number" type="tel" class="profile-input" value="{{ old('contact_number', $user->contact_number) }}" required autocomplete="tel">
            </x-buyer-profile.field>
        </div>
    </x-buyer-profile.section-card>

    <x-buyer-profile.section-card title="Shipping Address" id="shipping-address" class="profile-scroll-section" data-profile-section>
        <div class="profile-grid address-grid">
            <x-buyer-profile.field label="Province" for="province" :error="$errors->get('province')[0] ?? null">
                <select id="province" name="province" class="profile-select" required>
                    <option value="">Loading provinces...</option>
                </select>
            </x-buyer-profile.field>

            <x-buyer-profile.field label="Municipality" for="municipality" :error="$errors->get('municipality')[0] ?? null">
                <select id="municipality" name="municipality" class="profile-select" required disabled>
                    <option value="">Select province first</option>
                </select>
            </x-buyer-profile.field>

            <x-buyer-profile.field label="Barangay" for="barangay" :error="$errors->get('barangay')[0] ?? null">
                <select id="barangay" name="barangay" class="profile-select" required disabled>
                    <option value="">Select municipality first</option>
                </select>
            </x-buyer-profile.field>

            <x-buyer-profile.field label="Street" for="street" :error="$errors->get('street')[0] ?? null">
                <input id="street" name="street" type="text" class="profile-input" value="{{ old('street', $user->street) }}" autocomplete="address-line1">
            </x-buyer-profile.field>

            <x-buyer-profile.field label="House / Unit" for="house_number" :error="$errors->get('house_number')[0] ?? null">
                <input id="house_number" name="house_number" type="text" class="profile-input" value="{{ old('house_number', $user->house_number) }}" autocomplete="address-line2">
            </x-buyer-profile.field>
        </div>

        <div class="form-footer">
            @if (session('status') === 'profile-updated')
                <span class="saved-message">Saved.</span>
            @endif
            <button type="submit" class="btn-primary">
                <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" aria-hidden="true"><path d="M19 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h11l5 5v11a2 2 0 0 1-2 2Z"/><path d="M17 21v-8H7v8"/><path d="M7 3v5h8"/></svg>
                Save Changes
            </button>
        </div>
    </x-buyer-profile.section-card>
</form>

<script>
document.addEventListener('DOMContentLoaded', function () {
    const firstName = document.getElementById('first_name');
    const lastName = document.getElementById('last_name');
    const fullName = document.getElementById('profile_full_name');
    const birthDate = document.getElementById('date_of_birth');
    const age = document.getElementById('profile_age');
    const province = document.getElementById('province');
    const municipality = document.getElementById('municipality');
    const barangay = document.getElementById('barangay');
    const selectedProvince = @json(old('province', $user->province));
    const selectedMunicipality = @json(old('municipality', $user->municipality));
    const selectedBarangay = @json(old('barangay', $user->barangay));

    function syncFullName() {
        const name = [firstName?.value, lastName?.value].filter(Boolean).join(' ').trim();
        if (fullName && name) fullName.value = name;
    }

    function syncAge() {
        if (!birthDate?.value || !age) return;
        const birth = new Date(birthDate.value);
        const today = new Date();
        let years = today.getFullYear() - birth.getFullYear();
        const month = today.getMonth() - birth.getMonth();
        if (month < 0 || (month === 0 && today.getDate() < birth.getDate())) years--;
        age.value = Number.isFinite(years) && years >= 0 ? years : '';
    }

    function itemName(item) { return item.name ?? item.label ?? item.description ?? ''; }
    function itemCode(item) { return item.code ?? item.id ?? item.key ?? ''; }

    function fillSelect(select, items, selectedValue, placeholder) {
        select.innerHTML = '';
        select.add(new Option(placeholder, ''));
        items.forEach(function (item) {
            const name = itemName(item);
            const option = new Option(name, name, false, name === selectedValue);
            option.dataset.code = itemCode(item);
            select.add(option);
        });
        select.disabled = items.length === 0;
    }

    async function getAddress(url) {
        const response = await fetch(url, { headers: { 'Accept': 'application/json' } });
        if (!response.ok) throw new Error('Address request failed: ' + response.status);
        const payload = await response.json();
        const items = Array.isArray(payload) ? payload : payload.data;
        if (!Array.isArray(items)) throw new Error('Invalid address response.');
        return items;
    }

    async function loadProvinces() {
        try {
            const items = await getAddress('{{ url('/address/provinces') }}');
            fillSelect(province, items, selectedProvince, 'Select province');
            await loadMunicipalities();
        } catch (error) {
            console.error(error);
            province.innerHTML = '<option value="">Could not load provinces</option>';
        }
    }

    async function loadMunicipalities() {
        const option = province.options[province.selectedIndex];
        const code = option?.dataset.code;
        municipality.innerHTML = '<option value="">Select municipality</option>';
        barangay.innerHTML = '<option value="">Select barangay</option>';
        municipality.disabled = true;
        barangay.disabled = true;
        if (!code) return;
        try {
            const items = await getAddress('{{ url('/address/provinces') }}/' + encodeURIComponent(code) + '/municipalities');
            fillSelect(municipality, items, selectedMunicipality, 'Select municipality');
            await loadBarangays();
        } catch (error) {
            console.error(error);
        }
    }

    async function loadBarangays() {
        const option = municipality.options[municipality.selectedIndex];
        const code = option?.dataset.code;
        barangay.innerHTML = '<option value="">Select barangay</option>';
        barangay.disabled = true;
        if (!code) return;
        try {
            const items = await getAddress('{{ url('/address/municipalities') }}/' + encodeURIComponent(code) + '/barangays');
            fillSelect(barangay, items, selectedBarangay, 'Select barangay');
        } catch (error) {
            console.error(error);
        }
    }

    firstName?.addEventListener('input', syncFullName);
    lastName?.addEventListener('input', syncFullName);
    birthDate?.addEventListener('change', syncAge);
    province?.addEventListener('change', loadMunicipalities);
    municipality?.addEventListener('change', loadBarangays);

    syncFullName();
    syncAge();
    loadProvinces();
});
</script>
