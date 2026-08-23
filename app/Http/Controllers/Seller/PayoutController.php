<?php

namespace App\Http\Controllers\Seller;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\DB;

class PayoutController extends Controller
{
    // Platform takes 10% commission on every sale; seller keeps 90%.
    const COMMISSION_RATE = 0.10;

    public function index()
    {
        $sellerId = Auth::id();

        // Gross sales (before commission) — same calc as the dashboard
        $totalSales = DB::table('order_items as oi')
            ->join('products as p', 'p.id', '=', 'oi.product_id')
            ->join('orders as o', 'o.id', '=', 'oi.order_id')
            ->where('p.seller_id', $sellerId)
            ->where('o.status', 'paid')
            ->sum(DB::raw('oi.price * oi.quantity'));

        // Platform commission taken off the top, and what the seller actually earns
        $platformCommission = $totalSales * self::COMMISSION_RATE;
        $sellerEarnings     = $totalSales - $platformCommission;

        $totalOrders = DB::table('order_items as oi')
            ->join('products as p', 'p.id', '=', 'oi.product_id')
            ->where('p.seller_id', $sellerId)
            ->distinct('oi.order_id')
            ->count('oi.order_id');

        $totalPaidOut = DB::table('payout_requests')
            ->where('seller_id', $sellerId)
            ->whereIn('status', ['approved', 'paid'])
            ->sum('amount');

        $pendingAmount = DB::table('payout_requests')
            ->where('seller_id', $sellerId)
            ->where('status', 'pending')
            ->sum('amount');

        // Available balance is now based on seller's 90% share, not the gross sale amount
        $availableBalance = $sellerEarnings - $totalPaidOut - $pendingAmount;

        $payoutMethod = DB::table('seller_payout_methods')->where('seller_id', $sellerId)->first();

        $payoutHistory = DB::table('payout_requests')
            ->where('seller_id', $sellerId)
            ->orderByDesc('created_at')
            ->get();

        return view('seller.payouts', compact(
            'totalSales', 'platformCommission', 'sellerEarnings', 'totalOrders',
            'totalPaidOut', 'pendingAmount', 'availableBalance', 'payoutMethod', 'payoutHistory'
        ));
    }

    public function saveMethod(Request $request)
    {
        $request->validate([
            'method'         => ['required', 'in:gcash,paymaya,bank_transfer'],
            'account_name'   => ['required', 'string', 'max:255'],
            'account_number' => ['required', 'string', 'max:50'],
            'bank_name'      => ['required_if:method,bank_transfer', 'nullable', 'string', 'max:255'],
        ]);

        DB::table('seller_payout_methods')->updateOrInsert(
            ['seller_id' => Auth::id()],
            [
                'method'         => $request->method,
                'account_name'   => $request->account_name,
                'account_number' => $request->account_number,
                'bank_name'      => $request->method === 'bank_transfer' ? $request->bank_name : null,
                'updated_at'     => now(),
                'created_at'     => now(),
            ]
        );

        return back()->with('success', 'Payout method saved.');
    }

    public function requestPayout(Request $request)
    {
        $sellerId = Auth::id();

        $payoutMethod = DB::table('seller_payout_methods')->where('seller_id', $sellerId)->first();

        if (! $payoutMethod) {
            return back()->with('error', 'Please set up a payout method first.');
        }

        $request->validate([
            'amount' => ['required', 'numeric', 'min:100'],
        ]);

        // Recompute available balance server-side — never trust the client
        $totalSales = DB::table('order_items as oi')
            ->join('products as p', 'p.id', '=', 'oi.product_id')
            ->join('orders as o', 'o.id', '=', 'oi.order_id')
            ->where('p.seller_id', $sellerId)
            ->where('o.status', 'paid')
            ->sum(DB::raw('oi.price * oi.quantity'));

        $sellerEarnings = $totalSales * (1 - self::COMMISSION_RATE);

        $alreadyOut = DB::table('payout_requests')
            ->where('seller_id', $sellerId)
            ->whereIn('status', ['approved', 'paid', 'pending'])
            ->sum('amount');

        $available = $sellerEarnings - $alreadyOut;

        if ($request->amount > $available) {
            return back()->with('error', 'Requested amount exceeds your available balance.');
        }

        DB::table('payout_requests')->insert([
            'seller_id'      => $sellerId,
            'amount'         => $request->amount,
            'method'         => $payoutMethod->method,
            'account_name'   => $payoutMethod->account_name,
            'account_number' => $payoutMethod->account_number,
            'bank_name'      => $payoutMethod->bank_name,
            'status'         => 'pending',
            'created_at'     => now(),
            'updated_at'     => now(),
        ]);

        return back()->with('success', 'Payout request submitted.');
    }
}