<?php

namespace App\Http\Controllers\Buyer;

use App\Http\Controllers\Controller;
use App\Models\Order;
use App\Models\Product;
use App\Models\ProductReview;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Facades\Validator;
use Throwable;

class ProductReviewController extends Controller
{
    public function store(Request $request, Product $product): RedirectResponse
    {
        abort_unless($product->status === 'active', 404);

        $validated = $this->validateReview($request, $product);
        if ($validated instanceof RedirectResponse) {
            return $validated;
        }
        $order = $this->deliveredOrderFor($request, $product);

        if (! $order) {
            return back()->with('error', 'Only buyers who have received this product can leave a review.');
        }

        return $this->saveReview($request, $product, $validated, $order);
    }

    public function update(Request $request, Product $product, ProductReview $review): RedirectResponse
    {
        abort_unless((int) $review->product_id === (int) $product->id, 404);
        abort_unless((int) $review->user_id === (int) $request->user()->id, 403);

        $validated = $this->validateReview($request, $product);
        if ($validated instanceof RedirectResponse) {
            return $validated;
        }

        return $this->saveReview($request, $product, $validated, null, $review);
    }

    public function destroy(Request $request, Product $product, ProductReview $review): RedirectResponse
    {
        abort_unless((int) $review->product_id === (int) $product->id, 404);
        abort_unless((int) $review->user_id === (int) $request->user()->id, 403);

        $media = $review->media ?? [];
        $review->delete();
        Storage::disk('public')->delete($media);

        return redirect()->to(route('shop.product', ['id' => $product->id]).'#reviews')
            ->with('success', 'Your review has been deleted.');
    }

    private function validateReview(Request $request, Product $product): array|RedirectResponse
    {
        $validator = Validator::make($request->all(), [
            'rating' => ['required', 'integer', 'min:1', 'max:5'],
            'review' => ['nullable', 'string', 'max:2000'],
            'media' => ['nullable', 'array', 'max:4'],
            'media.*' => ['file', 'mimes:jpg,jpeg,png,webp,gif,mp4,mov,webm', 'max:20480'],
        ]);

        if ($validator->fails()) {
            return redirect()->to(route('shop.product', ['id' => $product->id]).'#reviews')
                ->withErrors($validator)
                ->withInput();
        }

        return $validator->validated();
    }

    private function saveReview(
        Request $request,
        Product $product,
        array $validated,
        ?Order $order,
        ?ProductReview $existingReview = null
    ): RedirectResponse {
        $review = $existingReview ?: ProductReview::firstOrNew([
            'user_id' => $request->user()->id,
            'product_id' => $product->id,
        ]);
        $currentMedia = $review->media ?? [];
        $uploads = array_values(array_filter((array) $request->file('media', [])));

        if (count($currentMedia) + count($uploads) > 4) {
            return redirect()->to(route('shop.product', ['id' => $product->id]).'#reviews')
                ->withErrors(['media' => 'A review can include up to 4 photos or videos in total.'])
                ->withInput();
        }

        $newMedia = [];
        try {
            foreach ($uploads as $file) {
                $path = $file->store('product-reviews/'.$product->id, 'public');
                if (! $path) {
                    throw new \RuntimeException('The review media could not be stored.');
                }
                $newMedia[] = $path;
            }

            $review->fill([
                'user_id' => $request->user()->id,
                'product_id' => $product->id,
                'order_id' => $order?->id ?? $review->order_id,
                'rating' => $validated['rating'],
                'review' => $validated['review'] ?? null,
                'media' => array_values(array_merge($currentMedia, $newMedia)),
            ]);
            $review->save();
        } catch (Throwable $exception) {
            if ($newMedia) {
                Storage::disk('public')->delete($newMedia);
            }
            throw $exception;
        }

        return redirect()->to(route('shop.product', ['id' => $product->id]).'#reviews')
            ->with('success', $existingReview ? 'Your review has been updated.' : 'Your review has been saved.');
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
