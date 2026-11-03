<?php

namespace App\Http\Controllers\Buyer;

use App\Http\Controllers\Controller;
use App\Models\Product;
use Illuminate\Database\QueryException;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;
use Illuminate\Validation\Rule;
use Throwable;

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
            'attachment' => ['nullable', 'file', 'max:10240', 'mimes:jpg,jpeg,png,webp,pdf'],
        ]);

        $reporterId = (int) $request->user()->id;
        $hasReportType = Schema::hasColumn('complaints', 'complaint_type');
        $hasReportUser = Schema::hasColumn('complaints', 'product_reporter_id');
        $hasReportReason = Schema::hasColumn('complaints', 'report_reason');
        $reportMarker = '[Product report: '.$validated['reason'].']';
        $existingReports = DB::table('complaints')->where('product_id', $product->id);
        if ($hasReportUser) {
            $existingReports->where('product_reporter_id', $reporterId);
        } else {
            $existingReports->where('buyer_id', $reporterId)->where('description', 'like', '[Product report:%');
        }
        $alreadyReported = $existingReports->exists();

        if ($alreadyReported) {
            return back()->with('error', 'You have already reported this product.');
        }

        $attachmentPath = null;
        try {
            $details = trim((string) ($validated['details'] ?? '')) ?: 'No additional details provided.';
            $record = [
                'buyer_id' => $reporterId,
                'seller_id' => $product->seller_id,
                'product_id' => $product->id,
                // The production complaints.category column is an enum; `other` is valid there.
                'category' => 'other',
                'description' => ($hasReportType && $hasReportUser && $hasReportReason) ? $details : $reportMarker."\n\n".$details,
                'status' => 'pending',
                'created_at' => now(),
                'updated_at' => now(),
            ];
            if ($hasReportType) $record['complaint_type'] = 'product_report';
            if ($hasReportUser) $record['product_reporter_id'] = $reporterId;
            if ($hasReportReason) $record['report_reason'] = $validated['reason'];
            DB::transaction(function () use ($record, $request, &$attachmentPath) {
                $complaintId = DB::table('complaints')->insertGetId($record);
                if ($request->hasFile('attachment')) {
                    $attachmentPath = $request->file('attachment')->store('complaint_evidence', 'local');
                    if (! $attachmentPath) throw new \RuntimeException('The report attachment could not be stored.');
                    DB::table('complaint_evidence')->insert([
                        'complaint_id' => $complaintId,
                        'image_path' => $attachmentPath,
                        'created_at' => now(),
                        'updated_at' => now(),
                    ]);
                }
            });
        } catch (Throwable $exception) {
            if (! empty($attachmentPath)) Storage::disk('local')->delete($attachmentPath);
            // The unique index handles two submissions racing for the same product.
            $racedReports = DB::table('complaints')->where('product_id', $product->id);
            if ($hasReportUser) $racedReports->where('product_reporter_id', $reporterId);
            else $racedReports->where('buyer_id', $reporterId)->where('description', 'like', '[Product report:%');
            if ($exception instanceof QueryException && $racedReports->exists()) {
                return back()->with('error', 'You have already reported this product.');
            }

            throw $exception;
        }

        return back()->with('success', 'Thank you. Your product report was sent to our team for review.');
    }
}
