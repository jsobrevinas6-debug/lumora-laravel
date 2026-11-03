<x-admin-layout title="Product Approval">
    <div class="panel">
        <h2>Products awaiting review</h2>
        <p style="color:var(--text-muted);margin:-8px 0 18px;font-size:.9rem;">
            New seller products stay hidden from buyers until approved.
        </p>

        <div style="overflow-x:auto;">
            <table>
                <thead>
                    <tr>
                        <th>Product</th>
                        <th>Seller</th>
                        <th>Category</th>
                        <th>Price</th>
                        <th>Stock</th>
                        <th>Submitted</th>
                        <th>Actions</th>
                    </tr>
                </thead>
                <tbody>
                    @forelse ($products as $product)
                        <tr>
                            <td>
                                <div style="display:flex;align-items:center;gap:10px;min-width:190px;">
                                    <img src="{{ \App\Models\Product::resolveImageUrl($product->image) }}" alt="" style="width:48px;height:48px;object-fit:cover;border-radius:8px;">
                                    <div>
                                        <strong>{{ $product->name }}</strong>
                                        @if ($product->description)
                                            <div style="max-width:260px;color:var(--text-muted);font-size:.78rem;">{{ \Illuminate\Support\Str::limit($product->description, 90) }}</div>
                                        @endif
                                    </div>
                                </div>
                            </td>
                            <td>{{ $product->seller_name }}</td>
                            <td>{{ $product->category ?: '—' }}</td>
                            <td>PHP {{ number_format((float) $product->price, 2) }}</td>
                            <td>{{ $product->stock }}</td>
                            <td>{{ \Carbon\Carbon::parse($product->created_at)->format('M d, Y') }}</td>
                            <td style="white-space:nowrap;">
                                <form method="POST" action="{{ route('admin.product-approval.approve', $product->id) }}" style="display:inline-block;">
                                    @csrf
                                    <button class="btn btn-dark" type="submit">Approve</button>
                                </form>
                                <form method="POST" action="{{ route('admin.product-approval.reject', $product->id) }}" style="display:inline-block;margin-left:4px;" onsubmit="return confirm('Reject this product and keep it hidden from buyers?');">
                                    @csrf
                                    <button class="btn btn-danger" type="submit">Reject</button>
                                </form>
                            </td>
                        </tr>
                    @empty
                        <tr><td colspan="7" style="text-align:center;color:var(--text-muted);padding:24px;">No products are waiting for approval.</td></tr>
                    @endforelse
                </tbody>
            </table>
        </div>
    </div>
</x-admin-layout>
