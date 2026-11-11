<?php

namespace App\Http\Controllers\Seller;

use App\Http\Controllers\Controller;
use App\Models\Order;
use App\Notifications\PayoutRequestStatusNotification;
use App\Notifications\ProductApprovalRejectedNotification;
use Barryvdh\DomPDF\Facade\Pdf;
use Illuminate\Http\RedirectResponse;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\DB;

class OrderController extends Controller
{
    public function index()
    {
        $sellerId = Auth::id();
        $hasVoucherCols = \Illuminate\Support\Facades\Schema::hasColumn('orders', 'voucher_code');
        $hasPaymentMethod = \Illuminate\Support\Facades\Schema::hasColumn('orders', 'payment_method');
        $hasReturnTable = \Illuminate\Support\Facades\Schema::hasTable('return_requests');

        $query = DB::table('order_items as oi')
            ->join('products as p', 'p.id', '=', 'oi.product_id')
            ->join('orders as o', 'o.id', '=', 'oi.order_id')
            ->join('users as u', 'u.id', '=', 'o.user_id');

        if ($hasReturnTable) {
            $query->leftJoin('return_requests as rr', 'rr.order_id', '=', 'o.id');
        }

        $selectCols = [
            'o.id as order_id',
            'o.order_number',
            'o.status',
            'o.created_at as order_date',
            'u.name as buyer_name',
            DB::raw($hasPaymentMethod ? 'o.payment_method' : "'cod' as payment_method"),
            DB::raw($hasVoucherCols ? 'o.voucher_code' : 'NULL as voucher_code'),
            DB::raw($hasVoucherCols ? 'o.voucher_type' : 'NULL as voucher_type'),
            DB::raw($hasVoucherCols ? 'o.voucher_discount' : '0 as voucher_discount'),
            DB::raw($hasVoucherCols ? 'o.shipping_discount' : '0 as shipping_discount'),
            DB::raw('SUM(oi.price * oi.quantity) as seller_subtotal'),
            DB::raw('SUM(CASE WHEN oi.seen_at IS NULL THEN 1 ELSE 0 END) as unseen_count'),
            DB::raw('SUM(CASE WHEN oi.packed_at IS NULL THEN 1 ELSE 0 END) as unpacked_count'),
        ];

        if ($hasReturnTable) {
            $selectCols[] = 'rr.id as return_request_id';
            $selectCols[] = 'rr.status as return_request_status';
            $selectCols[] = 'rr.reason as return_request_reason';
            $selectCols[] = 'rr.created_at as return_request_date';
        } else {
            $selectCols[] = DB::raw('NULL as return_request_id');
            $selectCols[] = DB::raw('NULL as return_request_status');
            $selectCols[] = DB::raw('NULL as return_request_reason');
            $selectCols[] = DB::raw('NULL as return_request_date');
        }

        $groupByCols = array_merge(
            ['o.id', 'o.order_number', 'o.status', 'o.created_at', 'u.name'],
            $hasPaymentMethod ? ['o.payment_method'] : [],
            $hasVoucherCols ? ['o.voucher_code', 'o.voucher_type', 'o.voucher_discount', 'o.shipping_discount'] : [],
            $hasReturnTable ? ['rr.id', 'rr.status', 'rr.reason', 'rr.created_at'] : []
        );

        $allOrders = $query
            ->where(function ($q) use ($sellerId) {
                $q->where('oi.seller_id', $sellerId)
                    ->orWhere('p.seller_id', $sellerId);
            })
            ->select($selectCols)
            ->groupBy(...$groupByCols)
            ->orderByDesc('o.created_at')
            ->get();

        $tabCounts = [
            'all' => $allOrders->count(),
            'pending' => $allOrders->whereIn('status', ['pending', 'processing'])->count(),
            'packed' => $allOrders->where('status', 'packed')->count(),
            'shipped' => $allOrders->whereIn('status', ['shipped', 'out_for_delivery'])->count(),
            'delivered' => $allOrders->where('status', 'delivered')->whereNull('return_request_id')->count(),
            'returns' => $allOrders->filter(fn ($o) => $o->return_request_id !== null || $o->status === 'returned')->count(),
        ];

        $currentStatus = request()->query('status', 'all');
        $search = strtolower(trim((string) request()->query('search', '')));

        $orders = $allOrders->filter(function ($o) use ($currentStatus, $search) {
            if ($currentStatus === 'pending' && ! in_array($o->status, ['pending', 'processing'], true)) {
                return false;
            }
            if ($currentStatus === 'packed' && $o->status !== 'packed') {
                return false;
            }
            if ($currentStatus === 'shipped' && ! in_array($o->status, ['shipped', 'out_for_delivery'], true)) {
                return false;
            }
            if ($currentStatus === 'delivered' && ($o->status !== 'delivered' || $o->return_request_id !== null)) {
                return false;
            }
            if ($currentStatus === 'returns' && $o->return_request_id === null && $o->status !== 'returned') {
                return false;
            }

            if ($search !== '') {
                $haystack = strtolower(($o->order_number ?? '') . ' ' . ($o->buyer_name ?? '') . ' #' . $o->order_id);
                if (! str_contains($haystack, $search)) {
                    return false;
                }
            }

            return true;
        })->values();

        return view('seller.orders', compact('orders', 'tabCounts', 'currentStatus', 'search'));
    }

    public function show($orderId)
    {
        $sellerId = Auth::id();
        $hasVoucherCols = \Illuminate\Support\Facades\Schema::hasColumn('orders', 'voucher_code');
        $hasPaymentMethod = \Illuminate\Support\Facades\Schema::hasColumn('orders', 'payment_method');

        $order = DB::table('orders as o')
            ->join('users as u', 'u.id', '=', 'o.user_id')
            ->where('o.id', $orderId)
            ->select(
                'o.id',
                'o.order_number',
                'o.created_at',
                'o.status',
                'u.name as buyer_name',
                'u.contact_number',
                'u.province',
                'u.municipality',
                'u.barangay',
                'u.street',
                'u.house_number',
                DB::raw($hasPaymentMethod ? 'o.payment_method' : "'cod' as payment_method"),
                DB::raw($hasVoucherCols ? 'o.voucher_code' : 'NULL as voucher_code'),
                DB::raw($hasVoucherCols ? 'o.voucher_type' : 'NULL as voucher_type'),
                DB::raw($hasVoucherCols ? 'o.voucher_discount' : '0 as voucher_discount'),
                DB::raw($hasVoucherCols ? 'o.shipping_discount' : '0 as shipping_discount')
            )
            ->first();

        abort_unless($order, 404);

        $items = DB::table('order_items as oi')
            ->join('products as p', 'p.id', '=', 'oi.product_id')
            ->where('oi.order_id', $orderId)
            ->where(function ($query) use ($sellerId) {
                $query->where('oi.seller_id', $sellerId)
                    ->orWhere('p.seller_id', $sellerId);
            })
            ->select(
                'oi.id',
                'oi.order_id',
                'oi.product_id',
                'oi.seller_id',
                'oi.quantity',
                'oi.price',
                'oi.subtotal',
                'oi.seen_at',
                'oi.packed_at',
                'p.name as product_name'
            )
            ->get();

        abort_if($items->isEmpty(), 404);

        DB::table('order_items as oi')
            ->join('products as p', 'p.id', '=', 'oi.product_id')
            ->where('oi.order_id', $orderId)
            ->where(function ($query) use ($sellerId) {
                $query->where('oi.seller_id', $sellerId)
                    ->orWhere('p.seller_id', $sellerId);
            })
            ->whereNull('oi.seen_at')
            ->update([
                'oi.seen_at' => now(),
                'oi.updated_at' => now(),
            ]);

        $returnRequest = null;
        if (\Illuminate\Support\Facades\Schema::hasTable('return_requests')) {
            $returnRequest = \App\Models\ReturnRequest::query()
                ->where('order_id', $orderId)
                ->with(['evidence', 'logisticsNotification', 'buyer'])
                ->first();
        }

        return view('seller.order-detail', compact('order', 'items', 'returnRequest'));
    }

    public function markPacked(int $id): RedirectResponse
    {
        $sellerId = Auth::id();

        $packed = DB::transaction(function () use ($id, $sellerId): bool {
            $order = Order::query()
                ->where('id', $id)
                ->whereHas('items', function ($query) use ($sellerId) {
                    $query->where('seller_id', $sellerId)
                        ->orWhereHas('product', function ($productQuery) use ($sellerId) {
                            $productQuery->where('seller_id', $sellerId);
                        });
                })
                ->lockForUpdate()
                ->firstOrFail();

            if (in_array($order->status, ['packed', 'shipped', 'out_for_delivery', 'delivered', 'cancelled', 'returned'], true)) {
                return false;
            }

            $now = now();

            DB::table('order_items as oi')
                ->join('products as p', 'p.id', '=', 'oi.product_id')
                ->where('oi.order_id', $order->id)
                ->where(function ($query) use ($sellerId) {
                    $query->where('oi.seller_id', $sellerId)
                        ->orWhere('p.seller_id', $sellerId);
                })
                ->update([
                    'oi.packed_at' => $now,
                    'oi.updated_at' => $now,
                ]);

            $order->updateStatus('packed', 'Order marked as packed by seller.', event: [
                'changed_by' => $sellerId,
            ]);

            return true;
        });

        if (! $packed) {
            return back()->with('error', 'This order can no longer be marked as packed.');
        }

        return back()->with('success', 'Order marked as packed successfully.');
    }

    public function waybill($orderId)
    {
        $sellerId = Auth::id();

        $hasPaymentMethod = \Illuminate\Support\Facades\Schema::hasColumn('orders', 'payment_method');

        $order = DB::table('orders as o')
            ->join('users as u', 'u.id', '=', 'o.user_id')
            ->where('o.id', $orderId)
            ->select(
                'o.id',
                'o.order_number',
                'o.created_at',
                'u.name as buyer_name',
                'u.contact_number',
                'u.province',
                'u.municipality',
                'u.barangay',
                'u.street',
                'u.house_number',
                DB::raw($hasPaymentMethod ? 'o.payment_method' : "'cod' as payment_method")
            )
            ->firstOrFail();

        $items = DB::table('order_items as oi')
            ->join('products as p', 'p.id', '=', 'oi.product_id')
            ->where('oi.order_id', $orderId)
            ->where('p.seller_id', $sellerId)
            ->select('oi.*', 'p.name as product_name')
            ->get();

        abort_if($items->isEmpty(), 404);

        $sellerApp = DB::table('seller_applications')
            ->where('user_id', $sellerId)
            ->where('status', 'approved')
            ->first();

        $shopName = $sellerApp->business_name ?? Auth::user()->name;

        $total = $items->sum(fn ($item) => $item->price * $item->quantity);

        // Code 39 uses the numeric order ID printed on the label, so scanners
        // can identify the same reference shown to the seller and buyer.
        $code39 = [
            '0' => 'nnnwwnwnn', '1' => 'wnnwnnnnw', '2' => 'nnwwnnnnw',
            '3' => 'wnwwnnnnn', '4' => 'nnnwwnnnw', '5' => 'wnnwwnnnn',
            '6' => 'nnwwwnnnn', '7' => 'nnnwnnwnw', '8' => 'wnnwnnwnn',
            '9' => 'nnwwnnwnn', '*' => 'nwnnwnwnn',
        ];
        $barcodeValue = (string) $order->id;
        $barcodeSequence = '*'.$barcodeValue.'*';
        // Use wider Code 39 modules for phone-camera scanning, while scaling
        // down for long order IDs so the barcode stays within the label width.
        $module = max(2, min(4, (int) floor(500 / (16 * strlen($barcodeValue) + 52))));
        $barcodeHeight = 90;
        $cursor = 0;
        // Build a plain HTML table rather than inline SVG. Dompdf can omit
        // inline SVG from streamed PDFs, leaving only the human-readable ID.
        $barcodeRuns = [10]; // quiet zone before the start character
        foreach (str_split($barcodeSequence) as $character) {
            foreach (str_split($code39[$character]) as $index => $width) {
                $barWidth = ($width === 'w' ? 3 : 1) * $module;
                $barcodeRuns[] = [$barWidth, $index % 2 === 0];
            }
            $barcodeRuns[] = [$module, false]; // Inter-character gap
        }
        $barcodeRuns[] = [10, false]; // quiet zone after the stop character
        $barcodeRuns[0] = [10 * $module, false];
        $barcodeRuns[count($barcodeRuns) - 1] = [10 * $module, false];
        $barcodeCells = '';
        foreach ($barcodeRuns as [$width, $isBar]) {
            $background = $isBar ? '#000000' : '#FFFFFF';
            $barcodeCells .= '<td style="width:'.$width.'px;height:'.$barcodeHeight.'px;padding:0;border:0;background:'.$background.';"></td>';
        }
        $barcodeHtml = '<table cellpadding="0" cellspacing="0" style="margin:0 auto;border-collapse:collapse;border:0;"><tr>'.$barcodeCells.'</tr></table>';

        $pdf = Pdf::loadView('seller.waybill-pdf', compact('order', 'items', 'shopName', 'total', 'barcodeHtml', 'barcodeValue', 'barcodeHeight'));

        return $pdf->stream('waybill-order-' . $orderId . '.pdf');
    }

    public function notifications()
    {
        $sellerId = Auth::id();

        $count = DB::table('order_items as oi')
            ->join('products as p', 'p.id', '=', 'oi.product_id')
            ->where('p.seller_id', $sellerId)
            ->whereNull('oi.seen_at')
            ->distinct('oi.order_id')
            ->count('oi.order_id');

        $recent = DB::table('order_items as oi')
            ->join('products as p', 'p.id', '=', 'oi.product_id')
            ->join('orders as o', 'o.id', '=', 'oi.order_id')
            ->join('users as u', 'u.id', '=', 'o.user_id')
            ->where('p.seller_id', $sellerId)
            ->whereNull('oi.seen_at')
            ->select(
                'o.id as order_id',
                'o.order_number',
                'o.created_at',
                'o.payment_method',
                'o.payment_status',
                'u.name as buyer_name',
                DB::raw('SUM(oi.price * oi.quantity) as subtotal')
            )
            ->groupBy('o.id', 'o.order_number', 'o.created_at', 'o.payment_method', 'o.payment_status', 'u.name')
            ->orderByDesc('o.created_at')
            ->limit(5)
            ->get();

        $productsByOrder = $recent->isEmpty()
            ? collect()
            : DB::table('order_items as oi')
                ->join('products as p', 'p.id', '=', 'oi.product_id')
                ->where('p.seller_id', $sellerId)
                ->whereIn('oi.order_id', $recent->pluck('order_id'))
                ->select('oi.order_id', 'p.name', 'oi.quantity')
                ->orderBy('p.name')
                ->get()
                ->groupBy('order_id');

        $recent = $recent->map(function ($order) use ($productsByOrder) {
            $walletPaymentConfirmed = in_array(strtolower((string) $order->payment_method), ['gcash', 'maya', 'paymaya'], true)
                && $order->payment_status === 'paid';
            $order->products = $productsByOrder->get($order->order_id, collect())
                ->map(fn ($item) => ['name' => $item->name, 'quantity' => (int) $item->quantity])
                ->values();
            if ($walletPaymentConfirmed) {
                $commission = round((float) $order->subtotal * PayoutController::COMMISSION_RATE, 2);
                $sellerEarnings = round((float) $order->subtotal - $commission, 2);
                $order->notification_message = 'E-Wallet payment received and confirmed. PHP '
                    .number_format($sellerEarnings, 2)
                    .' is added to your earnings after the 10% platform commission. Check Payouts / Earnings and pack your order now.';
                $order->seller_earnings = $sellerEarnings;
            } else {
                $order->notification_message = 'New order received.';
            }

            return $order;
        });

        $unreadPayoutNotifications = DB::table('notifications')
            ->where('notifiable_type', \App\Models\User::class)
            ->where('notifiable_id', $sellerId)
            ->where('type', PayoutRequestStatusNotification::class)
            ->whereNull('read_at')
            ->orderByDesc('created_at')
            ->limit(5)
            ->get();

        $payoutNotificationCount = DB::table('notifications')
            ->where('notifiable_type', \App\Models\User::class)
            ->where('notifiable_id', $sellerId)
            ->where('type', PayoutRequestStatusNotification::class)
            ->whereNull('read_at')
            ->count();

        $productApprovalNotifications = DB::table('notifications')
            ->where('notifiable_type', \App\Models\User::class)
            ->where('notifiable_id', $sellerId)
            ->where('type', ProductApprovalRejectedNotification::class)
            ->whereNull('read_at')
            ->orderByDesc('created_at')
            ->limit(5)
            ->get();

        $productApprovalNotificationCount = DB::table('notifications')
            ->where('notifiable_type', \App\Models\User::class)
            ->where('notifiable_id', $sellerId)
            ->where('type', ProductApprovalRejectedNotification::class)
            ->whereNull('read_at')
            ->count();

        $pendingReturnsCount = 0;
        $returnRequests = collect();
        if (\Illuminate\Support\Facades\Schema::hasTable('return_requests')) {
            $pendingReturns = \App\Models\ReturnRequest::query()
                ->where('status', 'pending')
                ->whereHas('order.items', fn ($q) => $q->where('seller_id', $sellerId))
                ->with(['order', 'buyer'])
                ->latest()
                ->take(5)
                ->get();

            $pendingReturnsCount = \App\Models\ReturnRequest::query()
                ->where('status', 'pending')
                ->whereHas('order.items', fn ($q) => $q->where('seller_id', $sellerId))
                ->count();

            $returnRequests = $pendingReturns->map(function ($rr) {
                return [
                    'id' => $rr->id,
                    'order_id' => $rr->order_id,
                    'order_number' => $rr->order?->order_number ?? '#' . $rr->order_id,
                    'buyer_name' => $rr->buyer?->name ?? 'Customer',
                    'reason' => ucwords(str_replace('_', ' ', $rr->reason)),
                    'created_at' => $rr->created_at,
                    'url' => route('seller.returns.index', ['search' => $rr->order?->order_number]),
                ];
            })->values();
        }

        return response()->json([
            'count' => $count + $payoutNotificationCount + $productApprovalNotificationCount + $pendingReturnsCount,
            'orders_count' => $count,
            'returns_count' => $pendingReturnsCount,
            'returns' => $returnRequests,
            'orders' => $recent,
            'payouts' => $unreadPayoutNotifications->map(function ($notification) {
                $data = json_decode($notification->data, true) ?: [];

                return [
                    'id' => $notification->id,
                    'payout_request_id' => $data['payout_request_id'] ?? null,
                    'message' => $data['message'] ?? 'Your payout request status changed.',
                    'created_at' => $notification->created_at,
                ];
            })->values(),
            'product_approvals' => $productApprovalNotifications->map(function ($notification) {
                $data = json_decode($notification->data, true) ?: [];

                return [
                    'id' => $notification->id,
                    'product_id' => $data['product_id'] ?? null,
                    'product_name' => $data['product_name'] ?? 'Product listing',
                    'message' => $data['message'] ?? 'Your product needs changes before it can be published.',
                    'reason' => $data['reason'] ?? null,
                    'note' => $data['note'] ?? null,
                    'created_at' => $notification->created_at,
                ];
            })->values(),
        ]);
    }

    public function markProductApprovalNotificationsRead(\Illuminate\Http\Request $request)
    {
        $validated = $request->validate(['ids' => ['required', 'array', 'min:1'], 'ids.*' => ['required', 'uuid']]);

        DB::table('notifications')
            ->whereIn('id', $validated['ids'])
            ->where('notifiable_type', \App\Models\User::class)
            ->where('notifiable_id', Auth::id())
            ->where('type', ProductApprovalRejectedNotification::class)
            ->whereNull('read_at')
            ->update(['read_at' => now()]);

        return response()->json(['success' => true]);
    }

    public function markPayoutNotificationsRead(\Illuminate\Http\Request $request)
    {
        $validated = $request->validate(['ids' => ['required', 'array', 'min:1'], 'ids.*' => ['required', 'uuid']]);

        DB::table('notifications')
            ->whereIn('id', $validated['ids'])
            ->where('notifiable_type', \App\Models\User::class)
            ->where('notifiable_id', Auth::id())
            ->where('type', PayoutRequestStatusNotification::class)
            ->whereNull('read_at')
            ->update(['read_at' => now()]);

        return response()->json(['success' => true]);
    }
}
