@props([
    'title',
    'description' => null,
])

<section {{ $attributes->class('profile-section-card') }}>
    <div class="section-card-head">
        <h2>{{ $title }}</h2>
        @if ($description)
            <p>{{ $description }}</p>
        @endif
    </div>

    {{ $slot }}
</section>
