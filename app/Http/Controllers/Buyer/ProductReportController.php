<?php

namespace App\Http\Controllers\Buyer;

use App\Http\Controllers\Controller;
use App\Models\Product;
use Illuminate\Database\QueryException;
use Illuminate\Http\Request;
use Illuminate\Validation\Rule;

class ProductReportController extends Controller
{
    public const REASONS = [
        'Counterfeit or fake product',
        'Misleading product description',
        'Inappropriate product',
        'Wrong product images',
        'Suspicious seller',
        'Other',
    ];

    public function store(Request $request, Product $product)
    {
        abort_unless($product->status === 'active', 404);

        $validated = $request->validate([
            'reason' => ['required', 'string', Rule::in(self::REASONS)],
            'details' => ['nullable', 'string', 'max:2000'],
        ]);

        $reporterId = (int) $request->user()->id;
        $alreadyReported = \DB::table('complaints')
            ->where('product_id', $product->id)
            ->where('product_reporter_id', $reporterId)
            ->exists();

        if ($alreadyReported) {
            return back()->with('error', 'You have already reported this product.');
        }

        try {
            \DB::table('complaints')->insert([
                'buyer_id' => $reporterId,
                'seller_id' => $product->seller_id,
                'product_id' => $product->id,
                'category' => $validated['reason'],
                'description' => trim((string) ($validated['details'] ?? '')) ?: 'No additional details provided.',
                'status' => 'pending',
                'complaint_type' => 'product_report',
                'product_reporter_id' => $reporterId,
                'created_at' => now(),
                'updated_at' => now(),
            ]);
        } catch (QueryException $exception) {
            // The unique index handles two submissions racing for the same product.
            if (\DB::table('complaints')->where('product_id', $product->id)->where('product_reporter_id', $reporterId)->exists()) {
                return back()->with('error', 'You have already reported this product.');
            }

            throw $exception;
        }

        return back()->with('success', 'Thank you. Your product report was sent to our team for review.');
    }
}
