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
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Schema;

class OrderController extends Controller
{
    public function index(Request $request)
    {
        $sellerId = Auth::id();
        $base = DB::table('orders as o')->whereExists(function ($q) use ($sellerId) {
            $q->selectRaw('1')->from('order_items as si')->whereColumn('si.order_id', 'o.id')
                ->where(function ($x) use ($sellerId) { $x->where('si.seller_id', $sellerId)->orWhereExists(function ($p) use ($sellerId) { $p->selectRaw('1')->from('products')->whereColumn('products.id', 'si.product_id')->where('products.seller_id', $sellerId); }); });
        });
        $items = DB::table('order_items as oi')->join('products as p', 'p.id', '=', 'oi.product_id')->where(function ($q) use ($sellerId) { $q->where('oi.seller_id', $sellerId)->orWhere('p.seller_id', $sellerId); });
        $summary = (clone $items)->selectRaw('oi.order_id, SUM(oi.price * oi.quantity) seller_subtotal, SUM(oi.quantity) item_count, SUM(CASE WHEN oi.packed_at IS NULL THEN oi.quantity ELSE 0 END) unpacked_count, SUM(CASE WHEN oi.seen_at IS NULL THEN 1 ELSE 0 END) unseen_count')->groupBy('oi.order_id');
        $tabCounts = ['all' => (clone $base)->count(), 'pending' => (clone $base)->whereIn('o.status', ['pending','processing'])->count(), 'packed' => (clone $base)->where('o.status','packed')->count(), 'shipped' => (clone $base)->whereIn('o.status',['shipped','out_for_delivery'])->count(), 'delivered' => (clone $base)->where('o.status','delivered')->count(), 'cancelled' => (clone $base)->where('o.status','cancelled')->count(), 'returns' => (clone $base)->where(function($q){$q->where('o.status','returned')->orWhereExists(function($r){$r->selectRaw('1')->from('return_requests')->whereColumn('return_requests.order_id','o.id');});})->count(), 'refund' => (clone $base)->where('o.payment_status','refunded')->count()];
        $currentStatus = $request->query('status', 'all');
        $search = trim((string) $request->query('search', ''));
        $query = (clone $base)->join('users as u','u.id','=','o.user_id')->leftJoinSub($summary,'s','s.order_id','=','o.id')
            ->select('o.*','u.name as buyer_name','u.province','u.municipality','u.contact_number',DB::raw('COALESCE(s.seller_subtotal,0) seller_subtotal'),DB::raw('COALESCE(s.item_count,0) item_count'),DB::raw('COALESCE(s.unpacked_count,0) unpacked_count'),DB::raw('COALESCE(s.unseen_count,0) unseen_count'));
        $statusMap = ['pending'=>['pending','processing'],'packed'=>['packed'],'shipped'=>['shipped','out_for_delivery'],'delivered'=>['delivered'],'cancelled'=>['cancelled'],'returns'=>['returned'],'refund'=>['refunded']];
        if (isset($statusMap[$currentStatus]) && $currentStatus !== 'returns') $query->whereIn('o.status',$statusMap[$currentStatus]);
        if ($currentStatus==='returns') $query->where(function($q){$q->where('o.status','returned')->orWhereExists(fn($r)=>$r->selectRaw('1')->from('return_requests')->whereColumn('return_requests.order_id','o.id'));});
        if ($search!=='') $query->where(function($q)use($search){$q->where('o.order_number','like',"%{$search}%")->orWhere('u.name','like',"%{$search}%")->orWhereExists(function($sub)use($search){$sub->selectRaw('1')->from('order_items as si')->join('products as sp','sp.id','=','si.product_id')->whereColumn('si.order_id','o.id')->where('sp.name','like',"%{$search}%");});});
        if ($request->filled('date_range')) $query->where('o.created_at','>=',now()->subDays($request->date_range==='30'?30:7));
        if ($request->filled('payment') && $request->payment!=='all') $query->where('o.payment_method',$request->payment);
        match($request->query('sort')) {'oldest'=>$query->orderBy('o.created_at'), 'highest'=>$query->orderByDesc('o.total'), default=>$query->orderByDesc('o.created_at')};
        $orders=$query->paginate(15)->withQueryString();
        $stats=['new'=>(clone $base)->whereIn('o.status',['pending','processing'])->whereNull('o.seller_viewed_at')->count(),'to_pack'=>(clone $base)->whereIn('o.status',['pending','processing'])->count(),'waiting_payment'=>(clone $base)->whereIn('o.status',['pending','processing'])->whereIn('o.payment_method',['gcash','maya','paymaya'])->where('o.payment_status','!=','paid')->count(),'to_ship'=>(clone $base)->where('o.status','packed')->count(),'week_sales'=>(clone $base)->where('o.created_at','>=',now()->subDays(7))->whereNotIn('o.status',['cancelled'])->sum('o.total')];
        return view('seller.orders', compact('orders','tabCounts','currentStatus','search','stats'));
    }

    public function show($orderId)
    {
        $sellerId = Auth::id();
        $hasVoucherCols = \Illuminate\Support\Facades\Schema::hasColumn('orders', 'voucher_code');
        $hasPaymentMethod = \Illuminate\Support\Facades\Schema::hasColumn('orders', 'payment_method');

        $orderColumns = [
            'o.id',
            'o.order_number',
            'o.created_at',
            'o.status',
            'u.name as buyer_name',
            DB::raw($hasPaymentMethod ? 'o.payment_method' : "'cod' as payment_method"),
            DB::raw($hasVoucherCols ? 'o.voucher_code' : 'NULL as voucher_code'),
            DB::raw($hasVoucherCols && \Illuminate\Support\Facades\Schema::hasColumn('orders', 'voucher_type') ? 'o.voucher_type' : 'NULL as voucher_type'),
            DB::raw($hasVoucherCols && \Illuminate\Support\Facades\Schema::hasColumn('orders', 'voucher_discount') ? 'o.voucher_discount' : '0 as voucher_discount'),
            DB::raw($hasVoucherCols && \Illuminate\Support\Facades\Schema::hasColumn('orders', 'shipping_discount') ? 'o.shipping_discount' : '0 as shipping_discount'),
        ];

        foreach (['contact_number', 'province', 'municipality', 'barangay', 'street', 'house_number'] as $addressColumn) {
            $orderColumns[] = \Illuminate\Support\Facades\Schema::hasColumn('users', $addressColumn)
                ? 'u.'.$addressColumn
                : DB::raw('NULL as '.$addressColumn);
        }

        $order = DB::table('orders as o')
            ->join('users as u', 'u.id', '=', 'o.user_id')
            ->where('o.id', $orderId)
            ->select($orderColumns)
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

        Order::whereKey($orderId)->update(['seller_viewed_at' => now()]);

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
            $returnRelations = ['buyer'];
            $hasReturnEvidenceTable = \Illuminate\Support\Facades\Schema::hasTable('return_request_evidence');
            $hasLogisticsNotificationsTable = \Illuminate\Support\Facades\Schema::hasTable('logistics_return_notifications');

            if ($hasReturnEvidenceTable) {
                $returnRelations[] = 'evidence';
            }
            if ($hasLogisticsNotificationsTable) {
                $returnRelations[] = 'logisticsNotification';
            }

            $returnRequest = \App\Models\ReturnRequest::query()
                ->where('order_id', $orderId)
                ->with($returnRelations)
                ->first();

            if ($returnRequest && ! $hasReturnEvidenceTable) {
                $returnRequest->setRelation('evidence', collect());
            }
            if ($returnRequest && ! $hasLogisticsNotificationsTable) {
                $returnRequest->setRelation('logisticsNotification', null);
            }
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

            if (! in_array($order->status, ['pending', 'processing'], true)) {
                return false;
            }
            if (in_array(strtolower((string) $order->payment_method), ['gcash', 'maya', 'paymaya'], true) && $order->payment_status !== 'paid') {
                throw new \Illuminate\Http\Exceptions\HttpResponseException(back()->with('error', 'This e-wallet payment must be verified before packing.'));
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
