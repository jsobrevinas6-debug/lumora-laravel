<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use Illuminate\Support\Facades\DB;

class DashboardController extends Controller
{
    public function users()
    {
        $users = DB::table('users')->orderByDesc('created_at')->get();
        return view('admin.users', compact('users'));
    }

    public function applications()
    {
        $applications = DB::table('seller_applications as sa')
            ->join('users as u', 'u.id', '=', 'sa.user_id')
            ->select('sa.*', 'u.name', 'u.email')
            ->orderByDesc('sa.created_at')
            ->get();

        return view('admin.applications', compact('applications'));
    }

    public function index()
    {
        $totalSales    = DB::table('order_items as oi')
            ->join('orders as o', 'o.id', '=', 'oi.order_id')
            ->where('o.status', 'paid')
            ->sum(DB::raw('oi.price * oi.quantity'));

        $totalOrders   = DB::table('orders')->count();
        $totalProducts = DB::table('products')->count();
        $totalBuyers   = DB::table('users')->where('role', 'buyer')->count();

        $applications = DB::table('seller_applications as sa')
            ->join('users as u', 'u.id', '=', 'sa.user_id')
            ->where('sa.status', 'pending')
            ->select('sa.*', 'u.name', 'u.email')
            ->orderByDesc('sa.created_at')
            ->limit(10)
            ->get();

        return view('admin.dashboard', compact('totalSales', 'totalOrders', 'totalProducts', 'totalBuyers', 'applications'));
    }

    public function handleApplication($id, $action)
    {
        $newStatus = match($action) {
            'approve' => 'approved',
            'reject'  => 'rejected',
            'archive' => 'archived',
            default   => null,
        };

        if (!$newStatus) abort(404);

        DB::table('seller_applications')->where('id', $id)->update(['status' => $newStatus]);

        if ($newStatus === 'approved') {
            $app = DB::table('seller_applications')->find($id);
            DB::table('users')->where('id', $app->user_id)->update(['role' => 'seller']);
        }

        session()->flash('flash_success', 'Application ' . $newStatus . '.');
        return redirect()->route('admin.dashboard');
    }
}
