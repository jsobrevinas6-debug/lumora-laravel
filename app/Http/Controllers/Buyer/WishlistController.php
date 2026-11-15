<?php

namespace App\Http\Controllers\Buyer;

use App\Http\Controllers\Controller;
use App\Models\Product;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\View\View;
use Throwable;

class WishlistController extends Controller
{
    public function index(Request $request): View
    {
        $filter = $request->query('filter', 'all');
        if (! in_array($filter, ['all', 'sale', 'in_stock', 'out_of_stock'], true)) $filter = 'all';

        $shopId = $request->query('shop');
        if (! is_string($shopId) || ! ctype_digit($shopId)) $shopId = '';

        $sort = $request->query('sort', 'recent');
        if (! in_array($sort, ['recent', 'price_asc', 'price_desc'], true)) $sort = 'recent';
        $loadError = false;
        $products = collect();
        $shops = collect();
        $savedCount = 0;

        try {
            $query = Product::query()
                ->approved()
                ->join('saved_products', 'saved_products.product_id', '=', 'products.id')
                ->where('saved_products.user_id', $request->user()->id)
                ->select('products.*', 'saved_products.created_at as saved_at')
                ->with(['seller.approvedSellerApplication'])
                ->withAvg('reviews', 'rating')
                ->withCount('reviews');

            if ($filter === 'sale') {
                $query->where('products.discount_percent', '>', 0);
            } elseif ($filter === 'in_stock') {
                $query->where('products.stock', '>', 0);
            } elseif ($filter === 'out_of_stock') {
                $query->where('products.stock', '<=', 0);
            }

            if ($shopId !== '') {
                $query->where('products.seller_id', (int) $shopId);
            }

            if ($sort === 'price_asc') {
                $query->orderByRaw('(products.price * (1 - products.discount_percent / 100)) asc')
                    ->orderByDesc('saved_products.created_at');
            } elseif ($sort === 'price_desc') {
                $query->orderByRaw('(products.price * (1 - products.discount_percent / 100)) desc')
                    ->orderByDesc('saved_products.created_at');
            } else {
                $query->orderByDesc('saved_products.created_at');
            }

            $products = $query->get();
            $shops = DB::table('saved_products')
                ->join('products', 'products.id', '=', 'saved_products.product_id')
                ->join('users', 'users.id', '=', 'products.seller_id')
                ->where('saved_products.user_id', $request->user()->id)
                ->where('products.status', 'active')
                ->where('products.approval_status', 'approved')
                ->whereNotIn('users.status', ['suspended', 'deactivated', 'banned'])
                ->select('users.id', 'users.shop_name', 'users.name')
                ->distinct()
                ->orderBy('users.shop_name')
                ->get();
            $savedCount = DB::table('saved_products')->where('user_id', $request->user()->id)->count();
        } catch (Throwable $exception) {
            report($exception);
            $loadError = true;
        }

        return view('buyer.wishlist.index', [
            'products' => $products,
            'savedCount' => $savedCount,
            'shops' => $shops,
            'selectedShop' => (string) $shopId,
            'filter' => $filter,
            'sort' => $sort,
            'loadError' => $loadError,
        ]);
    }

    public function apiIndex(Request $request): JsonResponse
    {
        $products = Product::query()
            ->approved()
            ->join('saved_products', 'saved_products.product_id', '=', 'products.id')
            ->where('saved_products.user_id', $request->user()->id)
            ->select('products.*', 'saved_products.created_at as saved_at')
            ->with('seller')
            ->orderByDesc('saved_products.created_at')
            ->get();

        return response()->json([
            'count' => DB::table('saved_products')->where('user_id', $request->user()->id)->count(),
            'items' => $products->map(fn (Product $product) => [
                'id' => $product->id,
                'name' => $product->name,
                'shop' => $product->seller?->shop_name ?: ($product->seller?->name ?: 'Lumora seller'),
                'image_url' => $product->image_url,
                'price' => (float) $product->price,
                'discount_percent' => (float) $product->discount_percent,
                'stock' => (int) $product->stock,
                'saved_at' => $product->saved_at,
            ])->values(),
        ]);
    }

    public function add(Request $request): JsonResponse
    {
        $validated = $request->validate(['product_id' => ['required', 'integer', 'exists:products,id']]);
        $product = Product::query()->approved()->findOrFail($validated['product_id']);

        DB::table('saved_products')->insertOrIgnore([
            'user_id' => $request->user()->id,
            'product_id' => $product->id,
            'created_at' => now(),
            'updated_at' => now(),
        ]);

        return response()->json([
            'saved' => true,
            'count' => DB::table('saved_products')->where('user_id', $request->user()->id)->count(),
            'message' => 'Saved to your wishlist.',
        ]);
    }

    public function remove(Request $request, int $productId): JsonResponse
    {
        DB::table('saved_products')
            ->where('user_id', $request->user()->id)
            ->where('product_id', $productId)
            ->delete();

        return response()->json([
            'saved' => false,
            'count' => DB::table('saved_products')->where('user_id', $request->user()->id)->count(),
            'message' => 'Removed from your wishlist.',
        ]);
    }

    public function toggle(Request $request, Product $product): JsonResponse
    {
        abort_unless($product->approval_status === 'approved' && $product->status === 'active', 404);
        $query = DB::table('saved_products')->where('user_id', $request->user()->id)->where('product_id', $product->id);
        if ($query->exists()) {
            $query->delete();
            $saved = false;
        } else {
            DB::table('saved_products')->insertOrIgnore([
                'user_id' => $request->user()->id,
                'product_id' => $product->id,
                'created_at' => now(), 'updated_at' => now(),
            ]);
            $saved = true;
        }
        return response()->json([
            'saved' => $saved,
            'count' => DB::table('saved_products')->where('user_id', $request->user()->id)->count(),
            'message' => $saved ? 'Saved to your wishlist.' : 'Removed from your wishlist.',
        ]);
    }
}
