@props([
    'href' => '#',
    'active' => false,
    'label',
])

<a
    href="{{ $href }}"
    {{ $attributes->class(['profile-nav-item', 'active' => $active]) }}
    data-profile-nav-item
    @if ($active) aria-current="page" @endif
>
    <span class="profile-nav-icon" aria-hidden="true">{{ $icon ?? '' }}</span>
    <span class="profile-nav-label">{{ $label }}</span>
</a>
