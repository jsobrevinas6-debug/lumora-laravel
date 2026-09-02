@extends('layouts.seller')

@section('title', 'My Products')

@section('content')
    @if (session('success'))
        <div class="alert-success">{{ session('success') }}</div>
    @endif

    <div style="display:flex;gap:8px;margin-bottom:16px;">
        <a href="{{ route('seller.products.index') }}" class="view-toggle-btn {{ $view === 'active' ? 'active' : '' }}">Active</a>
        <a href="{{ route('seller.products.index', ['view' => 'archived']) }}" class="view-toggle-btn {{ $view === 'archived' ? 'active' : '' }}">Archived</a>
    </div>

    <div class="products-grid">
        @if ($view === 'active')
            {{-- Add Product tile --}}
            <button type="button" class="add-product-tile" onclick="clearVariantRows('add'); document.getElementById('addProductModal').style.display='flex'" style="cursor:pointer; font-family:inherit;">
                <div class="add-icon">+</div>
                <div class="add-label">Add Product</div>
            </button>
        @endif

        @forelse ($products as $product)
            @php
                $hasDiscount = $product->discount_percent && $product->discount_percent > 0;
                $discountedPrice = $hasDiscount ? $product->price * (1 - $product->discount_percent / 100) : $product->price;
                $productVariants = $variants->get($product->id, collect());
            @endphp
            <div class="product-tile">
                <div class="product-image" style="position:relative;">
                    @if ($hasDiscount)
                        <span style="position:absolute;top:8px;left:8px;background:#B85C3B;color:#fff;font-size:11px;font-weight:700;padding:3px 8px;border-radius:20px;">{{ rtrim(rtrim(number_format($product->discount_percent, 1), '0'), '.') }}% OFF</span>
                    @endif
                    @if ($product->image)
                        <img src="{{ asset('storage/' . $product->image) }}" alt="{{ $product->name }}">
                    @else
                        No image
                    @endif
                </div>
                <div class="product-body">
                    <div class="product-name">{{ $product->name }}</div>
                    @if ($product->category)
                        <div style="font-size:.75rem;color:#8B7A80;margin-bottom:4px;">{{ $product->category }}</div>
                    @endif
                    <div class="product-price">
                        @if ($hasDiscount)
                            <span style="text-decoration:line-through;color:#A08D96;font-size:.85em;">₱{{ number_format($product->price, 2) }}</span>
                            ₱{{ number_format($discountedPrice, 2) }}
                        @else
                            ₱{{ number_format($product->price, 2) }}
                        @endif
                    </div>
                    <div class="product-stock">
                        Stock:
                        <span class="count {{ $product->stock <= 5 ? 'low' : '' }}">{{ $product->stock }}</span>
                        @if ($productVariants->isNotEmpty())
                            <span style="color:#8B7A80;font-weight:400;">&middot; {{ $productVariants->count() }} {{ Str::plural($product->variant_type ?: 'variant', $productVariants->count()) }}</span>
                        @endif
                    </div>

                    @if ($view === 'active')
                        <button type="button" class="edit-stock-btn" style="width:100%;margin-top:8px;"
                            onclick="openEditModal({{ $product->id }}, {{ json_encode($product->name) }}, {{ json_encode($product->category) }}, {{ json_encode($product->description) }}, {{ $product->price }}, {{ $product->discount_percent ?? 'null' }}, {{ $product->stock }}, {{ json_encode($product->variant_type) }}, {{ json_encode($productVariants->map(fn($v) => ['name' => $v->name, 'stock' => $v->stock])->values()) }})">
                            Edit Product
                        </button>
                    @else
                        <form action="{{ route('seller.products.restore', $product->id) }}" method="POST" style="margin-top:8px;">
                            @csrf
                            @method('PATCH')
                            <button type="submit" class="edit-stock-btn" style="width:100%;">Restore Product</button>
                        </form>
                    @endif
                </div>
            </div>
        @empty
            @if ($view === 'archived')
                <p style="color:#999;grid-column:1/-1;padding:20px 0;">No archived products.</p>
            @endif
        @endforelse
    </div>

    {{-- Add Product Modal --}}
    <div id="addProductModal" style="display:none; position:fixed; inset:0; background:rgba(43,28,34,.5); align-items:center; justify-content:center; z-index:50;">
        <div style="background:#fff; border-radius:18px; padding:28px; width:420px; max-width:90%;">
            <h2 style="font-size:18px; font-weight:800; margin-bottom:18px;">Add Product</h2>
            <form action="{{ route('seller.products.store') }}" method="POST" enctype="multipart/form-data" style="display:flex; flex-direction:column; gap:12px;">
                @csrf
                <input type="text" name="name" placeholder="Product name" required class="stock-input" style="width:100%;">
                <select name="category" required class="stock-input" style="width:100%;">
                    <option value="">Select category</option>
                    @foreach (($categoryLeaves ?? []) as $cat)
                        <option value="{{ $cat['slug'] }}">{{ $cat['label'] }}</option>
                    @endforeach
                </select>
                <textarea name="description" placeholder="Description (optional)" class="stock-input" style="width:100%; height:70px;"></textarea>
                <input type="number" name="price" placeholder="Price" step="0.01" min="0" required class="stock-input" style="width:100%;">
                <input type="number" name="discount_percent" placeholder="Discount % (optional)" step="0.1" min="0" max="90" class="stock-input" style="width:100%;">

                <div style="font-size:12px;color:#8B7A80;">Base stock is set per variant below, if you add any.</div>
                <input type="number" name="stock" id="add_base_stock" placeholder="Stock (used only if no variants added)" min="0" class="stock-input" style="width:100%;">

                <div style="border-top:1px solid var(--border);padding-top:12px;">
                    <div style="font-size:13px;font-weight:700;color:var(--maroon-dark);margin-bottom:2px;">Variants (optional)</div>
                    <div style="font-size:11.5px;color:#8B7A80;margin-bottom:10px;">e.g. different colors or sizes, each with its own stock.</div>
                    <input type="text" name="variant_type" id="add_variant_type" placeholder="Variant type — e.g. Color, Size" autocomplete="off" class="stock-input" style="width:100%;margin-bottom:10px;">
                    <div style="display:flex;gap:8px;margin-bottom:6px;">
                        <div style="flex:2;font-size:11.5px;font-weight:700;color:#8B7A80;">Variant name</div>
                        <div style="flex:1;font-size:11.5px;font-weight:700;color:#8B7A80;">Stock</div>
                    </div>
                    <div id="add_variant_rows"></div>
                    <button type="button" onclick="addVariantRow('add')" style="background:none;border:none;color:var(--maroon);font-size:12.5px;font-weight:700;cursor:pointer;padding:0;font-family:inherit;">+ Add variant</button>
                </div>

                <input type="file" name="image" accept="image/*">
                <div style="display:flex; gap:10px; margin-top:8px;">
                    <button type="button" onclick="document.getElementById('addProductModal').style.display='none'" style="flex:1; padding:10px; border-radius:8px; border:1px solid var(--border); background:transparent; font-family:inherit;">Cancel</button>
                    <button type="submit" class="edit-stock-btn" style="flex:1; padding:10px;">Save Product</button>
                </div>
            </form>
        </div>
    </div>

    {{-- Edit Product Modal --}}
    <div id="editProductModal" style="display:none; position:fixed; inset:0; background:rgba(43,28,34,.5); align-items:center; justify-content:center; z-index:50;">
        <div style="background:#fff; border-radius:18px; padding:28px; width:420px; max-width:90%; max-height:88vh; overflow-y:auto;">
            <h2 style="font-size:18px; font-weight:800; margin-bottom:18px;">Edit Product</h2>
            <form id="editProductForm" method="POST" enctype="multipart/form-data" style="display:flex; flex-direction:column; gap:12px;">
                @csrf
                @method('PATCH')
                <input type="text" name="name" id="edit_name" placeholder="Product name" required class="stock-input" style="width:100%;">
                <select name="category" id="edit_category" required class="stock-input" style="width:100%;">
                    <option value="">Select category</option>
                    @foreach (($categoryLeaves ?? []) as $cat)
                        <option value="{{ $cat['slug'] }}">{{ $cat['label'] }}</option>
                    @endforeach
                </select>
                <textarea name="description" id="edit_description" placeholder="Description (optional)" class="stock-input" style="width:100%; height:70px;"></textarea>
                <input type="number" name="price" id="edit_price" placeholder="Price" step="0.01" min="0" required class="stock-input" style="width:100%;">
                <input type="number" name="discount_percent" id="edit_discount" placeholder="Discount % (optional)" step="0.1" min="0" max="90" class="stock-input" style="width:100%;">

                <div style="font-size:12px;color:#8B7A80;">Base stock is set per variant below, if you add any.</div>
                <input type="number" name="stock" id="edit_stock" placeholder="Stock (used only if no variants added)" min="0" class="stock-input" style="width:100%;">

                <div style="border-top:1px solid var(--border);padding-top:12px;">
                    <div style="font-size:13px;font-weight:700;color:var(--maroon-dark);margin-bottom:2px;">Variants (optional)</div>
                    <div style="font-size:11.5px;color:#8B7A80;margin-bottom:10px;">e.g. different colors or sizes, each with its own stock.</div>
                    <input type="text" name="variant_type" id="edit_variant_type" placeholder="Variant type — e.g. Color, Size" autocomplete="off" class="stock-input" style="width:100%;margin-bottom:10px;">
                    <div style="display:flex;gap:8px;margin-bottom:6px;">
                        <div style="flex:2;font-size:11.5px;font-weight:700;color:#8B7A80;">Variant name</div>
                        <div style="flex:1;font-size:11.5px;font-weight:700;color:#8B7A80;">Stock</div>
                    </div>
                    <div id="edit_variant_rows"></div>
                    <button type="button" onclick="addVariantRow('edit')" style="background:none;border:none;color:var(--maroon);font-size:12.5px;font-weight:700;cursor:pointer;padding:0;font-family:inherit;">+ Add variant</button>
                </div>

                <div>
                    <label style="font-size:12px;color:#8B7A80;display:block;margin-bottom:4px;">Replace image (optional)</label>
                    <input type="file" name="image" accept="image/*">
                </div>
                <div style="display:flex; gap:10px; margin-top:8px;">
                    <button type="button" onclick="closeEditModal()" style="flex:1; padding:10px; border-radius:8px; border:1px solid var(--border); background:transparent; font-family:inherit;">Cancel</button>
                    <button type="submit" class="edit-stock-btn" style="flex:1; padding:10px;">Save Changes</button>
                </div>
            </form>
            <button type="button" id="archiveBtnTrigger" style="width:100%;margin-top:10px;padding:10px;border-radius:8px;border:1px solid #B85C3B;background:transparent;color:#B85C3B;font-family:inherit;cursor:pointer;">
                Archive Product
            </button>
            <form id="archiveProductForm" method="POST" style="display:none;">
                @csrf
                @method('PATCH')
            </form>
        </div>
    </div>

    <style>
        .view-toggle-btn {
            padding: 8px 16px;
            border-radius: 20px;
            border: 1px solid var(--border, #F0E2DA);
            background: #fff;
            color: var(--text-muted, #8B7A80);
            font-size: .82rem;
            font-weight: 500;
            text-decoration: none;
        }
        .view-toggle-btn.active {
            background: var(--maroon, #5B1A35);
            color: #fff;
            border-color: var(--maroon, #5B1A35);
        }
    </style>

    <script>
        let variantIndex = { add: 0, edit: 0 };

        function addVariantRow(prefix, name = '', stock = '') {
            const idx = variantIndex[prefix]++;
            const container = document.getElementById(prefix + '_variant_rows');
            const row = document.createElement('div');
            row.style.cssText = 'display:flex;gap:8px;margin-bottom:8px;align-items:center;';
            row.innerHTML = `
                <input type="text" name="variants[${idx}][name]" placeholder="Variant name" value="${name.replace(/"/g, '&quot;')}" autocomplete="off" class="stock-input" style="flex:2;">
                <input type="number" name="variants[${idx}][stock]" placeholder="Stock" min="0" value="${stock}" autocomplete="off" class="stock-input" style="flex:1;">
                <button type="button" onclick="this.parentElement.remove()" style="background:none;border:none;color:#B85C3B;font-size:16px;cursor:pointer;padding:4px;">&times;</button>
            `;
            container.appendChild(row);
        }

        function clearVariantRows(prefix) {
            document.getElementById(prefix + '_variant_rows').innerHTML = '';
            variantIndex[prefix] = 0;
        }

        function openEditModal(id, name, category, description, price, discount, stock, variantType, variantsJson) {
            document.getElementById('editProductForm').action = `/seller/products/${id}`;
            document.getElementById('edit_name').value = name;
            document.getElementById('edit_category').value = category || '';
            document.getElementById('edit_description').value = description || '';
            document.getElementById('edit_price').value = price;
            document.getElementById('edit_discount').value = discount ?? '';
            document.getElementById('edit_stock').value = stock;
            document.getElementById('edit_variant_type').value = variantType || '';
            document.getElementById('archiveProductForm').action = `/seller/products/${id}/archive`;

            clearVariantRows('edit');
            (variantsJson || []).forEach(v => addVariantRow('edit', v.name, v.stock));

            document.getElementById('editProductModal').style.display = 'flex';
        }

        function closeEditModal() {
            document.getElementById('editProductModal').style.display = 'none';
        }

        document.getElementById('archiveBtnTrigger').addEventListener('click', function () {
            if (confirm('Archive this product? It will be hidden from your active listings but can be restored later.')) {
                document.getElementById('archiveProductForm').submit();
            }
        });
    </script>
@endsection