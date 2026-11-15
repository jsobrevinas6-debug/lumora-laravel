@php
    $leaves = \App\Support\CategoryCatalog::leafSlugsFor($node['slug']);
    $count = collect($leaves)->sum(fn($slug) => (int)($counts[$slug] ?? 0));
    $selectedBranch = in_array($active, $leaves, true) || $active === $node['slug'];
    $hasChildren = ! empty($node['children']);
@endphp
<div class="cat-group {{ $selectedBranch?'open':'' }}" data-category-group>
    <div class="cat-row" style="padding-left:{{ 14 + $depth*13 }}px">
        <a class="cat-parent {{ $active===$node['slug']?'active':'' }} {{ $count===0?'dim':'' }}" href="{{ route('shop.index', ['category'=>$node['slug']]) }}">
            {{ $node['label'] }}
        </a>
        <div class="cat-row-actions">
            <span class="cat-count">{{ $count }}</span>
            @if($hasChildren)
                <button class="cat-chevron" type="button" data-category-toggle aria-label="Toggle {{ $node['label'] }} subcategories" aria-expanded="{{ $selectedBranch?'true':'false' }}"><svg viewBox="0 0 24 24" aria-hidden="true"><path d="m6 9 6 6 6-6"/></svg></button>
            @endif
        </div>
    </div>
    @if($hasChildren)<div class="cat-children">
        @foreach($node['children'] as $child)
            @include('components.shop-category-node', ['node'=>$child,'counts'=>$counts,'active'=>$active,'depth'=>$depth+1])
        @endforeach
    </div>@endif
</div>
