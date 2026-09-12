@props([
    'href' => route('home'),
])

<a
    href="{{ $href }}"
    {{ $attributes->merge([
        'aria-label' => 'Lumora Home',
        'class' => 'inline-flex shrink-0 flex-col items-start justify-center whitespace-nowrap font-serif text-[#2E1E2D] opacity-100 transition-opacity duration-300 hover:opacity-90',
    ]) }}
>
    <span class="block select-text whitespace-nowrap text-[24px] font-normal uppercase leading-none tracking-[0.32em] text-[#2E1E2D] md:text-[27px] lg:text-[31px]">
        LUM<span class="text-[#C97B63]">O</span>RA
    </span>
    <span class="mt-1 block select-text whitespace-nowrap text-[6px] font-medium uppercase leading-none tracking-[0.5em] text-[#8C7A7A] md:text-[7px] lg:text-[8px]">
        BEAUTY LIVES HERE
    </span>
</a>
