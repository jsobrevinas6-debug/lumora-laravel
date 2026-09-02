<?php

namespace App\Http\Controllers\Seller;

use App\Http\Controllers\Controller;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\DB;
use Illuminate\View\View;

class SellerDashboardController extends Controller
{
    private const LOW_STOCK_LIMIT = 20;
    private const LOW_STOCK_PER_PAGE = 5;

    public function index(Request $request): View
    {
        $sellerId = Auth::id();
        $lowStockSearch = trim((string) $request->input('low_stock_search', ''));

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

        $totalProducts = DB::table('products')
            ->where('seller_id', $sellerId)
            ->where('status', '!=', 'archived')
            ->count();

        $lowStockQuery = DB::table('products')
            ->where('seller_id', $sellerId)
            ->where('status', '!=', 'archived')
            ->where('stock', '<=', self::LOW_STOCK_LIMIT);

        if ($lowStockSearch !== '') {
            $lowStockQuery->where('name', 'like', '%' . $lowStockSearch . '%');
        }

        $lowStock = $lowStockQuery
            ->orderBy('stock')
            ->orderBy('name')
            ->paginate(
                self::LOW_STOCK_PER_PAGE,
                ['id', 'name', 'stock'],
                'lowStockPage'
            )
            ->withQueryString();

        $salesTrend7 = $this->buildSalesTrend($sellerId, 7);
        $salesTrend30 = $this->buildSalesTrend($sellerId, 30);

        return view('seller.dashboard', compact(
            'totalSales',
            'totalOrders',
            'totalProducts',
            'lowStock',
            'lowStockSearch',
            'salesTrend7',
            'salesTrend30'
        ));
    }

    private function buildSalesTrend(int $sellerId, int $days): array
    {
        $start = now()->subDays($days - 1)->startOfDay();
        $end = now()->endOfDay();

        $rows = DB::table('order_items as oi')
            ->join('products as p', 'p.id', '=', 'oi.product_id')
            ->join('orders as o', 'o.id', '=', 'oi.order_id')
            ->where('p.seller_id', $sellerId)
            ->where('o.status', 'paid')
            ->whereBetween('o.created_at', [$start, $end])
            ->selectRaw('DATE(o.created_at) as day, SUM(oi.price * oi.quantity) as total')
            ->groupBy('day')
            ->pluck('total', 'day');

        $labels = [];
        $values = [];

        for ($i = 0; $i < $days; $i++) {
            $date = $start->copy()->addDays($i);
            $key = $date->format('Y-m-d');
            $labels[] = $date->format('M j');
            $values[] = (float) ($rows[$key] ?? 0);
        }

        return [
            'labels' => $labels,
            'values' => $values,
        ];
    }
}
