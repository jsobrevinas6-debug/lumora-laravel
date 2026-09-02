<?php

namespace App\Http\Controllers\Seller;

use App\Http\Controllers\Controller;
use App\Support\CategoryCatalog;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Storage;
use Illuminate\Validation\Rule;

class ProductController extends Controller
{
    public function index(Request $request)
    {
        $view = $request->query('view', 'active');
        $query = DB::table('products')->where('seller_id', Auth::id());

        if ($view === 'archived') {
            $query->where('status', 'archived');
        } else {
            $query->where('status', '!=', 'archived');
        }

        $products = $query->orderByDesc('created_at')->get();
        $variants = DB::table('product_variants')
            ->whereIn('product_id', $products->pluck('id'))
            ->orderBy('id')
            ->get()
            ->groupBy('product_id');

        return view('seller.products', [
            'products' => $products,
            'view' => $view,
            'variants' => $variants,
            'categoryTree' => CategoryCatalog::tree(),
            'categoryLeaves' => CategoryCatalog::leaves(),
        ]);
    }

    public function store(Request $request)
    {
        $validated = $this->validateProduct($request);
        $imagePath = $request->hasFile('image')
            ? $request->file('image')->store('products', 'public')
            : null;

        $variantRows = collect($request->input('variants', []))
            ->filter(fn ($v) => !empty($v['name']));
        $hasVariants = $variantRows->isNotEmpty();
        $totalStock = $hasVariants
            ? $variantRows->sum(fn ($v) => (int) ($v['stock'] ?? 0))
            : (int) ($request->stock ?? 0);

        $productId = DB::table('products')->insertGetId([
            'seller_id' => Auth::id(),
            'name' => $validated['name'],
            'category' => $validated['category'],
            'description' => $validated['description'] ?? null,
            'price' => $validated['price'],
            'discount_percent' => $validated['discount_percent'] ?? null,
            'stock' => $totalStock,
            'variant_type' => $hasVariants ? ($validated['variant_type'] ?? null) : null,
            'image' => $imagePath,
            'status' => 'active',
            'created_at' => now(),
            'updated_at' => now(),
        ]);

        $this->insertVariants($productId, $variantRows);
        return back()->with('success', 'Product added successfully!');
    }

    public function update(Request $request, $id)
    {
        $product = DB::table('products')
            ->where('id', $id)
            ->where('seller_id', Auth::id())
            ->first();
        abort_unless($product, 403);

        $validated = $this->validateProduct($request);
        $variantRows = collect($request->input('variants', []))
            ->filter(fn ($v) => !empty($v['name']));
        $hasVariants = $variantRows->isNotEmpty();

        $data = [
            'name' => $validated['name'],
            'category' => $validated['category'],
            'description' => $validated['description'] ?? null,
            'price' => $validated['price'],
            'discount_percent' => $validated['discount_percent'] ?? null,
            'stock' => $hasVariants
                ? $variantRows->sum(fn ($v) => (int) ($v['stock'] ?? 0))
                : (int) ($request->stock ?? 0),
            'variant_type' => $hasVariants ? ($validated['variant_type'] ?? null) : null,
            'updated_at' => now(),
        ];

        if ($request->hasFile('image')) {
            if ($product->image) {
                Storage::disk('public')->delete($product->image);
            }
            $data['image'] = $request->file('image')->store('products', 'public');
        }

        DB::table('products')->where('id', $id)->update($data);
        DB::table('product_variants')->where('product_id', $id)->delete();
        $this->insertVariants($id, $variantRows);

        return back()->with('success', 'Product updated.');
    }

    private function validateProduct(Request $request): array
    {
        return $request->validate([
            'name' => ['required', 'string', 'max:255'],
            'category' => ['required', 'string', Rule::in(CategoryCatalog::slugs())],
            'description' => ['nullable', 'string'],
            'price' => ['required', 'numeric', 'min:0'],
            'discount_percent' => ['nullable', 'numeric', 'min:0', 'max:90'],
            'stock' => ['nullable', 'integer', 'min:0'],
            'image' => ['nullable', 'image', 'max:2048'],
            'variant_type' => ['nullable', 'string', 'max:100'],
            'variants' => ['nullable', 'array'],
            'variants.*.name' => ['nullable', 'string', 'max:255'],
            'variants.*.stock' => ['nullable', 'integer', 'min:0'],
        ]);
    }

    private function insertVariants(int $productId, $variantRows): void
    {
        foreach ($variantRows as $variant) {
            DB::table('product_variants')->insert([
                'product_id' => $productId,
                'name' => $variant['name'],
                'stock' => (int) ($variant['stock'] ?? 0),
                'created_at' => now(),
                'updated_at' => now(),
            ]);
        }
    }

    public function updateStock(Request $request, $id)
    {
        $request->validate(['stock' => 'required|integer|min:0']);
        $product = DB::table('products')->where('id', $id)->where('seller_id', Auth::id())->first();
        abort_unless($product, 403);
        DB::table('products')->where('id', $id)->update(['stock' => $request->stock, 'updated_at' => now()]);
        return back()->with('success', 'Stock updated.');
    }

    public function archive($id)
    {
        DB::table('products')->where('id', $id)->where('seller_id', Auth::id())->update(['status' => 'archived', 'updated_at' => now()]);
        return back()->with('success', 'Product archived.');
    }

    public function restore($id)
    {
        DB::table('products')->where('id', $id)->where('seller_id', Auth::id())->update(['status' => 'active', 'updated_at' => now()]);
        return back()->with('success', 'Product restored.');
    }

    public function destroy($id)
    {
        $product = DB::table('products')->where('id', $id)->where('seller_id', Auth::id())->first();
        if ($product && $product->image) {
            Storage::disk('public')->delete($product->image);
        }
        DB::table('products')->where('id', $id)->where('seller_id', Auth::id())->delete();
        return back()->with('success', 'Product permanently deleted.');
    }
}
