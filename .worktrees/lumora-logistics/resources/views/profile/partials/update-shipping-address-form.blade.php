<form method="post" action="{{ route('profile.address.update') }}" id="shipping-address-form" class="profile-form-stack">
    @csrf
    @method('patch')

    <x-buyer-profile.section-card
        title="Shipping Address"
        description="Manage where your LUMORA orders will be delivered."
        id="shipping-address"
        class="profile-scroll-section"
        data-profile-section
    >
        <div class="profile-grid address-grid">
            <x-buyer-profile.field label="Province" for="province" :error="$errors->addressUpdate->get('province')[0] ?? null">
                <select id="province" name="province" class="profile-select">
                    <option value="">Loading provinces...</option>
                </select>
            </x-buyer-profile.field>

            <x-buyer-profile.field label="Municipality" for="municipality" :error="$errors->addressUpdate->get('municipality')[0] ?? null">
                <select id="municipality" name="municipality" class="profile-select" disabled>
                    <option value="">Select province first</option>
                </select>
            </x-buyer-profile.field>

            <x-buyer-profile.field label="Barangay" for="barangay" :error="$errors->addressUpdate->get('barangay')[0] ?? null">
                <select id="barangay" name="barangay" class="profile-select" disabled>
                    <option value="">Select municipality first</option>
                </select>
            </x-buyer-profile.field>

            <x-buyer-profile.field label="Street" for="street" :error="$errors->addressUpdate->get('street')[0] ?? null">
                <input id="street" name="street" type="text" class="profile-input" value="{{ old('street', $user->street) }}" autocomplete="address-line1">
            </x-buyer-profile.field>

            <x-buyer-profile.field label="House / Unit No." for="house_number" :error="$errors->addressUpdate->get('house_number')[0] ?? null">
                <input id="house_number" name="house_number" type="text" class="profile-input" value="{{ old('house_number', $user->house_number) }}" autocomplete="address-line2">
            </x-buyer-profile.field>
        </div>

        <div class="form-footer">
            @if (session('status') === 'address-updated')
                <span class="saved-message">Shipping address saved.</span>
            @endif
            <button type="submit" class="btn-primary">
                <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" aria-hidden="true"><path d="M19 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h11l5 5v11a2 2 0 0 1-2 2Z"/><path d="M17 21v-8H7v8"/><path d="M7 3v5h8"/></svg>
                Save Shipping Address
            </button>
        </div>
    </x-buyer-profile.section-card>
</form>

<script>
document.addEventListener('DOMContentLoaded', function () {
    const province = document.getElementById('province');
    const municipality = document.getElementById('municipality');
    const barangay = document.getElementById('barangay');
    const selectedProvince = @json(old('province', $user->province));
    const selectedMunicipality = @json(old('municipality', $user->municipality));
    const selectedBarangay = @json(old('barangay', $user->barangay));

    if (!province || !municipality || !barangay) return;

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
            await loadMunicipalities(selectedMunicipality);
        } catch (error) {
            console.error(error);
            province.innerHTML = '<option value="">Could not load provinces</option>';
        }
    }

    async function loadMunicipalities(selectedValue = '') {
        const option = province.options[province.selectedIndex];
        const code = option?.dataset.code;
        municipality.innerHTML = '<option value="">Select municipality</option>';
        barangay.innerHTML = '<option value="">Select barangay</option>';
        municipality.disabled = true;
        barangay.disabled = true;
        if (!code) return;
        try {
            const items = await getAddress('{{ url('/address/provinces') }}/' + encodeURIComponent(code) + '/municipalities');
            fillSelect(municipality, items, selectedValue, 'Select municipality');
            await loadBarangays(selectedBarangay);
        } catch (error) {
            console.error(error);
        }
    }

    async function loadBarangays(selectedValue = '') {
        const option = municipality.options[municipality.selectedIndex];
        const code = option?.dataset.code;
        barangay.innerHTML = '<option value="">Select barangay</option>';
        barangay.disabled = true;
        if (!code) return;
        try {
            const items = await getAddress('{{ url('/address/municipalities') }}/' + encodeURIComponent(code) + '/barangays');
            fillSelect(barangay, items, selectedValue, 'Select barangay');
        } catch (error) {
            console.error(error);
        }
    }

    province.addEventListener('change', () => loadMunicipalities());
    municipality.addEventListener('change', () => loadBarangays());

    loadProvinces();
});
</script>
