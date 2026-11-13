<?php

namespace App\Http\Controllers;

use App\Models\Product;
use Illuminate\Http\Request;

class ShopController extends Controller
{
    public function index()
    {
    $productsByCategory = Product::approved()->get()->groupBy('category');

    return view('buyer.shop', compact('productsByCategory'));
    }
}
