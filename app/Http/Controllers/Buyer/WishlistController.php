<?php

namespace App\Http\Controllers\Buyer;

use App\Http\Controllers\Controller;
use App\Models\Product;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class WishlistController extends Controller
{
    public function toggle(Request $request, Product $product): JsonResponse
    {
        abort_unless($product->approval_status === 'approved' && $product->status === 'active', 404);
        $query = DB::table('saved_products')->where('user_id', $request->user()->id)->where('product_id', $product->id);
        if ($query->exists()) {
            $query->delete();
            $saved = false;
        } else {
            DB::table('saved_products')->insertOrIgnore([
                'user_id' => $request->user()->id,
                'product_id' => $product->id,
                'created_at' => now(), 'updated_at' => now(),
            ]);
            $saved = true;
        }
        return response()->json(['saved' => $saved, 'message' => $saved ? 'Saved to your wishlist.' : 'Removed from your wishlist.']);
    }
}
