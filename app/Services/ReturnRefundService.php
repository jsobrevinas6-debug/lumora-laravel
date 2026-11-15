<?php

namespace App\Services;

use App\Models\Order;
use App\Models\ReturnRequest;
use App\Models\User;
use App\Notifications\ReturnRequestStatusNotification;
use Carbon\Carbon;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Str;

/**
 * Shared business logic for Return & Refund requests, disputes, refunds, and payable-order queries.
 */
class ReturnRefundService
{
    public const RETURN_WINDOW_DAYS = 7;

    public const REASON_CODES = [
        'damaged',
        'wrong_item',
        'missing_items',
        'not_as_described',
        'changed_mind',
        'other',
    ];

    public const SOLUTION_REFUND = 'refund';

    public const SOLUTION_EXCHANGE = 'exchange';

    /**
     * Normalize mobile/web return reasons into one of the six canonical codes.
     */
    public static function normalizeReason(?string $raw): string
    {
        $clean = strtolower(trim((string) $raw));
        if (in_array($clean, self::REASON_CODES, true)) {
            return $clean;
        }

        return match (true) {
            str_contains($clean, 'damage') || str_contains($clean, 'defect') || str_contains($clean, 'broken') => 'damaged',
            str_contains($clean, 'wrong') => 'wrong_item',
            str_contains($clean, 'missing') || str_contains($clean, 'incomplete') => 'missing_items',
            str_contains($clean, 'described') || str_contains($clean, 'fake') || str_contains($clean, 'counterfeit') => 'not_as_described',
            str_contains($clean, 'mind') || str_contains($clean, 'changed') => 'changed_mind',
            default => 'other',
        };
    }

    /**
     * Normalize buyer resolution preference into 'refund' or 'exchange'.
     */
    public static function normalizeSolution(?string $raw): string
    {
        $clean = strtolower(trim((string) $raw));
        if (str_contains($clean, 'exchange') || str_contains($clean, 'replace')) {
            return self::SOLUTION_EXCHANGE;
        }

        return self::SOLUTION_REFUND;
    }

    /**
     * Determine when an order was delivered using delivered_at or status history fallback.
     */
    public static function resolveDeliveredAt(Order $order): ?Carbon
    {
        if ($order->delivered_at) {
            return Carbon::parse($order->delivered_at);
        }

        $deliveredEvent = $order->statusHistories()
            ->where(function ($q) {
                $q->whereIn('status', ['delivered', 'completed'])
                    ->orWhereIn('tracking_status', ['delivered', 'completed']);
            })
            ->latest('created_at')
            ->first();

        if ($deliveredEvent?->created_at) {
            return Carbon::parse($deliveredEvent->created_at);
        }

        return null;
    }

    /**
     * Check whether the order is still within the 7-day return window from delivery.
     */
    public static function isWithinReturnWindow(Order $order): bool
    {
        $deliveredAt = self::resolveDeliveredAt($order);
        if (! $deliveredAt) {
            return true;
        }

        return $deliveredAt->diffInDays(now()) <= self::RETURN_WINDOW_DAYS;
    }

    /**
     * Submit a new return/refund claim and store optional photo/video or base64 evidence privately.
     *
     * @param  array<string, mixed>  $data
     * @param  array<int, UploadedFile>  $uploadedFiles
     * @param  array<int, string>  $inlineDataUris
     */
    public static function submitReturnRequest(
        Order $order,
        ?User $buyer,
        array $data,
        array $uploadedFiles = [],
        array $inlineDataUris = []
    ): ReturnRequest {
        abort_unless(Schema::hasTable('return_requests'), 503, 'Return requests are temporarily unavailable.');

        $reason = self::normalizeReason($data['reason'] ?? 'other');
        $solution = self::normalizeSolution($data['preferred_solution'] ?? null);
        $details = trim((string) ($data['details'] ?? ''));
        $buyerId = $buyer?->id ?? $order->user_id;

        if (mb_strlen($details) < 10) {
            abort(422, 'Please provide at least 10 characters explaining the return/refund reason.');
        }
        if (mb_strlen($details) > 2000) {
            abort(422, 'Return explanation cannot exceed 2,000 characters.');
        }

        return DB::transaction(function () use ($order, $buyerId, $reason, $solution, $details, $uploadedFiles, $inlineDataUris) {
            $lockedOrder = Order::query()
                ->lockForUpdate()
                ->with(['statusHistories'])
                ->findOrFail($order->id);

            abort_unless(
                strtolower((string) $lockedOrder->status) === 'delivered',
                422,
                'Return requests are available for delivered orders only.'
            );

            abort_unless(
                self::isWithinReturnWindow($lockedOrder),
                422,
                'The 7-day return window for this order has expired.'
            );

            abort_if(
                $lockedOrder->returnRequest()->exists(),
                409,
                'A return request has already been submitted for this order.'
            );

            $payload = [
                'buyer_id' => $buyerId,
                'reason' => $reason,
                'details' => $details,
                'status' => 'pending',
            ];

            if (Schema::hasColumn('return_requests', 'preferred_solution')) {
                $payload['preferred_solution'] = $solution;
            }
            if (Schema::hasColumn('return_requests', 'refund_amount')) {
                $payload['refund_amount'] = round((float) $lockedOrder->total, 2);
            }
            if (Schema::hasColumn('return_requests', 'refund_status')) {
                $payload['refund_status'] = $solution === self::SOLUTION_EXCHANGE ? 'not_applicable' : 'pending';
            }

            $returnRequest = $lockedOrder->returnRequest()->create($payload);

            self::storeEvidenceFiles($returnRequest, $uploadedFiles, $inlineDataUris);

            $reasonLabel = ucwords(str_replace('_', ' ', $reason));
            $solutionLabel = $solution === self::SOLUTION_EXCHANGE ? 'Exchange' : 'Refund';

            $lockedOrder->recordStatusUpdate(
                'return_requested',
                "Buyer submitted a {$solutionLabel} request ({$reasonLabel}). Awaiting seller review.",
                event: [
                    'tracking_status' => 'return_requested',
                    'tracking_label' => 'Return Requested',
                    'changed_by' => $buyerId,
                ]
            );

            return $returnRequest->fresh(['evidence', 'logisticsNotification']);
        });
    }

    /**
     * Approve a return request (by Seller on pending, or Admin during review/dispute arbitration).
     * Processes order return lifecycle, refund accounting, stock adjustment, and logistics dispatch.
     */
    public static function approveReturnRequest(
        ReturnRequest $returnRequest,
        int $actorId,
        ?string $note = null,
        bool $isAdminOverride = false,
        string $actorRole = 'seller'
    ): array {
        return DB::transaction(function () use ($returnRequest, $actorId, $note, $isAdminOverride, $actorRole) {
            $lockedRequest = ReturnRequest::query()
                ->lockForUpdate()
                ->with(['order.items.product', 'order.statusHistories', 'buyer', 'evidence'])
                ->findOrFail($returnRequest->id);

            $allowedStatuses = $isAdminOverride ? ['pending', 'denied'] : ['pending'];
            abort_unless(
                in_array($lockedRequest->status, $allowedStatuses, true),
                409,
                'This request has already been reviewed.'
            );

            $order = Order::query()
                ->lockForUpdate()
                ->with(['items.product', 'statusHistories'])
                ->findOrFail($lockedRequest->order_id);

            $previousOrderStatus = strtolower((string) $order->status);
            $solution = self::normalizeSolution($lockedRequest->preferred_solution ?? self::SOLUTION_REFUND);
            $cleanNote = $note !== null && trim($note) !== '' ? trim($note) : $lockedRequest->admin_note;

            $updates = [
                'status' => 'approved',
                'admin_note' => $cleanNote,
                'reviewed_at' => now(),
            ];
            if (Schema::hasColumn('return_requests', 'resolved_by')) {
                $updates['resolved_by'] = $actorId;
            }
            if (Schema::hasColumn('return_requests', 'dispute_status') && $lockedRequest->dispute_status === 'under_arbitration') {
                $updates['dispute_status'] = 'resolved_approved';
            }

            $refundProcessed = false;
            $refundAmount = round((float) ($lockedRequest->refund_amount ?? $order->total), 2);
            $canRefund = $solution === self::SOLUTION_REFUND
                && ($order->payment_status === 'paid'
                    || (strtolower((string) $order->payment_method) === 'cod' && in_array($previousOrderStatus, ['delivered', 'returned'], true)));

            if ($solution === self::SOLUTION_REFUND && $canRefund) {
                $refundProcessed = true;
                $order->payment_status = 'refunded';
                if (Schema::hasColumn('orders', 'refund_amount')) {
                    $order->refund_amount = $refundAmount;
                }
                if (Schema::hasColumn('orders', 'refunded_at')) {
                    $order->refunded_at = now();
                }
                $order->save();

                if (Schema::hasColumn('return_requests', 'refund_status')) {
                    $updates['refund_status'] = 'refunded';
                }
                if (Schema::hasColumn('return_requests', 'refund_amount')) {
                    $updates['refund_amount'] = $refundAmount;
                }
                if (Schema::hasColumn('return_requests', 'refunded_at')) {
                    $updates['refunded_at'] = now();
                }
            } elseif (Schema::hasColumn('return_requests', 'refund_status')) {
                $updates['refund_status'] = $solution === self::SOLUTION_EXCHANGE ? 'not_applicable' : ($order->payment_status === 'refunded' ? 'refunded' : 'pending');
            }

            $lockedRequest->update($updates);
            $lockedRequest->logisticsNotification()->firstOrCreate(['status' => 'pending']);

            $actorLabel = $actorRole === 'admin' ? 'Lumora Admin' : 'seller';
            $order->updateStatus(
                'returned',
                "Return request approved by {$actorLabel}." . ($cleanNote ? " Note: {$cleanNote}" : ' Queued for return pickup by Lumora Logistics.'),
                event: [
                    'tracking_status' => 'return_approved',
                    'tracking_label' => 'Return Approved',
                    'changed_by' => $actorId,
                ]
            );

            if ($refundProcessed) {
                $order->recordStatusUpdate(
                    'refunded',
                    'Refund of PHP ' . number_format($refundAmount, 2) . ' issued to buyer for approved return.',
                    event: [
                        'tracking_status' => 'refunded',
                        'tracking_label' => 'Refund Issued',
                        'changed_by' => $actorId,
                    ]
                );
            }

            // Adjust inventory/sales stats only on approved return (avoid double adjustment if already 'returned')
            if ($previousOrderStatus !== 'returned') {
                self::adjustInventoryForApprovedReturn($order, (string) $lockedRequest->reason);
            }

            $lockedRequest->setRelation('order', $order->fresh(['items.product', 'statusHistories', 'user', 'seller']));
            $dispatchResult = LogisticsReturnService::dispatchReturnToLogistics($lockedRequest, $cleanNote);

            self::notifyBuyer($lockedRequest, 'approved', $cleanNote);

            return array_merge($dispatchResult, [
                'refund_processed' => $refundProcessed,
                'refund_amount' => $refundProcessed ? $refundAmount : 0.0,
            ]);
        });
    }

    /**
     * Deny a return request (by Seller on pending, or Admin during review/dispute arbitration).
     */
    public static function denyReturnRequest(
        ReturnRequest $returnRequest,
        int $actorId,
        string $note,
        bool $isAdminOverride = false,
        string $actorRole = 'seller'
    ): ReturnRequest {
        $cleanNote = trim($note);
        abort_if($cleanNote === '', 422, 'Please provide a reason when denying a return request.');

        return DB::transaction(function () use ($returnRequest, $actorId, $cleanNote, $isAdminOverride, $actorRole) {
            $lockedRequest = ReturnRequest::query()
                ->lockForUpdate()
                ->with(['order', 'buyer'])
                ->findOrFail($returnRequest->id);

            $allowedStatuses = $isAdminOverride ? ['pending', 'denied'] : ['pending'];
            abort_unless(
                in_array($lockedRequest->status, $allowedStatuses, true),
                409,
                'This request has already been reviewed.'
            );

            $order = Order::query()->lockForUpdate()->findOrFail($lockedRequest->order_id);

            $updates = [
                'status' => 'denied',
                'admin_note' => $cleanNote,
                'reviewed_at' => now(),
            ];
            if (Schema::hasColumn('return_requests', 'resolved_by')) {
                $updates['resolved_by'] = $actorId;
            }
            if (Schema::hasColumn('return_requests', 'refund_status')) {
                $updates['refund_status'] = 'not_applicable';
            }
            if (Schema::hasColumn('return_requests', 'dispute_status') && $lockedRequest->dispute_status === 'under_arbitration') {
                $updates['dispute_status'] = 'resolved_denied';
            }

            $lockedRequest->update($updates);

            // Restore delivered status if an earlier client/endpoint prematurely set it to 'returned'
            if (strtolower((string) $order->status) === 'returned') {
                $order->status = 'delivered';
                $order->save();
            }

            $actorLabel = $actorRole === 'admin' ? 'Lumora Admin' : 'seller';
            $order->recordStatusUpdate(
                'return_denied',
                "Return request was reviewed and denied by {$actorLabel}: {$cleanNote}",
                event: [
                    'tracking_status' => 'return_denied',
                    'tracking_label' => 'Return Denied',
                    'changed_by' => $actorId,
                ]
            );

            self::notifyBuyer($lockedRequest, 'denied', $cleanNote);

            return $lockedRequest->fresh(['order', 'buyer', 'evidence']);
        });
    }

    /**
     * Escalate a pending or seller-denied return request to Lumora Admin for formal dispute arbitration.
     */
    public static function escalateDispute(Order $order, ?User $buyer, ?string $notes = null): ReturnRequest
    {
        abort_unless(Schema::hasTable('return_requests'), 503, 'Return dispute handling is temporarily unavailable.');

        $buyerId = $buyer?->id ?? $order->user_id;
        $cleanNotes = trim((string) $notes);

        return DB::transaction(function () use ($order, $buyerId, $cleanNotes) {
            $lockedOrder = Order::query()->lockForUpdate()->with('returnRequest')->findOrFail($order->id);
            $rr = $lockedOrder->returnRequest;

            // Bridge legacy mobile orders that were previously placed straight into 'returned' without a ReturnRequest
            if (! $rr && strtolower((string) $lockedOrder->status) === 'returned') {
                $rr = $lockedOrder->returnRequest()->create([
                    'buyer_id' => $buyerId,
                    'reason' => 'other',
                    'details' => $cleanNotes !== '' ? $cleanNotes : 'Buyer escalated return dispute for review.',
                    'status' => 'pending',
                ]);
            }

            abort_if(! $rr, 422, 'Please submit a return request before escalating a dispute.');
            abort_if($rr->status === 'approved', 422, 'This return request has already been approved.');

            $lockedRequest = ReturnRequest::query()->lockForUpdate()->findOrFail($rr->id);
            if (Schema::hasColumn('return_requests', 'dispute_status')) {
                abort_if(
                    $lockedRequest->dispute_status === 'under_arbitration',
                    409,
                    'This dispute is already escalated to Lumora Admin.'
                );
                abort_if(
                    in_array($lockedRequest->dispute_status, ['resolved_approved', 'resolved_denied'], true),
                    422,
                    'Lumora Admin has already issued a final decision on this dispute.'
                );
            }

            $updates = [];
            if (Schema::hasColumn('return_requests', 'dispute_status')) {
                $updates['dispute_status'] = 'under_arbitration';
            }
            if (Schema::hasColumn('return_requests', 'disputed_at')) {
                $updates['disputed_at'] = now();
            }
            if (Schema::hasColumn('return_requests', 'dispute_notes') && $cleanNotes !== '') {
                $updates['dispute_notes'] = $cleanNotes;
            }
            if ($updates !== []) {
                $lockedRequest->update($updates);
            }

            $lockedOrder->recordStatusUpdate(
                'disputed',
                trim('Buyer escalated dispute to Lumora Admin for arbitration. ' . $cleanNotes),
                event: [
                    'tracking_status' => 'disputed',
                    'tracking_label' => 'Dispute Escalated to Admin',
                    'changed_by' => $buyerId,
                ]
            );

            return $lockedRequest->fresh(['order', 'buyer', 'evidence', 'logisticsNotification']);
        });
    }

    /**
     * Mark a cancelled order as refunded when payment was already confirmed.
     */
    public static function markCancelledRefundIfPaid(Order $order): bool
    {
        if (strtolower((string) $order->payment_status) !== 'paid') {
            return false;
        }

        $refundAmount = round((float) $order->total, 2);
        $order->payment_status = 'refunded';
        if (Schema::hasColumn('orders', 'refund_amount')) {
            $order->refund_amount = $refundAmount;
        }
        if (Schema::hasColumn('orders', 'refunded_at')) {
            $order->refunded_at = now();
        }
        $order->save();

        $order->recordStatusUpdate(
            'refunded',
            'Refund of PHP ' . number_format($refundAmount, 2) . ' recorded for cancelled paid order.',
            event: [
                'tracking_status' => 'refunded',
                'tracking_label' => 'Refund Recorded',
            ]
        );

        return true;
    }

    /**
     * Constrain revenue/commission/payout queries strictly to settled, non-cancelled, non-returned orders.
     */
    public static function applyPayableOrderFilter($query, string $alias = 'o')
    {
        return $query
            ->where("{$alias}.payment_status", 'paid')
            ->whereNotIn("{$alias}.status", ['cancelled', 'returned']);
    }

    /**
     * @param  array<int, UploadedFile>  $uploadedFiles
     * @param  array<int, string>  $inlineDataUris
     */
    private static function storeEvidenceFiles(ReturnRequest $returnRequest, array $uploadedFiles, array $inlineDataUris): void
    {
        if (! Schema::hasTable('return_request_evidence')) {
            return;
        }

        $stored = 0;
        $diskName = class_exists(\App\Support\ReturnEvidenceFiles::class)
            ? \App\Support\ReturnEvidenceFiles::diskName()
            : 'local';

        foreach ($uploadedFiles as $file) {
            if ($stored >= 5 || ! $file instanceof UploadedFile || ! $file->isValid()) {
                continue;
            }
            $returnRequest->evidence()->create([
                'file_path' => $file->store('return_request_evidence', $diskName),
                'mime_type' => $file->getMimeType() ?: 'image/jpeg',
            ]);
            $stored++;
        }

        foreach ($inlineDataUris as $dataUri) {
            if ($stored >= 5) {
                break;
            }
            $trimmed = trim((string) $dataUri);
            if (! preg_match('/^data:(image\/[a-zA-Z0-9.+-]+);base64,(.+)$/s', $trimmed, $m)) {
                continue;
            }
            $mime = strtolower($m[1]);
            $binary = base64_decode($m[2], true);
            if ($binary === false || strlen($binary) === 0 || strlen($binary) > 50 * 1024 * 1024) {
                continue;
            }
            $ext = match ($mime) {
                'image/png' => 'png',
                'image/webp' => 'webp',
                default => 'jpg',
            };
            $path = 'return_request_evidence/' . Str::uuid()->toString() . '.' . $ext;
            Storage::disk($diskName)->put($path, $binary);
            $returnRequest->evidence()->create([
                'file_path' => $path,
                'mime_type' => $mime === 'image/jpg' ? 'image/jpeg' : $mime,
            ]);
            $stored++;
        }
    }

    private static function adjustInventoryForApprovedReturn(Order $order, string $reason): void
    {
        $restockItems = $reason !== 'damaged';
        $hasVariantsTable = Schema::hasTable('product_variants');

        foreach ($order->items as $item) {
            $qty = max(1, (int) $item->quantity);

            if ($restockItems) {
                if (! empty($item->variant_id) && $hasVariantsTable) {
                    DB::table('product_variants')
                        ->where('id', (int) $item->variant_id)
                        ->increment('stock', $qty);
                }
                if ($item->product) {
                    $item->product->increment('stock', $qty);
                }
            }

            if ($item->product && (int) $item->product->sales_count > 0) {
                $item->product->decrement('sales_count', min($qty, (int) $item->product->sales_count));
            }
        }
    }

    private static function notifyBuyer(ReturnRequest $returnRequest, string $status, ?string $note): void
    {
        try {
            $returnRequest->buyer?->notify(new ReturnRequestStatusNotification($returnRequest, $status, $note));
        } catch (\Throwable $e) {
            Log::warning('Buyer return status notification failed: ' . $e->getMessage());
        }
    }
}
