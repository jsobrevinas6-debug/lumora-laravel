@php
    $leaves = \App\Support\CategoryCatalog::leafSlugsFor($node['slug']);
    $count = collect($leaves)->sum(fn($slug) => (int)($counts[$slug] ?? 0));
    $selectedBranch = in_array($active, $leaves, true) || $active === $node['slug'];
    $hasChildren = ! empty($node['children']);
@endphp
<div class="cat-group {{ $selectedBranch?'open':'' }}" data-category-group>
    <div class="cat-row">
        <a class="cat-parent {{ $active===$node['slug']?'active':'' }} {{ $count===0?'dim':'' }}" href="{{ route('shop.index', ['category'=>$node['slug']]) }}" style="padding-left:{{ 14 + $depth*13 }}px">
            {{ $node['label'] }} <span class="cat-count">{{ $count }}</span>
        </a>
        @if($hasChildren)<button class="cat-chevron" type="button" data-category-toggle aria-label="Toggle {{ $node['label'] }} subcategories" aria-expanded="{{ $selectedBranch?'true':'false' }}">⌄</button>@endif
    </div>
    @if($hasChildren)<div class="cat-children">
        @foreach($node['children'] as $child)
            @include('components.shop-category-node', ['node'=>$child,'counts'=>$counts,'active'=>$active,'depth'=>$depth+1])
        @endforeach
    </div>@endif
</div>
