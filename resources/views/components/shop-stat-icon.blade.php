@props(['name' => 'star'])

<span {{ $attributes->merge(['class' => 'shop-stat-icon']) }} aria-hidden="true">
    @switch($name)
        @case('package')
            <svg class="shop-stat-icon-svg" viewBox="0 0 24 24" width="18" height="18" fill="none" aria-hidden="true" focusable="false">
                <path d="m21 8-9-5-9 5 9 5 9-5Z" />
                <path d="M3 8v8l9 5 9-5V8" />
                <path d="M12 13v8" />
            </svg>
            @break

        @case('bag')
            <svg class="shop-stat-icon-svg" viewBox="0 0 24 24" width="18" height="18" fill="none" aria-hidden="true" focusable="false">
                <path d="M6 8h12l-1 12H7L6 8Z" />
                <path d="M9 8a3 3 0 0 1 6 0" />
            </svg>
            @break

        @case('calendar')
            <svg class="shop-stat-icon-svg" viewBox="0 0 24 24" width="18" height="18" fill="none" aria-hidden="true" focusable="false">
                <path d="M8 2v4" />
                <path d="M16 2v4" />
                <path d="M4 9h16" />
                <path d="M5 5h14v16H5z" />
            </svg>
            @break

        @default
            <svg class="shop-stat-icon-svg" viewBox="0 0 24 24" width="18" height="18" fill="none" aria-hidden="true" focusable="false">
                <path d="m12 3 2.8 5.7 6.2.9-4.5 4.4 1.1 6.2-5.6-2.9-5.6 2.9 1.1-6.2L3 9.6l6.2-.9L12 3Z" />
            </svg>
    @endswitch
</span>
