<?php

namespace App\Http\Controllers\Buyer;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\View\View;

class CustomerCareController extends Controller
{
    private const TOPICS = [
        'help' => ['Help Center', 'Find help with shopping, accounts, payments, and orders.'],
        'shipping' => ['Shipping Information', 'Delivery estimates are shown on your order details when available. You can follow a shipped package from My Orders.'],
        'returns' => ['Returns & Refunds', 'For a delivered order, open My Orders and choose Return / Refund. Add a reason and any photo or video proof; the Lumora team will review your request.'],
        'tracking' => ['Track an Order', 'Open My Orders and choose Track package or View details to see the latest available delivery status and tracking information.'],
        'size-guide' => ['Size Guide', 'Product sizes and variants are listed on each product page. If you need help choosing a size, contact the shop from the product page.'],
        'contact' => ['Contact Lumora', 'Use Lumora Support chat for help with your account, orders, payments, or shopping.'],
        'faq' => ['Frequently Asked Questions', 'Order status, payment methods, delivery estimates, and return requests are available from your account and order details.'],
        'payments' => ['Payments', 'Lumora checkout supports Cash on Delivery and the e-wallet methods offered at checkout, including GCash and Maya.'],
    ];

    public function show(Request $request, ?string $topic = null): View
    {
        $topic = $topic ?: 'help';
        abort_unless(array_key_exists($topic, self::TOPICS), 404);

        return view('buyer.help-center', [
            'topic' => $topic,
            'title' => self::TOPICS[$topic][0],
            'description' => self::TOPICS[$topic][1],
        ]);
    }
}
