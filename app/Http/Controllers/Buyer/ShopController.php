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
use Illuminate\Validation\ValidationException;
use Illuminate\View\View;

class ShopController extends Controller
{
    public function show(int $id): View
    {
        $productQuery = Product::query()
            ->with(['seller.approvedSellerApplication', 'seller.sellerApplication'])
            ->withAvg('reviews', 'rating')
            ->withCount('reviews')
            ->where('products.id', $id);
        $viewer = auth()->user();
        $canPreview = $viewer && ($viewer->role === 'admin' || ($viewer->role === 'seller' && (int) $viewer->id === (int) Product::whereKey($id)->value('seller_id')));
        if ($canPreview) {
            $productQuery->where(function ($query) { $query->where('approval_status', '!=', 'approved')->orWhere('status', 'active'); });
        } else {
            $productQuery->approved();
        }
        $product = $productQuery->first();

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

        $relatedProducts = Product::approved()
            ->withAvg('reviews', 'rating')
            ->withCount('reviews')
            ->where('category', $product->category)
            ->where('id', '!=', $product->id)
            ->orderByDesc('created_at')
            ->limit(4)
            ->get();

        $shopProfile = $this->sellerShopProfile($product->seller);

        $moreFromSeller = $product->seller
            ? $product->seller->products()->where('approval_status', 'approved')
                ->withAvg('reviews', 'rating')
                ->withCount('reviews')
                ->where('status', 'active')
                ->where('id', '!=', $product->id)
                ->latest()
                ->limit(4)
                ->get()
            : collect();

        $savedProductIds = auth()->check()
            ? DB::table('saved_products')->where('user_id', auth()->id())
                ->whereIn('product_id', collect([$product->id])->merge($relatedProducts->pluck('id'))->merge($moreFromSeller->pluck('id')))
                ->pluck('product_id')->map(fn ($id) => (int) $id)->all()
            : [];

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
            'savedProductIds' => $savedProductIds,
        ]);
    }

    public function sellerStore(Request $request, User $seller): View
    {
        $seller->load(['approvedSellerApplication', 'sellerApplication']);

        abort_unless(($seller->role === 'seller' || $seller->approvedSellerApplication) && ! in_array($seller->status, ['suspended', 'deactivated', 'banned'], true), 404);

        $validated = $request->validate([
            'search' => ['nullable', 'string', 'max:100'],
            'category' => ['nullable', 'string', 'max:255'],
            'min_price' => ['nullable', 'numeric', 'min:0'],
            'max_price' => ['nullable', 'numeric', 'min:0'],
            'sort' => ['nullable', 'in:newest,price_asc,price_desc,best_selling,top_rated'],
            'view' => ['nullable', 'in:grid,list'],
        ]);

        $search = trim((string) ($validated['search'] ?? ''));
        $category = trim((string) ($validated['category'] ?? ''));
        $minPrice = isset($validated['min_price']) ? (float) $validated['min_price'] : null;
        $maxPrice = isset($validated['max_price']) ? (float) $validated['max_price'] : null;

        if ($minPrice !== null && $maxPrice !== null && $minPrice > $maxPrice) {
            [$minPrice, $maxPrice] = [$maxPrice, $minPrice];
        }

        $sort = $validated['sort'] ?? 'newest';
        $viewMode = $validated['view'] ?? 'grid';

        $baseProducts = Product::approved()
            ->where('seller_id', $seller->id)
            ->where('status', 'active');

        $totalProductCount = (clone $baseProducts)->count();
        $categoryCounts = (clone $baseProducts)
            ->select('category', DB::raw('COUNT(*) as total'))
            ->whereNotNull('category')
            ->groupBy('category')
            ->orderBy('category')
            ->pluck('total', 'category')
            ->map(fn ($count) => (int) $count)
            ->all();

        $priceBounds = (clone $baseProducts)
            ->selectRaw('MIN(price) as min_price, MAX(price) as max_price')
            ->first();

        $productsQuery = (clone $baseProducts)
            ->withAvg('reviews', 'rating')
            ->withCount('reviews');

        if ($search !== '') {
            $productsQuery->where(function ($query) use ($search) {
                $query->where('name', 'like', "%{$search}%")
                    ->orWhere('category', 'like', "%{$search}%");
            });
        }

        if ($category !== '') {
            $productsQuery->where('category', $category);
        }

        if ($minPrice !== null) {
            $productsQuery->where('price', '>=', $minPrice);
        }

        if ($maxPrice !== null) {
            $productsQuery->where('price', '<=', $maxPrice);
        }

        if ($sort === 'price_asc') {
            $productsQuery->orderBy('price')->orderByDesc('created_at');
        } elseif ($sort === 'price_desc') {
            $productsQuery->orderByDesc('price')->orderByDesc('created_at');
        } elseif ($sort === 'best_selling' && Schema::hasColumn('products', 'sales_count')) {
            $productsQuery->orderByDesc('sales_count')->orderByDesc('created_at');
        } elseif ($sort === 'top_rated') {
            $productsQuery->orderByDesc('reviews_avg_rating')->orderByDesc('reviews_count')->orderByDesc('created_at');
        } else {
            $productsQuery->orderByDesc('created_at');
        }

        $products = $productsQuery->paginate(12)->withQueryString();
        $savedProductIds = auth()->check()
            ? DB::table('saved_products')->where('user_id', auth()->id())->whereIn('product_id', $products->getCollection()->pluck('id'))->pluck('product_id')->map(fn ($id) => (int) $id)->all()
            : [];

        $reviewsBase = ProductReview::query()
            ->whereHas('product', function ($query) use ($seller) {
                $query->where('seller_id', $seller->id)
                    ->where('status', 'active')->where('approval_status', 'approved');
            });

        $ratingBreakdown = (clone $reviewsBase)
            ->select('rating', DB::raw('COUNT(*) as total'))
            ->groupBy('rating')
            ->pluck('total', 'rating')
            ->map(fn ($total) => (int) $total)
            ->all();

        $recentReviews = (clone $reviewsBase)
            ->with(['user', 'product'])
            ->latest()
            ->limit(6)
            ->get();

        return view('buyer.store', [
            'seller' => $seller,
            'shopProfile' => $this->sellerShopProfile($seller),
            'products' => $products,
            'categoryCounts' => $categoryCounts,
            'totalProductCount' => $totalProductCount,
            'priceBounds' => [
                'min' => $priceBounds?->min_price !== null ? (float) $priceBounds->min_price : null,
                'max' => $priceBounds?->max_price !== null ? (float) $priceBounds->max_price : null,
            ],
            'filters' => [
                'search' => $search,
                'category' => $category,
                'min_price' => $minPrice,
                'max_price' => $maxPrice,
                'sort' => $sort,
                'view' => $viewMode,
            ],
            'businessCategory' => $seller->approvedSellerApplication?->category ?: $seller->sellerApplication?->category,
            'ratingBreakdown' => $ratingBreakdown,
            'recentReviews' => $recentReviews,
            'savedProductIds' => $savedProductIds,
        ]);
    }

    public function index(Request $request): View
    {
        $category = is_string($request->query('category')) ? trim($request->query('category')) : '';
        if ($category !== '' && ! in_array($category, CategoryCatalog::selectableSlugs(), true)) abort(404);

        $validated = $request->validate([
            'q' => ['nullable', 'string', 'max:100'],
            'min_price' => ['nullable', 'numeric', 'min:0', 'max:100000000'],
            'max_price' => ['nullable', 'numeric', 'min:0', 'max:100000000'],
            'rating' => ['nullable', 'numeric', 'in:4'],
            'in_stock' => ['nullable', 'boolean'],
            'on_sale' => ['nullable', 'boolean'],
            'sort' => ['nullable', 'in:popular,top_sales,newest,price_asc,price_desc,top_rated,best_selling'],
            'view' => ['nullable', 'in:grid,list'],
        ]);

        $minPrice = isset($validated['min_price']) ? (float) $validated['min_price'] : null;
        $maxPrice = isset($validated['max_price']) ? (float) $validated['max_price'] : null;

        if ($minPrice !== null && $maxPrice !== null && $minPrice > $maxPrice) {
            throw ValidationException::withMessages(['min_price' => 'Minimum price must not exceed maximum price.']);
        }

        $sort = $validated['sort'] ?? 'newest';
        $search = trim((string) ($validated['q'] ?? ''));
        $baseQuery = Product::approved();

        if ($search !== '') {
            $baseQuery->where(function ($query) use ($search) {
                $query->where('name', 'like', "%{$search}%")
                    ->orWhere('description', 'like', "%{$search}%")
                    ->orWhere('category', 'like', "%{$search}%");
            });
        }

        // One grouped aggregate for the whole category tree, independent of other filters.
        $categoryCounts = Product::approved()
            ->select('category', DB::raw('COUNT(*) as total'))
            ->groupBy('category')
            ->pluck('total', 'category')
            ->map(fn ($count) => (int) $count)
            ->all();

        // Preserve the landing route and its original all-products view.
        if ($request->routeIs('home')) {
            $homeCategoryCounts = (clone $baseQuery)
                ->select('category', DB::raw('COUNT(*) as total'))
                ->whereIn('category', CategoryCatalog::slugs())
                ->groupBy('category')->pluck('total', 'category')
                ->map(fn ($count) => (int) $count)->all();
            $homeProducts = (clone $baseQuery)->with('seller')->withAvg('reviews', 'rating')->withCount('reviews');
            if (in_array($sort, ['top_sales', 'best_selling'], true) && Schema::hasColumn('products', 'sales_count')) {
                $homeProducts->orderByDesc('sales_count')->orderByDesc('created_at');
            } elseif ($sort === 'popular' || $sort === 'top_rated') {
                $homeProducts->orderByDesc('reviews_avg_rating')->orderByDesc('created_at');
            } elseif ($sort === 'price_asc') {
                $homeProducts->orderBy('price')->orderByDesc('created_at');
            } elseif ($sort === 'price_desc') {
                $homeProducts->orderByDesc('price')->orderByDesc('created_at');
            } else {
                $homeProducts->orderByDesc('created_at');
            }
            $homeProductCollection = $homeProducts->get();
            $savedProductIds = auth()->check()
                ? DB::table('saved_products')->where('user_id', auth()->id())->whereIn('product_id', $homeProductCollection->pluck('id'))->pluck('product_id')->map(fn ($id) => (int) $id)->all()
                : [];
            return view('buyer.shop', [
                'products' => $homeProductCollection,
                'categoryCounts' => $homeCategoryCounts,
                'categoryTree' => CategoryCatalog::tree(),
                'searchQuery' => $search,
                'savedProductIds' => $savedProductIds,
            ]);
        }

        $productsQuery = $baseQuery
            ->with('seller')
            ->withAvg('reviews', 'rating')
            ->withCount('reviews');

        if ($category !== '') $productsQuery->whereIn('category', CategoryCatalog::leafSlugsFor($category));
        if ($minPrice !== null) $productsQuery->where('price', '>=', $minPrice);
        if ($maxPrice !== null) $productsQuery->where('price', '<=', $maxPrice);
        if ($request->boolean('in_stock')) $productsQuery->where('stock', '>', 0);
        if ($request->boolean('on_sale')) $productsQuery->where('discount_percent', '>', 0);
        if (isset($validated['rating'])) {
            $ratedProductIds = DB::table('product_reviews')
                ->select('product_id')->selectRaw('AVG(rating) as average_rating')->groupBy('product_id')
                ->get()->filter(fn ($review) => (float) $review->average_rating >= (float) $validated['rating'])
                ->pluck('product_id');
            $productsQuery->whereIn('products.id', $ratedProductIds);
        }

        if ($sort === 'top_sales' && Schema::hasColumn('products', 'sales_count')) {
            $productsQuery->orderByDesc('sales_count')->orderByDesc('created_at');
        } elseif ($sort === 'top_rated') {
            $productsQuery->orderByDesc('reviews_avg_rating')->orderByDesc('reviews_count')->orderByDesc('created_at');
        } elseif ($sort === 'popular') {
            $productsQuery->orderByDesc('reviews_avg_rating')->orderByDesc('created_at');
        } elseif ($sort === 'price_asc') {
            $productsQuery->orderBy('price')->orderByDesc('created_at');
        } elseif ($sort === 'price_desc') {
            $productsQuery->orderByDesc('price')->orderByDesc('created_at');
        } else {
            $productsQuery->orderByDesc('created_at');
        }

        $products = $productsQuery->paginate(12)->withQueryString();
        $savedProductIds = auth()->check()
            ? DB::table('saved_products')->where('user_id', auth()->id())->whereIn('product_id', $products->getCollection()->pluck('id'))->pluck('product_id')->all()
            : [];

        return view('buyer.category', [
            'products' => $products,
            'category' => $category,
            'categoryTitle' => $category !== '' ? CategoryCatalog::label($category) : 'All products',
            'categoryCounts' => $categoryCounts,
            'categoryTree' => CategoryCatalog::tree(),
            'savedProductIds' => $savedProductIds,
            'filters' => [
                'q' => $search, 'min_price' => $minPrice, 'max_price' => $maxPrice,
                'rating' => $validated['rating'] ?? null, 'in_stock' => $request->boolean('in_stock'),
                'on_sale' => $request->boolean('on_sale'), 'sort' => $sort,
            ],
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

        $activeProducts = $seller->products()->approved();
        $activeProductCount = (clone $activeProducts)->count();
        $soldCount = (int) (clone $activeProducts)->sum('sales_count');

        $reviews = ProductReview::query()
            ->join('products', 'product_reviews.product_id', '=', 'products.id')
            ->where('products.seller_id', $seller->id)
            ->where('products.status', 'active')->where('products.approval_status', 'approved');

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
