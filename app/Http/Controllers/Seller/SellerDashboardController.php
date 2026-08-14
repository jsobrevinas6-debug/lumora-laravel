<?php

namespace App\Http\Controllers\Seller;

use App\Http\Controllers\Controller;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\DB;

class SellerDashboardController extends Controller
{
    public function index()
    {
        $sellerId = Auth::id();

        $totalSales = DB::table('order_items as oi')
            ->join('products as p', 'p.id', '=', 'oi.product_id')
            ->join('orders as o', 'o.id', '=', 'oi.order_id')
            ->where('p.seller_id', $sellerId)
            ->where('o.status', 'paid')
            ->sum(DB::raw('oi.price * oi.quantity'));

        $totalOrders = DB::table('order_items as oi')
            ->join('products as p', 'p.id', '=', 'oi.product_id')
            ->where('p.seller_id', $sellerId)
            ->distinct('oi.order_id')
            ->count('oi.order_id');

        $totalProducts = DB::table('products')->where('seller_id', $sellerId)->count();

        $lowStock = DB::table('products')
            ->where('seller_id', $sellerId)
            ->where('stock', '<=', 5)
            ->orderBy('stock')
            ->get(['id', 'name', 'stock']);

        return view('seller.dashboard', compact('totalSales', 'totalOrders', 'totalProducts', 'lowStock'));
    }
}
