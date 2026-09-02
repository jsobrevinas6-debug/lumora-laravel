<?php

namespace App\Http\Controllers\Seller;

use App\Http\Controllers\Controller;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\DB;
use Barryvdh\DomPDF\Facade\Pdf;

class OrderController extends Controller
{
    public function index()
    {
        $sellerId = Auth::id();

        $orders = DB::table('order_items as oi')
            ->join('products as p', 'p.id', '=', 'oi.product_id')
            ->join('orders as o', 'o.id', '=', 'oi.order_id')
            ->join('users as u', 'u.id', '=', 'o.buyer_id')
            ->where('p.seller_id', $sellerId)
            ->select(
                'o.id as order_id',
                'o.created_at as order_date',
                'u.name as buyer_name',
                DB::raw('SUM(oi.price * oi.quantity) as seller_subtotal'),
                DB::raw('SUM(CASE WHEN oi.seen_at IS NULL THEN 1 ELSE 0 END) as unseen_count'),
                DB::raw('SUM(CASE WHEN oi.packed_at IS NULL THEN 1 ELSE 0 END) as unpacked_count')
            )
            ->groupBy('o.id', 'o.created_at', 'u.name')
            ->orderByDesc('o.created_at')
            ->get();

        return view('seller.orders', compact('orders'));
    }

    public function show($orderId)
    {
        $sellerId = Auth::id();

        $order = DB::table('orders as o')
            ->join('users as u', 'u.id', '=', 'o.buyer_id')
            ->where('o.id', $orderId)
            ->select(
                'o.id', 'o.created_at', 'o.status',
                'u.name as buyer_name', 'u.contact_number',
                'u.province', 'u.municipality', 'u.barangay', 'u.street', 'u.house_number'
            )
            ->first();

        abort_unless($order, 404);

        $items = DB::table('order_items as oi')
            ->join('products as p', 'p.id', '=', 'oi.product_id')
            ->where('oi.order_id', $orderId)
            ->where('p.seller_id', $sellerId)
            ->select('oi.*', 'p.name as product_name')
            ->get();

        abort_if($items->isEmpty(), 404);

        // Mark this seller's items in this order as seen (clears the notification badge for them)
        DB::table('order_items as oi')
            ->join('products as p', 'p.id', '=', 'oi.product_id')
            ->where('oi.order_id', $orderId)
            ->where('p.seller_id', $sellerId)
            ->whereNull('oi.seen_at')
            ->update(['oi.seen_at' => now()]);

        return view('seller.order-detail', compact('order', 'items'));
    }

    public function markPacked($orderId)
    {
        $sellerId = Auth::id();

        DB::table('order_items as oi')
            ->join('products as p', 'p.id', '=', 'oi.product_id')
            ->where('oi.order_id', $orderId)
            ->where('p.seller_id', $sellerId)
            ->update(['oi.packed_at' => now()]);

        return back()->with('success', 'Order marked as packed.');
    }

    public function waybill($orderId)
    {
        $sellerId = Auth::id();

        $order = DB::table('orders as o')
            ->join('users as u', 'u.id', '=', 'o.buyer_id')
            ->where('o.id', $orderId)
            ->select(
                'o.id', 'o.created_at',
                'u.name as buyer_name', 'u.contact_number',
                'u.province', 'u.municipality', 'u.barangay', 'u.street', 'u.house_number'
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
        $total = $items->sum(fn ($i) => $i->price * $i->quantity);

        $pdf = Pdf::loadView('seller.waybill-pdf', compact('order', 'items', 'shopName', 'total'));

        return $pdf->download('waybill-order-' . $orderId . '.pdf');
    }

    /**
     * AJAX endpoint powering the notification bell in the seller topbar.
     */
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
            ->join('users as u', 'u.id', '=', 'o.buyer_id')
            ->where('p.seller_id', $sellerId)
            ->whereNull('oi.seen_at')
            ->select(
                'o.id as order_id',
                'o.created_at',
                'u.name as buyer_name',
                DB::raw('SUM(oi.price * oi.quantity) as subtotal')
            )
            ->groupBy('o.id', 'o.created_at', 'u.name')
            ->orderByDesc('o.created_at')
            ->limit(5)
            ->get();

        return response()->json(['count' => $count, 'orders' => $recent]);
    }
}