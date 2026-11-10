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
    public function index()
    {
        $requests = ReturnRequest::query()
            ->whereHas('order.items', fn ($query) => $query->where('seller_id', auth()->id()))
            ->with(['order.items.product', 'buyer', 'evidence', 'logisticsNotification'])
            ->latest()
            ->paginate(20);

        return view('seller.returns', compact('requests'));
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
        $this->review($returnRequest, 'approved');

        return redirect()->route('seller.returns.index')->with('success', 'Return approved and queued for Lumora Logistics.');
    }

    public function deny(Request $request, ReturnRequest $returnRequest)
    {
        $validated = $request->validate(['seller_note' => ['required', 'string', 'max:1000']]);
        $this->review($returnRequest, 'denied', $validated['seller_note']);

        return redirect()->route('seller.returns.index')->with('success', 'Return/refund request denied.');
    }

    private function review(ReturnRequest $returnRequest, string $status, ?string $note = null): void
    {
        $this->authorizeSeller($returnRequest);

        DB::transaction(function () use ($returnRequest, $status, $note) {
            $lockedRequest = ReturnRequest::query()->lockForUpdate()->findOrFail($returnRequest->id);
            abort_unless($lockedRequest->status === 'pending', 409, 'This request has already been reviewed.');
            $lockedRequest->update(['status' => $status, 'admin_note' => $note, 'reviewed_at' => now()]);

            if ($status === 'approved') {
                $lockedRequest->logisticsNotification()->create(['status' => 'pending']);
            }

            $lockedRequest->buyer->notify(new ReturnRequestStatusNotification($lockedRequest, $status, $note));
        });
    }

    private function authorizeSeller(ReturnRequest $returnRequest): void
    {
        abort_unless($returnRequest->order()->whereHas('items', fn ($query) => $query->where('seller_id', auth()->id()))->exists(), 404);
    }
}
