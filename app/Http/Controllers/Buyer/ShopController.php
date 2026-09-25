<?php

namespace App\Http\Controllers\Buyer;

use App\Http\Controllers\Controller;
use App\Models\Order;
use App\Models\Product;
use App\Models\ProductReview;
use App\Models\User;
use App\Support\CategoryCatalog;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;
use Illuminate\View\View;

class ShopController extends Controller
{
    public function show(int $id): View
    {
        $product = Product::query()
            ->with(['seller.approvedSellerApplication', 'seller.sellerApplication'])
            ->withAvg('reviews', 'rating')
            ->withCount('reviews')
            ->where('products.id', $id)
            ->where('products.status', 'active')
            ->first();

        abort_if(!$product, 404);

        $reviews = $product->reviews()
            ->with(['user'])
            ->latest()
            ->paginate(10, ['*'], 'reviews_page');

        $ratingBreakdown = $product->reviews()
            ->select('rating', DB::raw('COUNT(*) as total'))
            ->groupBy('rating')
            ->pluck('total', 'rating')
            ->map(fn ($total) => (int) $total);

        $userReview = null;
        $deliveredOrder = null;

        if (auth()->check()) {
            $userReview = $product->reviews()
                ->where('user_id', auth()->id())
                ->first();

            $deliveredOrder = Order::query()
                ->where('user_id', auth()->id())
                ->where('status', 'delivered')
                ->whereHas('items', fn ($query) => $query->where('product_id', $product->id))
                ->latest('delivered_at')
                ->latest('id')
                ->first();
        }

        $relatedProducts = Product::query()
            ->withAvg('reviews', 'rating')
            ->withCount('reviews')
            ->where('status', 'active')
            ->where('category', $product->category)
            ->where('id', '!=', $product->id)
            ->orderByDesc('created_at')
            ->limit(4)
            ->get();

        $shopProfile = $this->sellerShopProfile($product->seller);

        $moreFromSeller = $product->seller
            ? $product->seller->products()
                ->withAvg('reviews', 'rating')
                ->withCount('reviews')
                ->where('status', 'active')
                ->where('id', '!=', $product->id)
                ->latest()
                ->limit(4)
                ->get()
            : collect();

        return view('buyer.product', [
            'product' => $product,
            'relatedProducts' => $relatedProducts,
            'shopProfile' => $shopProfile,
            'moreFromSeller' => $moreFromSeller,
            'reviews' => $reviews,
            'ratingBreakdown' => $ratingBreakdown,
            'userReview' => $userReview,
            'canReview' => (bool) $deliveredOrder,
            'categoryTitle' => CategoryCatalog::label((string) ($product->category ?? '')),
        ]);
    }

    public function sellerStore(User $seller): View
    {
        $seller->load(['approvedSellerApplication', 'sellerApplication']);

        abort_unless($seller->role === 'seller' || $seller->approvedSellerApplication, 404);

        $products = $seller->products()
            ->withAvg('reviews', 'rating')
            ->withCount('reviews')
            ->where('status', 'active')
            ->latest()
            ->paginate(12);

        return view('buyer.store', [
            'seller' => $seller,
            'shopProfile' => $this->sellerShopProfile($seller),
            'products' => $products,
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
        $baseQuery = Product::query()->where('status', 'active');

        $categoryCounts = (clone $baseQuery)
            ->select('category', DB::raw('COUNT(*) as total'))
            ->whereIn('category', CategoryCatalog::slugs())
            ->groupBy('category')
            ->pluck('total', 'category')
            ->map(fn ($count) => (int) $count)
            ->all();

        if ($category !== '') {
            $query = (clone $baseQuery)
                ->withAvg('reviews', 'rating')
                ->withCount('reviews')
                ->where('category', $category);

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
            } elseif ($sort === 'popular') {
                $query->orderByDesc('reviews_avg_rating')->orderByDesc('created_at');
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

        $products = $baseQuery
            ->withAvg('reviews', 'rating')
            ->withCount('reviews')
            ->orderByDesc('created_at')
            ->get();

        return view('buyer.shop', [
            'products' => $products,
            'categoryCounts' => $categoryCounts,
            'categoryTree' => CategoryCatalog::tree(),
        ]);
    }

    private function sellerShopProfile(?User $seller): array
    {
        if (! $seller) {
            return [
                'seller' => null,
                'name' => 'Lumora seller',
                'description' => 'This seller has not added a shop description yet.',
                'avatar' => null,
                'initials' => 'LS',
                'location' => null,
                'verified' => false,
                'active_products' => 0,
                'sold_count' => 0,
                'rating_average' => null,
                'review_count' => 0,
                'joined' => null,
                'url' => null,
            ];
        }

        $seller->loadMissing(['approvedSellerApplication', 'sellerApplication']);

        $approvedApplication = $seller->approvedSellerApplication;
        $latestApplication = $seller->sellerApplication;
        $shopName = $seller->shop_name
            ?: ($approvedApplication?->business_name ?: ($latestApplication?->business_name ?: $seller->name));

        $activeProducts = $seller->products()->where('status', 'active');
        $activeProductCount = (clone $activeProducts)->count();
        $soldCount = (int) (clone $activeProducts)->sum('sales_count');

        $reviews = ProductReview::query()
            ->join('products', 'product_reviews.product_id', '=', 'products.id')
            ->where('products.seller_id', $seller->id)
            ->where('products.status', 'active');

        $reviewCount = (clone $reviews)->count('product_reviews.id');
        $ratingAverage = $reviewCount > 0
            ? round((float) (clone $reviews)->avg('product_reviews.rating'), 1)
            : null;

        $location = collect([$seller->municipality, $seller->province])
            ->filter(fn ($value) => filled($value))
            ->implode(', ');

        $initials = collect(preg_split('/\s+/', trim((string) $shopName)))
            ->filter()
            ->map(fn ($part) => mb_substr($part, 0, 1))
            ->take(2)
            ->implode('');

        return [
            'seller' => $seller,
            'name' => $shopName ?: 'Lumora seller',
            'description' => $seller->shop_description ?: 'This seller has not added a shop description yet.',
            'avatar' => $seller->avatar,
            'initials' => mb_strtoupper($initials ?: 'LS'),
            'location' => $location ?: null,
            'verified' => (bool) $approvedApplication,
            'active_products' => $activeProductCount,
            'sold_count' => $soldCount,
            'rating_average' => $ratingAverage,
            'review_count' => $reviewCount,
            'joined' => ($approvedApplication?->updated_at ?: $seller->created_at)?->format('M Y'),
            'url' => route('shop.seller', ['seller' => $seller->id]),
        ];
    }
}
