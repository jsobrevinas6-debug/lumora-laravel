@props([
    'node',
    'level' => 0,
    'categoryCounts' => [],
    'shopProducts' => collect(),
])

@php
    $children = $node['children'] ?? [];
    $hasChildren = count($children) > 0;
    $hasImage = !empty($node['image']);
    $countFor = function (string $slug) use ($categoryCounts, $shopProducts): int {
        return (int) ($categoryCounts[$slug] ?? $shopProducts->where('category', $slug)->count());
    };

    $sumTree = function (array $items) use (&$sumTree, $countFor): int {
        return collect($items)->sum(function ($item) use (&$sumTree, $countFor) {
            return !empty($item['children'])
                ? $sumTree($item['children'])
                : $countFor($item['slug']);
        });
    };

    $nodeCount = $hasChildren ? $sumTree($children) : $countFor($node['slug']);
    $slug = $node['slug'] ?? 'category';
    $label = $node['label'] ?? 'Category';
@endphp

@php
    $icon = match (true) {
        $slug === 'men' => '<path d="M8 5 5 7l-2 4 4 2v8h10v-8l-2-4-3-2a4 4 0 0 1-8 0Z"/>',
        $slug === 'women' => '<path d="M9 3h6l2 5-2 2v8h-6v-8L7 8l2-5Z"/><path d="M12 18v3M9 21h6"/>',
        $slug === 'electronics' => '<rect x="4" y="5" width="16" height="12" rx="2"/><path d="M8 21h8M12 17v4"/>',
        $slug === 'home-living' => '<path d="m4 11 8-7 8 7v9H4v-9Z"/><path d="M9 20v-6h6v6"/>',
        $slug === 'sports-outdoors' => '<circle cx="12" cy="12" r="8"/><path d="M4.5 9.5h15M4.5 14.5h15M12 4v16"/>',
        $slug === 'beauty-personal-care' => '<path d="M10 3h4v5h-4zM9 8h6v11a2 2 0 0 1-2 2h-2a2 2 0 0 1-2-2V8Z"/>',
        default => '<path d="M4 7h16M6 4h12l2 3H4l2-3ZM5 7v13h14V7"/><path d="M9 11h6"/>',
    };
@endphp

@if ($hasChildren)
    <div class="flow-menu-group {{ $level > 0 ? 'flow-menu-nested-group' : '' }}" data-submenu-group>
        <button type="button" class="flow-menu-item flow-menu-parent" data-submenu-toggle aria-expanded="false">
            <span class="flow-menu-item-left">
                <span class="flow-menu-item-icon" aria-hidden="true">
                    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5">{!! $icon !!}</svg>
                </span>
                <span class="flow-menu-item-label">{{ $label }}</span>
            </span>
            <span class="flow-menu-item-right">
                @if ($nodeCount > 0)<span class="flow-menu-badge">{{ $nodeCount }}</span>@endif
                <span class="flow-menu-chevron" aria-hidden="true">⌄</span>
            </span>
        </button>
        <div class="flow-menu-submenu" data-submenu>
            @foreach ($children as $child)
                <x-flow-menu-node :node="$child" :level="$level + 1" :category-counts="$categoryCounts" :shop-products="$shopProducts" />
            @endforeach
        </div>
    </div>
@else
    <div class="flowing-menu-leaf" data-flowing-item>
        <a
            class="flow-menu-subitem flow-menu-subitem-leaf {{ $hasImage ? 'has-image' : '' }}"
            href="{{ route('shop.index', ['category' => $slug]) }}"
            data-flowing-link
            data-category-label="{{ $label }}"
            @if ($hasImage) style="--category-image: url('{{ asset($node['image']) }}')" @endif
        >
            <span class="flow-menu-subitem-label">{{ $label }}</span>
            @if ($nodeCount > 0)<span class="flow-menu-badge">{{ $nodeCount }}</span>@endif
            <span class="flow-menu-arrow" aria-hidden="true">&rarr;</span>
        </a>
        <div class="flowing-marquee" data-flowing-marquee aria-hidden="true">
            <div class="flowing-marquee-inner" data-flowing-marquee-inner>
                @for ($i = 0; $i < 5; $i++)
                    <div class="flowing-marquee-part">
                        <span>{{ $label }}</span>
                        @if ($hasImage)
                            <span class="flowing-marquee-image" style="background-image:url('{{ asset($node['image']) }}')"></span>
                        @else
                            <span class="flowing-marquee-dot"></span>
                        @endif
                    </div>
                @endfor
            </div>
        </div>
    </div>
@endif
