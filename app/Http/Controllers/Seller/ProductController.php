<?php

namespace App\Http\Controllers\Seller;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Storage;

class ProductController extends Controller
{
    public function index()
    {
        $products = DB::table('products')->where('seller_id', Auth::id())->orderByDesc('created_at')->get();
        return view('seller.products', compact('products'));
    }

    public function store(Request $request)
    {
        $request->validate([
            'name'        => ['required', 'string', 'max:255'],
            'description' => ['nullable', 'string'],
            'price'       => ['required', 'numeric', 'min:0'],
            'stock'       => ['required', 'integer', 'min:0'],
            'image'       => ['nullable', 'image', 'max:2048'],
        ]);

        $imagePath = null;
        if ($request->hasFile('image')) {
            $imagePath = $request->file('image')->store('products', 'public');
        }

        DB::table('products')->insert([
            'seller_id'   => Auth::id(),
            'name'        => $request->name,
            'description' => $request->description,
            'price'       => $request->price,
            'stock'       => $request->stock,
            'image'       => $imagePath,
            'status'      => 'active',
            'created_at'  => now(),
            'updated_at'  => now(),
        ]);

        return back()->with('success', 'Product added successfully!');
    }

    public function updateStock(Request $request, $id)
    {
        $request->validate(['stock' => 'required|integer|min:0']);

        $product = DB::table('products')->where('id', $id)->where('seller_id', Auth::id())->first();

        abort_unless($product, 403);

        DB::table('products')->where('id', $id)->update([
            'stock'      => $request->stock,
            'updated_at' => now(),
        ]);

        return back()->with('success', 'Stock updated.');
    }

    public function destroy($id)
    {
        $product = DB::table('products')->where('id', $id)->where('seller_id', Auth::id())->first();
        if ($product && $product->image) {
            Storage::disk('public')->delete($product->image);
        }
        DB::table('products')->where('id', $id)->where('seller_id', Auth::id())->delete();
        return back()->with('success', 'Product deleted.');
    }
}