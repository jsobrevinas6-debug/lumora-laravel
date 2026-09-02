@php
    $nodes = $nodes ?? [];
    $activeCategory = $activeCategory ?? '';
    $categoryCounts = $categoryCounts ?? [];
    $isBranchActive = function (array $node) use (&$isBranchActive, $activeCategory): bool {
        if (($node['slug'] ?? '') === $activeCategory) return true;
        foreach (($node['children'] ?? []) as $child) {
            if ($isBranchActive($child)) return true;
        }
        return false;
    };
@endphp

@foreach ($nodes as $node)
    @php
        $children = $node['children'] ?? [];
        $hasChildren = count($children) > 0;
        $branchActive = $isBranchActive($node);
        $isLeafActive = ($node['slug'] ?? '') === $activeCategory;
        $countFor = function (array $item) use (&$countFor, $categoryCounts): int {
            if (!empty($item['children'])) {
                return collect($item['children'])->sum(fn ($child) => $countFor($child));
            }
            return (int) ($categoryCounts[$item['slug'] ?? ''] ?? 0);
        };
        $nodeCount = $countFor($node);
    @endphp

    @if ($hasChildren)
        <div class="category-sidebar-group {{ $branchActive ? 'is-active-branch' : '' }}" data-sidebar-group>
            <button type="button" class="category-sidebar-parent" data-sidebar-toggle aria-expanded="{{ $branchActive ? 'true' : 'false' }}">
                <span>{{ $node['label'] }}</span>
                <span class="category-sidebar-chevron" aria-hidden="true">⌄</span>
                @if ($nodeCount > 0)<span class="category-sidebar-count">{{ $nodeCount }}</span>@endif
            </button>
            <div class="category-sidebar-children" data-sidebar-children>
                @include('components.category-sidebar-node', ['nodes' => $children, 'activeCategory' => $activeCategory, 'categoryCounts' => $categoryCounts])
            </div>
        </div>
    @else
        <a class="category-sidebar-leaf {{ $isLeafActive ? 'is-current' : '' }}" href="{{ route('shop.index', ['category' => $node['slug']]) }}" @if ($isLeafActive) aria-current="page" @endif>
            <span>{{ $node['label'] }}</span>
            @if ($nodeCount > 0)<span class="category-sidebar-count">{{ $nodeCount }}</span>@endif
        </a>
    @endif
@endforeach
