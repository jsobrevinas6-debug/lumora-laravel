@extends('layouts.seller')

@section('title', 'My Products')

@section('content')
    @if (session('success'))
        <div class="alert-success">{{ session('success') }}</div>
    @endif

    <div class="products-grid">
        {{-- Add Product tile --}}
        <button type="button" class="add-product-tile" onclick="document.getElementById('addProductModal').style.display='flex'" style="cursor:pointer; font-family:inherit;">
            <div class="add-icon">+</div>
            <div class="add-label">Add Product</div>
        </button>

        {{-- Every product the seller has inserted --}}
        @forelse ($products as $product)
            <div class="product-tile">
                <div class="product-image">
                    @if ($product->image)
                        <img src="{{ asset('storage/' . $product->image) }}" alt="{{ $product->name }}">
                    @else
                        No image
                    @endif
                </div>
                <div class="product-body">
                    <div class="product-name">{{ $product->name }}</div>
                    <div class="product-price">₱{{ number_format($product->price, 2) }}</div>
                    <div class="product-stock">
                        Stock:
                        <span class="count {{ $product->stock <= 5 ? 'low' : '' }}">{{ $product->stock }}</span>
                    </div>

                    <form action="{{ route('seller.products.updateStock', $product->id) }}" method="POST" class="stock-form">
                        @csrf
                        @method('PATCH')
                        <input type="number" name="stock" value="{{ $product->stock }}" min="0" class="stock-input">
                        <button type="submit" class="edit-stock-btn">Edit Stock</button>
                    </form>
                </div>
            </div>
        @empty
            {{-- no products yet — Add Product tile still shows above --}}
        @endforelse
    </div>

    {{-- Add Product Modal --}}
    <div id="addProductModal" style="display:none; position:fixed; inset:0; background:rgba(43,28,34,.5); align-items:center; justify-content:center; z-index:50;">
        <div style="background:#fff; border-radius:18px; padding:28px; width:420px; max-width:90%;">
            <h2 style="font-size:18px; font-weight:800; margin-bottom:18px;">Add Product</h2>
            <form action="{{ route('seller.products.store') }}" method="POST" enctype="multipart/form-data" style="display:flex; flex-direction:column; gap:12px;">
                @csrf
                <input type="text" name="name" placeholder="Product name" required class="stock-input" style="width:100%;">
                <textarea name="description" placeholder="Description (optional)" class="stock-input" style="width:100%; height:70px;"></textarea>
                <input type="number" name="price" placeholder="Price" step="0.01" min="0" required class="stock-input" style="width:100%;">
                <input type="number" name="stock" placeholder="Initial stock" min="0" required class="stock-input" style="width:100%;">
                <input type="file" name="image" accept="image/*">
                <div style="display:flex; gap:10px; margin-top:8px;">
                    <button type="button" onclick="document.getElementById('addProductModal').style.display='none'" style="flex:1; padding:10px; border-radius:8px; border:1px solid var(--border); background:transparent; font-family:inherit;">Cancel</button>
                    <button type="submit" class="edit-stock-btn" style="flex:1; padding:10px;">Save Product</button>
                </div>
            </form>
        </div>
    </div>
@endsection