<?php

namespace App\Http\Controllers\Buyer;

use App\Http\Controllers\Controller;
use App\Models\Order;
use App\Models\Product;
use App\Models\ProductReview;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;

class ProductReviewController extends Controller
{
    public function store(Request $request, Product $product): RedirectResponse
    {
        abort_unless($product->status === 'active', 404);

        $validated = $this->validateReview($request);
        $order = $this->deliveredOrderFor($request, $product);

        if (! $order) {
            return back()->with('error', 'Only buyers who have received this product can leave a review.');
        }

        ProductReview::updateOrCreate(
            [
                'user_id' => $request->user()->id,
                'product_id' => $product->id,
            ],
            [
                'order_id' => $order->id,
                'rating' => $validated['rating'],
                'review' => $validated['review'] ?? null,
            ]
        );

        return back()->with('success', 'Your review has been saved.');
    }

    public function update(Request $request, Product $product, ProductReview $review): RedirectResponse
    {
        abort_unless((int) $review->product_id === (int) $product->id, 404);
        abort_unless((int) $review->user_id === (int) $request->user()->id, 403);

        $validated = $this->validateReview($request);

        $review->update([
            'rating' => $validated['rating'],
            'review' => $validated['review'] ?? null,
        ]);

        return back()->with('success', 'Your review has been updated.');
    }

    public function destroy(Request $request, Product $product, ProductReview $review): RedirectResponse
    {
        abort_unless((int) $review->product_id === (int) $product->id, 404);
        abort_unless((int) $review->user_id === (int) $request->user()->id, 403);

        $review->delete();

        return back()->with('success', 'Your review has been deleted.');
    }

    private function validateReview(Request $request): array
    {
        return $request->validate([
            'rating' => ['required', 'integer', 'min:1', 'max:5'],
            'review' => ['nullable', 'string', 'max:2000'],
        ]);
    }

    private function deliveredOrderFor(Request $request, Product $product): ?Order
    {
        return Order::query()
            ->where('user_id', $request->user()->id)
            ->where('status', 'delivered')
            ->whereHas('items', function ($query) use ($product) {
                $query->where('product_id', $product->id);
            })
            ->latest('delivered_at')
            ->latest('id')
            ->first();
    }
}
