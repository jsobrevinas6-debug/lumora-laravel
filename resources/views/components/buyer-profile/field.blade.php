@props([
    'label',
    'for' => null,
    'error' => null,
])

<div {{ $attributes->class('profile-field') }}>
    <label @if ($for) for="{{ $for }}" @endif>{{ $label }}</label>
    {{ $slot }}
    @if ($error)
        <small class="profile-field-error">{{ $error }}</small>
    @endif
</div>
