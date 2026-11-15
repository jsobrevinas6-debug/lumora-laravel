<?php

namespace App\Http\Controllers\Seller;

use App\Http\Controllers\Controller;
use App\Models\ReturnRequest;
use App\Services\ReturnRefundService;
use App\Support\ReturnEvidenceFiles;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Schema;

class ReturnRequestController extends Controller
{
    public function index(Request $request)
    {
        $sellerId = auth()->id();
        $status = $request->query('status', 'all');
        $search = trim((string) $request->query('search', ''));
        $hasDisputeCol = Schema::hasColumn('return_requests', 'dispute_status');

        $baseQuery = ReturnRequest::query()
            ->whereHas('order.items', fn ($query) => $query->where('seller_id', $sellerId));

        $tabCounts = [
            'all' => (clone $baseQuery)->count(),
            'pending' => (clone $baseQuery)->where('status', 'pending')->count(),
            'disputed' => $hasDisputeCol ? (clone $baseQuery)->where('dispute_status', 'under_arbitration')->count() : 0,
            'approved' => (clone $baseQuery)->where('status', 'approved')->count(),
            'denied' => (clone $baseQuery)->where('status', 'denied')->count(),
        ];

        $requestsQuery = (clone $baseQuery)
            ->with(['order.items.product', 'order.statusHistories', 'buyer', 'evidence', 'logisticsNotification'])
            ->latest();

        if (in_array($status, ['pending', 'approved', 'denied'], true)) {
            $requestsQuery->where('status', $status);
        } elseif ($status === 'disputed' && $hasDisputeCol) {
            $requestsQuery->where('dispute_status', 'under_arbitration');
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
        $file = $returnRequest->evidence()->findOrFail($evidence);
        $path = ltrim(str_replace('\\', '/', (string) $file->file_path), '/');
        $path = preg_replace('#^(?:public/|storage/)+#', '', $path);
        abort_unless(str_starts_with($path, 'return_request_evidence/'), 404);

        return ReturnEvidenceFiles::response($file);
    }

    public function approve(ReturnRequest $returnRequest)
    {
        $this->authorizeSeller($returnRequest);

        $result = ReturnRefundService::approveReturnRequest(
            $returnRequest,
            (int) auth()->id(),
            null,
            false,
            'seller'
        );

        $courier = $result['dispatch']['courier_name'] ?? 'delivery courier';

        return back()->with('success', "Return approved! Refund processed (if applicable) and Lumora Logistics assigned to {$courier} for pickup.");
    }

    public function deny(Request $request, ReturnRequest $returnRequest)
    {
        $this->authorizeSeller($returnRequest);
        $validated = $request->validate(['seller_note' => ['required', 'string', 'max:1000']]);

        ReturnRefundService::denyReturnRequest(
            $returnRequest,
            (int) auth()->id(),
            $validated['seller_note'],
            false,
            'seller'
        );

        return back()->with('success', 'Return/refund request has been denied.');
    }

    private function authorizeSeller(ReturnRequest $returnRequest): void
    {
        abort_unless($returnRequest->order()->whereHas('items', fn ($query) => $query->where('seller_id', auth()->id()))->exists(), 404);
    }
}
