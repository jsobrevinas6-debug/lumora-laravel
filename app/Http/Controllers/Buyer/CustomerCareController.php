<?php

namespace App\Http\Controllers\Buyer;

use App\Http\Controllers\Controller;
use App\Models\Order;
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

        if ($topic === 'help') {
            $recentOrders = $request->user()
                ? Order::query()
                    ->where('user_id', $request->user()->id)
                    ->latest('id')
                    ->limit(3)
                    ->get(['id', 'order_number', 'status'])
                : collect();

            return view('buyer.help-center-home', [
                'faqs' => config('help_center.faqs', []),
                'recentOrders' => $recentOrders,
            ]);
        }

        $searchQuery = trim((string) $request->query('q', ''));
        $matchedFaqs = [];
        if ($topic === 'faq' && $searchQuery !== '') {
            $terms = preg_split('/\s+/', mb_strtolower($searchQuery), -1, PREG_SPLIT_NO_EMPTY) ?: [];
            $matchedFaqs = collect(config('help_center.faqs', []))
                ->filter(function (array $faq) use ($terms): bool {
                    $content = mb_strtolower($faq['question'].' '.$faq['answer']);
                    return collect($terms)->every(fn (string $term) => str_contains($content, $term));
                })
                ->values()
                ->all();
        }

        return view('buyer.help-center', [
            'topic' => $topic,
            'title' => self::TOPICS[$topic][0],
            'description' => self::TOPICS[$topic][1],
            'searchQuery' => $searchQuery,
            'matchedFaqs' => $matchedFaqs,
        ]);
    }
}
