<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Product;
use App\Support\CategoryCatalog;
use Illuminate\Database\Eloquent\Builder;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

/**
 * Read-only product catalog for the Lumora mobile app.
 * Mirrors the visibility rules of Buyer\ShopController (only "active" products).
 */
class ProductController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'category' => ['nullable', 'string', 'max:255'],
            'search' => ['nullable', 'string', 'max:100'],
            'flash_deals' => ['nullable', 'boolean'],
            'seller_id' => ['nullable', 'integer'],
            'per_page' => ['nullable', 'integer', 'min:1', 'max:200'],
        ]);

        $query = $this->baseQuery();

        $category = trim((string) ($validated['category'] ?? ''));
        if ($category !== '' && strtolower($category) !== 'all') {
            $query->where('category', $this->resolveCategorySlug($category));
        }

        $search = trim((string) ($validated['search'] ?? ''));
        if ($search !== '') {
            $query->where(function (Builder $q) use ($search) {
                $q->where('name', 'like', "%{$search}%")
                    ->orWhere('category', 'like', "%{$search}%");
            });
        }

        if ($request->boolean('flash_deals')) {
            $query->where('discount_percent', '>', 0);
        }

        if (isset($validated['seller_id'])) {
            $query->where('seller_id', (int) $validated['seller_id']);
        }

        $products = $query->orderByDesc('created_at')->paginate($validated['per_page'] ?? 100);

        return response()->json([
            'data' => $products->getCollection()->map(fn (Product $p) => $this->transform($p))->values(),
            'meta' => [
                'current_page' => $products->currentPage(),
                'last_page' => $products->lastPage(),
                'per_page' => $products->perPage(),
                'total' => $products->total(),
            ],
        ]);
    }

    public function show(int $id): JsonResponse
    {
        $product = $this->baseQuery()->where('products.id', $id)->first();

        if (! $product) {
            return response()->json(['message' => 'Product not found.'], 404);
        }

        return response()->json(['data' => $this->transform($product)]);
    }

    private function baseQuery(): Builder
    {
        return Product::query()
            ->with('seller')
            ->withAvg('reviews', 'rating')
            ->withCount('reviews')
            ->where('status', 'active');
    }

    /** Accepts either a category slug or its display label (e.g. from the mobile app). */
    private function resolveCategorySlug(string $category): string
    {
        foreach (CategoryCatalog::slugs() as $slug) {
            if (strcasecmp($slug, $category) === 0 || strcasecmp(CategoryCatalog::label($slug), $category) === 0) {
                return $slug;
            }
        }

        return $category;
    }

    private function transform(Product $p): array
    {
        $originalPrice = (float) $p->price;
        $discountPercent = (float) ($p->discount_percent ?? 0);
        // Same pricing formula as Buyer\CartController::hydrateCart().
        $unitPrice = round($originalPrice * (1 - ($discountPercent / 100)), 2);

        $reviewsCount = (int) ($p->reviews_count ?? 0);
        $rating = $reviewsCount > 0
            ? round((float) $p->reviews_avg_rating, 1)
            : round((float) ($p->rating ?? 0), 1);

        $seller = $p->seller;
        $sellerLocation = $seller
            ? collect([$seller->municipality, $seller->province])->filter()->implode(', ')
            : '';

        return [
            'id' => $p->id,
            'name' => $p->name,
            'price' => $unitPrice,
            'original_price' => $discountPercent > 0 ? $originalPrice : null,
            'discount_percent' => $discountPercent,
            'discount_label' => $discountPercent > 0
                ? rtrim(rtrim(number_format($discountPercent, 1), '0'), '.').'% OFF'
                : null,
            'is_flash_deal' => $discountPercent > 0,
            'category_id' => $p->category,
            'category_name' => $p->category ? CategoryCatalog::label((string) $p->category) : null,
            'description' => (string) ($p->description ?? ''),
            'rating' => $rating,
            'reviews_count' => $reviewsCount,
            'sold_count' => (int) ($p->sales_count ?? 0),
            'stock' => (int) $p->stock,
            'variant_type' => $p->variant_type,
            'image_path' => $p->image_url,
            'images' => $p->image_urls,
            'seller_id' => $p->seller_id,
            'seller_name' => $seller ? ($seller->shop_name ?: $seller->name) : null,
            'seller_location' => $sellerLocation ?: null,
            'created_at' => $p->created_at?->toIso8601String(),
        ];
    }
}
