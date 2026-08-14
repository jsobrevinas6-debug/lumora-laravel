<?php

namespace App\Http\Controllers\Buyer;

use App\Http\Controllers\Controller;
use Illuminate\Support\Facades\DB;

class ShopController extends Controller
{
    public function index()
    {
        $products = DB::table('products')->where('status', 'active')->orderByDesc('created_at')->get();
        return view('buyer.shop', compact('products'));
    }
}
