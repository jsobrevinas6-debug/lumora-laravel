<?php

namespace App\Http\Controllers\Buyer;

use App\Http\Controllers\Controller;
use App\Support\CategoryCatalog;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;
use Illuminate\View\View;

class ShopController extends Controller
{
    public function show(int $id): View
    {
        $product = DB::table('products')
            ->leftJoin('users', 'users.id', '=', 'products.seller_id')
            ->select('products.*', 'users.shop_name', 'users.name as seller_name')
            ->where('products.id', $id)
            ->where('products.status', 'active')
            ->first();

        abort_if(!$product, 404);

        $relatedProducts = DB::table('products')
            ->where('status', 'active')
            ->where('category', $product->category)
            ->where('id', '!=', $product->id)
            ->orderByDesc('created_at')
            ->limit(4)
            ->get();

        return view('buyer.product', [
            'product' => $product,
            'relatedProducts' => $relatedProducts,
            'categoryTitle' => CategoryCatalog::label((string) ($product->category ?? '')),
        ]);
    }

    public function index(Request $request): View
    {
        $category = trim((string) $request->query('category', ''));

        if ($category !== '' && !in_array($category, CategoryCatalog::slugs(), true)) {
            abort(404);
        }

        $validated = $request->validate([
            'min_price' => ['nullable', 'numeric', 'min:0'],
            'max_price' => ['nullable', 'numeric', 'min:0'],
            'discount' => ['nullable', 'integer', 'in:10,20'],
            'in_stock' => ['nullable', 'boolean'],
            'on_sale' => ['nullable', 'boolean'],
            'sort' => ['nullable', 'in:newest,latest,popular,top_sales,price_asc,price_desc,discount_desc'],
        ]);

        $minPrice = isset($validated['min_price']) ? (float) $validated['min_price'] : null;
        $maxPrice = isset($validated['max_price']) ? (float) $validated['max_price'] : null;

        if ($minPrice !== null && $maxPrice !== null && $minPrice > $maxPrice) {
            [$minPrice, $maxPrice] = [$maxPrice, $minPrice];
        }

        $sort = $validated['sort'] ?? 'newest';
        $baseQuery = DB::table('products')->where('status', 'active');

        $categoryCounts = (clone $baseQuery)
            ->select('category', DB::raw('COUNT(*) as total'))
            ->whereIn('category', CategoryCatalog::slugs())
            ->groupBy('category')
            ->pluck('total', 'category')
            ->map(fn ($count) => (int) $count)
            ->all();

        if ($category !== '') {
            $query = (clone $baseQuery)->where('category', $category);

            if ($minPrice !== null) $query->where('price', '>=', $minPrice);
            if ($maxPrice !== null) $query->where('price', '<=', $maxPrice);
            if ($request->boolean('in_stock')) $query->where('stock', '>', 0);
            if ($request->boolean('on_sale')) $query->where('discount_percent', '>', 0);
            if (isset($validated['discount'])) $query->where('discount_percent', '>=', (int) $validated['discount']);

            if ($sort === 'price_asc') {
                $query->orderBy('price')->orderByDesc('created_at');
            } elseif ($sort === 'price_desc') {
                $query->orderByDesc('price')->orderByDesc('created_at');
            } elseif ($sort === 'discount_desc') {
                $query->orderByDesc('discount_percent')->orderByDesc('created_at');
            } elseif ($sort === 'popular' && Schema::hasColumn('products', 'rating')) {
                $query->orderByDesc('rating')->orderByDesc('created_at');
            } elseif ($sort === 'top_sales' && Schema::hasColumn('products', 'sales_count')) {
                $query->orderByDesc('sales_count')->orderByDesc('created_at');
            } else {
                // Latest is also the safe fallback when popularity/sales data is not available yet.
                $query->orderByDesc('created_at');
            }

            $products = $query->paginate(12)->withQueryString();

            return view('buyer.category', [
                'products' => $products,
                'category' => $category,
                'categoryTitle' => CategoryCatalog::label($category),
                'categoryCounts' => $categoryCounts,
                'filters' => [
                    'min_price' => $minPrice,
                    'max_price' => $maxPrice,
                    'discount' => $validated['discount'] ?? null,
                    'in_stock' => $request->boolean('in_stock'),
                    'on_sale' => $request->boolean('on_sale'),
                    'sort' => $sort,
                ],
            ]);
        }

        $products = $baseQuery->orderByDesc('created_at')->get();

        return view('buyer.shop', [
            'products' => $products,
            'categoryCounts' => $categoryCounts,
            'categoryTree' => CategoryCatalog::tree(),
        ]);
    }
}
