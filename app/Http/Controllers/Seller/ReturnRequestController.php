<?php

namespace App\Http\Controllers\Seller;

use App\Http\Controllers\Controller;
use App\Models\ReturnRequest;
use App\Notifications\ReturnRequestStatusNotification;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Storage;

class ReturnRequestController extends Controller
{
    public function index(Request $request)
    {
        $sellerId = auth()->id();
        $status = $request->query('status', 'all');
        $search = trim((string) $request->query('search', ''));

        $baseQuery = ReturnRequest::query()
            ->whereHas('order.items', fn ($query) => $query->where('seller_id', $sellerId));

        $tabCounts = [
            'all' => (clone $baseQuery)->count(),
            'pending' => (clone $baseQuery)->where('status', 'pending')->count(),
            'approved' => (clone $baseQuery)->where('status', 'approved')->count(),
            'denied' => (clone $baseQuery)->where('status', 'denied')->count(),
        ];

        $requestsQuery = (clone $baseQuery)
            ->with(['order.items.product', 'order.statusHistories', 'buyer', 'evidence', 'logisticsNotification'])
            ->latest();

        if (in_array($status, ['pending', 'approved', 'denied'], true)) {
            $requestsQuery->where('status', $status);
        }

        if ($search !== '') {
            $requestsQuery->where(function ($q) use ($search) {
                $q->whereHas('order', fn ($oq) => $oq->where('order_number', 'like', "%{$search}%"))
                  ->orWhereHas('buyer', fn ($bq) => $bq->where('name', 'like', "%{$search}%")->orWhere('email', 'like', "%{$search}%"))
                  ->orWhere('reason', 'like', "%{$search}%")
                  ->orWhere('details', 'like', "%{$search}%");
            });
        }

        $requests = $requestsQuery->paginate(20)->withQueryString();

        return view('seller.returns', compact('requests', 'tabCounts', 'status', 'search'));
    }

    public function evidence(ReturnRequest $returnRequest, int $evidence)
    {
        $this->authorizeSeller($returnRequest);
        $file = $returnRequest->evidence()->findOrFail($evidence);
        $path = ltrim(str_replace('\\', '/', (string) $file->file_path), '/');
        abort_unless(str_starts_with($path, 'return_request_evidence/') && ! preg_match('#(^|/)\.\.?(/|$)#', $path), 404);
        $disk = Storage::disk('local');
        abort_unless($disk->exists($path), 404);

        return response()->file($disk->path($path), [
            'Content-Type' => $file->mime_type,
            'Content-Disposition' => 'inline; filename="'.basename($path).'"',
            'X-Content-Type-Options' => 'nosniff',
            'Cache-Control' => 'private, no-store',
        ]);
    }

    public function approve(ReturnRequest $returnRequest)
    {
        $result = $this->review($returnRequest, 'approved');
        $courier = $result['courier_name'] ?? 'delivery courier';

        return back()->with('success', "Return approved! Lumora Logistics notified with items list and automatically assigned to {$courier} for return pickup.");
    }

    public function deny(Request $request, ReturnRequest $returnRequest)
    {
        $validated = $request->validate(['seller_note' => ['required', 'string', 'max:1000']]);
        $this->review($returnRequest, 'denied', $validated['seller_note']);

        return back()->with('success', 'Return/refund request has been denied.');
    }

    private function review(ReturnRequest $returnRequest, string $status, ?string $note = null): array
    {
        $this->authorizeSeller($returnRequest);

        return DB::transaction(function () use ($returnRequest, $status, $note) {
            $lockedRequest = ReturnRequest::query()->lockForUpdate()->findOrFail($returnRequest->id);
            abort_unless($lockedRequest->status === 'pending', 409, 'This request has already been reviewed.');
            $lockedRequest->update(['status' => $status, 'admin_note' => $note, 'reviewed_at' => now()]);

            $dispatchResult = [];

            if ($status === 'approved') {
                $lockedRequest->logisticsNotification()->firstOrCreate(['status' => 'pending']);

                // Synchronize order lifecycle to 'returned' so tracking & status histories update
                $lockedRequest->order->updateStatus('returned', 'Return request approved by seller. Queued for return pickup by Lumora Logistics.', event: [
                    'tracking_status' => 'return_approved',
                    'tracking_label' => 'Return Approved',
                    'changed_by' => auth()->id(),
                ]);

                // Dispatch full return package to Lumora Logistics and automatically assign to delivering rider
                $dispatchResult = \App\Services\LogisticsReturnService::dispatchReturnToLogistics($lockedRequest, $note);
            } else {
                // Record the denial in order history without changing base lifecycle
                $lockedRequest->order->recordStatusUpdate('return_denied', 'Return request was reviewed and denied by seller' . ($note ? ': ' . $note : '.'), event: [
                    'tracking_status' => 'return_denied',
                    'tracking_label' => 'Return Denied',
                    'changed_by' => auth()->id(),
                ]);
            }

            try {
                $lockedRequest->buyer->notify(new ReturnRequestStatusNotification($lockedRequest, $status, $note));
            } catch (\Throwable $e) {
                \Illuminate\Support\Facades\Log::warning('Buyer return status notification failed: ' . $e->getMessage());
            }

            return $dispatchResult;
        });
    }

    private function authorizeSeller(ReturnRequest $returnRequest): void
    {
        abort_unless($returnRequest->order()->whereHas('items', fn ($query) => $query->where('seller_id', auth()->id()))->exists(), 404);
    }
}
