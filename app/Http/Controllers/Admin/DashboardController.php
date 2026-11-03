<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Mail\SellerApprovedMail;
use App\Models\Order;
use App\Models\User;
use App\Notifications\PayoutRequestStatusNotification;
use App\Notifications\ProductApprovalRejectedNotification;
use App\Support\CategoryCatalog;
use Barryvdh\DomPDF\Facade\Pdf;
use Carbon\Carbon;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Http\Request;
use Illuminate\Pagination\LengthAwarePaginator;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Mail;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Facades\Storage;
use Illuminate\Validation\Rule;

class DashboardController extends Controller
{
    private const PRODUCT_LOW_STOCK_THRESHOLD = 5;
    private const PRODUCT_OVERDUE_HOURS = 48;

    public function eWalletPayments(Request $request)
    {
        $filters = $this->normalizeEWalletFilters($request);
        $baseQuery = $this->eWalletPaymentsQuery($filters);
        $tabCounts = [
            'all' => (clone $baseQuery)->count(),
            'review' => (clone $baseQuery)->where('payment_status', 'pending')->whereNotNull('payment_proof_path')->count(),
            'verified' => (clone $baseQuery)->where('payment_status', 'paid')->count(),
            'missing' => (clone $baseQuery)->whereNull('payment_proof_path')->count(),
        ];
        $filteredQuery = $this->eWalletPaymentsQuery($filters, $filters['status']);
        $total = (clone $filteredQuery)->count();
        $lastPage = max(1, (int) ceil($total / $filters['per_page']));
        $page = min($filters['page'], $lastPage);

        $orders = $filteredQuery
            ->with(['user', 'seller', 'items.product'])
            ->offset(($page - 1) * $filters['per_page'])
            ->limit($filters['per_page'])
            ->get();

        $proofDisk = Storage::disk(config('filesystems.payment_proof_disk'));
        $orders->each(function (Order $order) use ($proofDisk) {
            $order->setAttribute('payment_proof_available', (bool) $order->payment_proof_path && $proofDisk->exists($order->payment_proof_path));
        });

        $orders = new LengthAwarePaginator($orders, $total, $filters['per_page'], $page, [
            'path' => $request->url(),
            'query' => array_merge($filters, ['page' => $page]),
        ]);

        return view('admin.e-wallet-payments', compact('orders', 'filters', 'tabCounts'));
    }

    public function exportEWalletPayments(Request $request)
    {
        $filters = $this->normalizeEWalletFilters($request);
        $query = $this->eWalletPaymentsQuery($filters, $filters['status'])
            ->with(['user', 'seller']);

        return response()->streamDownload(function () use ($query) {
            $file = fopen('php://output', 'w');
            fputcsv($file, ['Order number', 'Placed at', 'Buyer', 'Buyer email', 'Seller', 'Method', 'Subtotal', 'Shipping', 'Total', 'Order status', 'Payment status', 'Reference last 6', 'Receipt path']);

            foreach ($query->lazy(200) as $order) {
                $values = [
                    $order->order_number,
                    $order->created_at?->format('Y-m-d H:i:s'),
                    $order->user?->name,
                    $order->user?->email,
                    $order->seller?->name,
                    in_array($order->payment_method, ['maya', 'paymaya'], true) ? 'Maya' : 'GCash',
                    number_format((float) $order->subtotal, 2, '.', ''),
                    number_format((float) $order->shipping_fee, 2, '.', ''),
                    number_format((float) $order->total, 2, '.', ''),
                    $order->status_label,
                    ucfirst($order->payment_status),
                    $order->payment_reference_last6,
                    $order->payment_proof_path,
                ];

                fputcsv($file, array_map(function ($value) {
                    $value = (string) ($value ?? '');

                    return preg_match('/^[=+\-@]/', $value) ? "'".$value : $value;
                }, $values));
            }

            fclose($file);
        }, 'e-wallet-payments.csv', ['Content-Type' => 'text/csv; charset=UTF-8']);
    }

    private function normalizeEWalletFilters(Request $request): array
    {
        $allowedPerPage = ['8', '16', '32'];
        $perPageValue = $request->query('per_page', '8');
        $pageValue = $request->query('page', 1);
        $page = is_scalar($pageValue)
            ? (filter_var($pageValue, FILTER_VALIDATE_INT, ['options' => ['min_range' => 1]]) ?: 1)
            : 1;
        $query = $request->query('q', '');

        return [
            'page' => $page,
            'per_page' => is_scalar($perPageValue) && in_array((string) $perPageValue, $allowedPerPage, true) ? (int) $perPageValue : 8,
            'status' => in_array($request->query('status'), ['all', 'review', 'verified', 'missing'], true) ? $request->query('status') : 'all',
            'method' => in_array($request->query('method'), ['all', 'gcash', 'maya'], true) ? $request->query('method') : 'all',
            'q' => is_scalar($query) ? mb_substr(trim((string) $query), 0, 120) : '',
            'sort' => in_array($request->query('sort'), ['attention', 'newest', 'oldest', 'amount'], true) ? $request->query('sort') : 'attention',
            'range' => in_array($request->query('range'), ['30', '7', 'today'], true) ? $request->query('range') : '30',
        ];
    }

    private function eWalletPaymentsQuery(array $filters, ?string $status = null)
    {
        $query = Order::query()->whereIn('payment_method', ['gcash', 'maya', 'paymaya']);

        if ($filters['method'] === 'gcash') {
            $query->where('payment_method', 'gcash');
        } elseif ($filters['method'] === 'maya') {
            $query->whereIn('payment_method', ['maya', 'paymaya']);
        }

        if ($filters['q'] !== '') {
            $term = $filters['q'];
            $query->where(function ($search) use ($term) {
                $search->where('order_number', 'like', '%'.$term.'%');

                if (preg_match('/^\d{6}$/', $term)) {
                    $search->orWhere('payment_reference_last6', $term);
                } else {
                    $search->orWhere('payment_reference_last6', 'like', '%'.$term.'%');
                }

                $search->orWhereHas('user', function ($buyer) use ($term) {
                    $buyer->where('name', 'like', '%'.$term.'%')
                        ->orWhere('email', 'like', '%'.$term.'%');
                });
            });
        }

        $rangeStart = match ($filters['range']) {
            'today' => now()->startOfDay(),
            '7' => now()->subDays(6)->startOfDay(),
            default => now()->subDays(29)->startOfDay(),
        };
        $query->whereBetween('created_at', [$rangeStart, now()->endOfDay()]);

        match ($status) {
            'review' => $query->where('payment_status', 'pending')->whereNotNull('payment_proof_path'),
            'verified' => $query->where('payment_status', 'paid'),
            'missing' => $query->whereNull('payment_proof_path'),
            default => null,
        };

        match ($filters['sort']) {
            'newest' => $query->orderByDesc('created_at'),
            'oldest' => $query->orderBy('created_at'),
            'amount' => $query->orderByDesc('total')->orderByDesc('created_at'),
            default => $query->orderByRaw("CASE WHEN payment_proof_path IS NULL THEN 0 WHEN payment_status = 'pending' THEN 1 WHEN payment_status = 'paid' THEN 2 ELSE 3 END")
                ->orderByDesc('created_at'),
        };

        return $query;
    }

    public function approveEWalletPayment(Order $order)
    {
        abort_unless(in_array($order->payment_method, ['gcash', 'maya', 'paymaya'], true), 404);
        abort_unless($order->payment_status === 'pending' && $order->status === 'pending', 422, 'This order is no longer awaiting payment review.');
        abort_unless(
            $order->payment_proof_path
            && Storage::disk(config('filesystems.payment_proof_disk'))->exists($order->payment_proof_path)
            && preg_match('/^\d{6}$/', (string) $order->payment_reference_last6),
            422,
            'A stored receipt and six digit reference number are required for approval.'
        );

        DB::transaction(function () use ($order) {
            $order->update(['payment_status' => 'paid']);
            DB::table('order_items')
                ->where('order_id', $order->id)
                ->update(['seen_at' => null, 'updated_at' => now()]);
        });

        return redirect()->route('admin.e-wallet-payments')->with('flash_success', 'Payment approved for order '.$order->order_number.'.');
    }

    public function eWalletPaymentProof(Order $order)
    {
        abort_unless(in_array($order->payment_method, ['gcash', 'maya', 'paymaya'], true), 404);
        $proofDisk = Storage::disk(config('filesystems.payment_proof_disk'));
        abort_unless($order->payment_proof_path && $proofDisk->exists($order->payment_proof_path), 404);

        return $proofDisk->response(
            $order->payment_proof_path,
            null,
            ['Cache-Control' => 'private, no-store'],
            'inline'
        );
    }

    public function rejectEWalletPayment(Order $order)
    {
        abort_unless(in_array($order->payment_method, ['gcash', 'maya', 'paymaya'], true), 404);
        abort_unless($order->payment_status === 'pending' && $order->status === 'pending', 422, 'This order is no longer awaiting payment review.');

        DB::transaction(function () use ($order) {
            $order->update([
                'payment_status' => 'failed',
                'status' => 'cancelled',
                'cancelled_at' => now(),
            ]);
            $order->statusHistory()->create([
                'status' => 'cancelled',
                'remarks' => 'E-wallet payment receipt rejected by admin.',
                'changed_by' => auth()->id(),
            ]);
        });

        return redirect()->route('admin.e-wallet-payments')->with('flash_success', 'Payment rejected and order '.$order->order_number.' cancelled.');
    }

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

    public function productApproval(Request $request)
    {
        $now = now();
        $sevenDaysAgo = $now->copy()->subDays(7);
        $pendingCount = DB::table('products')->where('approval_status', 'pending')->count();
        $overdueCutoff = $now->copy()->subHours(self::PRODUCT_OVERDUE_HOURS);
        $overdueCount = DB::table('products')->where('approval_status', 'pending')->where(function ($query) use ($overdueCutoff) {
            $query->where('approval_submitted_at', '<=', $overdueCutoff)
                ->orWhere(function ($fallback) use ($overdueCutoff) {
                    $fallback->whereNull('approval_submitted_at')->where('created_at', '<=', $overdueCutoff);
                });
        })->count();
        $approvedTodayCount = DB::table('products')->where('approval_status', 'approved')->whereBetween('approved_at', [$now->copy()->startOfDay(), $now])->count();
        $recentlyReviewed = DB::table('products')
            ->where(function ($query) use ($sevenDaysAgo, $now) {
                $query->whereBetween('approved_at', [$sevenDaysAgo, $now])
                    ->orWhereBetween('rejected_at', [$sevenDaysAgo, $now]);
            })
            ->select(['created_at', 'approval_submitted_at', 'approved_at', 'rejected_at'])
            ->cursor();
        $reviewDurationTotal = 0;
        $reviewDurationCount = 0;
        foreach ($recentlyReviewed as $product) {
            $finishedAt = $product->approved_at ?: $product->rejected_at;
            if ($finishedAt) {
                $submittedAt = $product->approval_submitted_at ?: $product->created_at;
                $reviewDurationTotal += Carbon::parse($submittedAt)->diffInSeconds(Carbon::parse($finishedAt));
                $reviewDurationCount++;
            }
        }
        $averageReviewHours = $reviewDurationCount === 0 ? null : round(($reviewDurationTotal / $reviewDurationCount) / 3600, 1);

        $status = in_array($request->query('status'), ['pending', 'approved', 'rejected'], true)
            ? $request->query('status')
            : 'pending';
        $searchInput = $request->query('q', '');
        $categoryInput = $request->query('category', '');
        $filters = [
            'q' => mb_substr(trim(is_scalar($searchInput) ? (string) $searchInput : ''), 0, 120),
            'category' => is_scalar($categoryInput) ? (string) $categoryInput : '',
            'seller_type' => in_array($request->query('seller_type'), ['new', 'verified'], true) ? $request->query('seller_type') : 'all',
            'sort' => in_array($request->query('sort'), ['newest', 'price'], true) ? $request->query('sort') : 'oldest',
        ];
        $pageSize = 5;
        $skuExists = Schema::hasColumn('products', 'sku');
        $imagesExist = Schema::hasColumn('products', 'images');
        $history = DB::table('products')
            ->select('seller_id')
            ->selectRaw('COUNT(*) as seller_product_count')
            ->selectRaw("SUM(CASE WHEN approval_status = 'approved' THEN 1 ELSE 0 END) as seller_approved_count")
            ->selectRaw("SUM(CASE WHEN approval_status = 'rejected' THEN 1 ELSE 0 END) as seller_rejected_count")
            ->groupBy('seller_id');
        $verifiedApplications = DB::table('seller_applications')
            ->select('user_id')
            ->selectRaw('MAX(id) as approved_application_id')
            ->where('status', 'approved')
            ->groupBy('user_id');
        $query = DB::table('products as p')
            ->join('users as u', 'u.id', '=', 'p.seller_id')
            ->leftJoinSub($verifiedApplications, 'verified_applications', fn ($join) => $join->on('verified_applications.user_id', '=', 'u.id'))
            ->leftJoinSub($history, 'seller_history', fn ($join) => $join->on('seller_history.seller_id', '=', 'u.id'))
            ->leftJoinSub(DB::table('products')->select('category')->selectRaw('AVG(price) as category_average_price')->groupBy('category'), 'category_prices', fn ($join) => $join->on('category_prices.category', '=', 'p.category'))
            ->where('p.approval_status', $status);

        if ($filters['category'] !== '') {
            $query->where('p.category', $filters['category']);
        }
        if ($filters['seller_type'] === 'verified') {
            $query->whereNotNull('verified_applications.approved_application_id');
        } elseif ($filters['seller_type'] === 'new') {
            $query->where('u.created_at', '>=', $now->copy()->subDays(30));
        }
        if ($filters['q'] !== '') {
            $term = '%'.$filters['q'].'%';
            $query->where(function ($search) use ($term, $skuExists) {
                $search->where('p.name', 'like', $term)->orWhere('u.name', 'like', $term);
                if ($skuExists) {
                    $search->orWhere('p.sku', 'like', $term);
                }
            });
        }

        $columns = [
            'p.id', 'p.name', 'p.category', 'p.description', 'p.price', 'p.stock', 'p.image', 'p.created_at',
            'p.approval_status', 'p.approval_submitted_at', 'p.approved_at', 'p.rejected_at', 'p.rejection_reason', 'p.rejection_note',
            'u.id as seller_id', 'u.name as seller_name', 'u.created_at as seller_created_at',
            'verified_applications.approved_application_id', 'seller_history.seller_product_count',
            'seller_history.seller_approved_count', 'seller_history.seller_rejected_count', 'category_prices.category_average_price',
        ];
        if ($skuExists) $columns[] = 'p.sku';
        if ($imagesExist) $columns[] = 'p.images';

        $query->select($columns);
        match ($filters['sort']) {
            'newest' => $query->orderByDesc('p.created_at'),
            'price' => $query->orderByDesc('p.price')->orderBy('p.created_at'),
            default => $query->orderBy('p.created_at'),
        };

        $products = $query->paginate($pageSize)->withQueryString();
        $categories = DB::table('products')->whereNotNull('category')->where('category', '!=', '')->distinct()->orderBy('category')->pluck('category');
        $tabCounts = DB::table('products')->select('approval_status')->selectRaw('COUNT(*) as aggregate')->whereIn('approval_status', ['pending', 'approved', 'rejected'])->groupBy('approval_status')->pluck('aggregate', 'approval_status');

        $lowStockThreshold = self::PRODUCT_LOW_STOCK_THRESHOLD;
        $overdueThresholdHours = self::PRODUCT_OVERDUE_HOURS;

        return view('admin.product-approval', compact('products', 'status', 'filters', 'categories', 'tabCounts', 'pendingCount', 'overdueCount', 'approvedTodayCount', 'averageReviewHours', 'skuExists', 'lowStockThreshold', 'overdueThresholdHours'));
    }

    public function approveProduct(Request $request, $id)
    {
        $product = $this->applyProductApproval((int) $id, 'approved');
        $message = 'Product approved and published.';

        return $request->expectsJson()
            ? response()->json(['success' => true, 'message' => $message, 'id' => (int) $id])
            : redirect()->route('admin.product-approval')->with('flash_success', $message);
    }

    public function rejectProduct(Request $request, $id)
    {
        $validated = $request->validate([
            'reason' => ['required', Rule::in($this->productRejectionReasons())],
            'note' => ['nullable', 'string', 'max:2000'],
        ]);
        $this->applyProductApproval((int) $id, 'rejected', $validated['reason'], $validated['note'] ?? null);
        $message = 'Product rejected and the seller was notified.';

        return $request->expectsJson()
            ? response()->json(['success' => true, 'message' => $message, 'id' => (int) $id])
            : redirect()->route('admin.product-approval')->with('flash_success', $message);
    }

    public function bulkProductApproval(Request $request)
    {
        $validated = $request->validate([
            'action' => ['required', Rule::in(['approved', 'rejected'])],
            'ids' => ['required', 'array', 'min:1', 'max:100'],
            'ids.*' => ['required', 'integer', 'distinct'],
            'reason' => ['required_if:action,rejected', Rule::in($this->productRejectionReasons())],
            'note' => ['nullable', 'string', 'max:2000'],
        ]);
        $changed = [];
        foreach ($validated['ids'] as $id) {
            $product = $this->applyProductApproval((int) $id, $validated['action'], $validated['reason'] ?? null, $validated['note'] ?? null, false);
            if ($product) $changed[] = (int) $id;
        }
        $message = count($changed).' product'.(count($changed) === 1 ? '' : 's').' '.($validated['action'] === 'approved' ? 'approved and published.' : 'rejected; sellers were notified.');

        return $request->expectsJson()
            ? response()->json(['success' => true, 'message' => $message, 'ids' => $changed])
            : redirect()->route('admin.product-approval')->with('flash_success', $message);
    }

    private function productRejectionReasons(): array
    {
        return ['Photos unclear or missing', 'Price looks incorrect', 'Description incomplete', 'Prohibited item', 'Other'];
    }

    private function applyProductApproval(int $id, string $decision, ?string $reason = null, ?string $note = null, bool $failIfMissing = true): ?object
    {
        return DB::transaction(function () use ($id, $decision, $reason, $note, $failIfMissing) {
            $product = DB::table('products')->where('id', $id)->where('approval_status', 'pending')->lockForUpdate()->first();
            if (! $product) {
                if ($failIfMissing) abort(404, 'This product is no longer awaiting approval.');
                return null;
            }
            $now = now();
            $changes = [
                'approval_status' => $decision,
                'status' => $decision === 'approved' ? 'active' : 'inactive',
                'approved_at' => $decision === 'approved' ? $now : null,
                'rejected_at' => $decision === 'rejected' ? $now : null,
                'rejection_reason' => $decision === 'rejected' ? $reason : null,
                'rejection_note' => $decision === 'rejected' ? $note : null,
                'updated_at' => $now,
            ];
            DB::table('products')->where('id', $id)->update($changes);
            if ($decision === 'rejected') {
                User::find($product->seller_id)?->notify(new ProductApprovalRejectedNotification((int) $id, $product->name, (string) $reason, $note));
            }
            return $product;
        });
    }

    public function index()
    {
        $totalSales = DB::table('order_items as oi')
            ->join('orders as o', 'o.id', '=', 'oi.order_id')
            ->where('o.payment_status', 'paid')
            ->sum(DB::raw('oi.price * oi.quantity'));

        $totalOrders = DB::table('orders')->count();
        $totalProducts = DB::table('products')->count();
        $totalBuyers = DB::table('users')->where('role', 'buyer')->count();

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
        $newStatus = match ($action) {
            'approve' => 'approved',
            'reject' => 'rejected',
            'archive' => 'archived',
            default => null,
        };

        if (! $newStatus) {
            abort(404);
        }

        DB::table('seller_applications')->where('id', $id)->update(['status' => $newStatus]);

        if ($newStatus === 'approved') {
            $app = DB::table('seller_applications')->find($id);
            $seller = DB::table('users')->find($app->user_id);

            DB::table('users')->where('id', $app->user_id)->update(['role' => 'seller']);

            if ($seller) {
                Mail::to($seller->email)->send(new SellerApprovedMail($seller->name, $app->business_name));
            }
        }

        session()->flash('flash_success', 'Application '.$newStatus.'.');

        return redirect()->route('admin.dashboard');
    }

    public function handleUserStatus($id, $action)
    {
        $newStatus = match ($action) {
            'activate' => 'active',
            'suspend' => 'suspended',
            'deactivate' => 'deactivated',
            default => null,
        };

        if (! $newStatus) {
            abort(404);
        }

        DB::table('users')->where('id', $id)->update(['status' => $newStatus]);

        session()->flash('flash_success', 'User account '.$newStatus.'.');

        return redirect()->route('admin.users');
    }

    /**
     * Compliance dashboard: lists every product with its seller and the seller's
     * registered category (from their approved seller_applications row, if any),
     * so admin can spot mismatches and manually flag prohibited items.
     *
     * Note: if a seller somehow has more than one 'approved' application row,
     * this join may show one of them arbitrarily — fine for now since sellers
     * normally only get approved once.
     */
    public function compliance()
    {
        $products = DB::table('products as p')
            ->join('users as u', 'u.id', '=', 'p.seller_id')
            ->leftJoin('seller_applications as sa', function ($join) {
                $join->on('sa.user_id', '=', 'u.id')
                    ->where('sa.status', '=', 'approved');
            })
            ->select(
                'p.id as product_id',
                'p.name as product_name',
                'p.category as product_category',
                'p.status as product_status',
                'u.id as seller_id',
                'u.name as seller_name',
                'u.status as seller_status',
                'sa.category as registered_category'
            )
            ->orderBy('u.name')
            ->orderByDesc('p.created_at')
            ->get();

        // Warning history per seller, newest first, grouped by seller_id
        $warningsBySeller = DB::table('seller_warnings')
            ->orderByDesc('created_at')
            ->get()
            ->groupBy('seller_id');

        return view('admin.compliance', compact('products', 'warningsBySeller'));
    }

    public function flagProduct($id)
    {
        DB::table('products')->where('id', $id)->update([
            'status' => 'flagged',
            'updated_at' => now(),
        ]);

        session()->flash('flash_success', 'Product flagged as prohibited and hidden from the storefront.');

        return redirect()->route('admin.compliance');
    }

    public function clearProduct($id)
    {
        DB::table('products')->where('id', $id)->update([
            'status' => DB::raw("CASE WHEN approval_status = 'approved' THEN 'active' ELSE 'inactive' END"),
            'updated_at' => now(),
        ]);

        session()->flash('flash_success', 'Product cleared and set back to active.');

        return redirect()->route('admin.compliance');
    }

    public function warnSeller(Request $request, $id)
    {
        $request->validate([
            'reason' => ['required', 'string', 'max:1000'],
            'product_id' => ['nullable', 'integer'],
        ]);

        DB::table('seller_warnings')->insert([
            'seller_id' => $id,
            'product_id' => $request->product_id,
            'reason' => $request->reason,
            'created_at' => now(),
            'updated_at' => now(),
        ]);

        $seller = DB::table('users')->find($id);
        session()->flash('flash_success', 'Warning logged for '.($seller->name ?? 'this seller').'.');

        return redirect()->route('admin.compliance');
    }

    /**
     * Complaints & Disputes: lists buyer-filed complaints against a product/seller,
     * with supporting evidence images, so admin can review and coordinate a resolution.
     * (Buyer-facing filing page not built yet — rows are inserted manually for now.)
     */
    public function complaints()
    {
        $complaints = DB::table('complaints as c')
            ->join('users as buyer', 'buyer.id', '=', 'c.buyer_id')
            ->join('users as seller', 'seller.id', '=', 'c.seller_id')
            ->join('products as p', 'p.id', '=', 'c.product_id')
            ->select(
                'c.*',
                'buyer.name as buyer_name',
                'buyer.email as buyer_email',
                'seller.name as seller_name',
                'seller.email as seller_email',
                'p.name as product_name'
            )
            ->orderByDesc('c.created_at')
            ->get();

        // Evidence images grouped by complaint_id
        $evidenceByComplaint = DB::table('complaint_evidence')
            ->orderBy('id')
            ->get()
            ->groupBy('complaint_id');

        return view('admin.complaints', compact('complaints', 'evidenceByComplaint'));
    }

    public function resolveComplaint(Request $request, $id)
    {
        $request->validate(['admin_note' => ['required', 'string', 'max:1000']]);

        DB::table('complaints')->where('id', $id)->update([
            'status' => 'resolved',
            'admin_note' => $request->admin_note,
            'resolved_at' => now(),
            'updated_at' => now(),
        ]);

        session()->flash('flash_success', 'Complaint marked as resolved.');

        return redirect()->route('admin.complaints');
    }

    public function dismissComplaint(Request $request, $id)
    {
        $request->validate(['admin_note' => ['required', 'string', 'max:1000']]);

        DB::table('complaints')->where('id', $id)->update([
            'status' => 'dismissed',
            'admin_note' => $request->admin_note,
            'resolved_at' => now(),
            'updated_at' => now(),
        ]);

        session()->flash('flash_success', 'Complaint dismissed.');

        return redirect()->route('admin.complaints');
    }

    /**
     * Commission dashboard: platform takes 10% of every paid sale.
     * Shows total commission earned platform-wide and a breakdown per seller.
     */
    public function commission()
    {
        $commissionRate = 0.10;

        $sellerSales = DB::table('order_items as oi')
            ->join('products as p', 'p.id', '=', 'oi.product_id')
            ->join('orders as o', 'o.id', '=', 'oi.order_id')
            ->join('users as u', 'u.id', '=', 'p.seller_id')
            ->where('o.payment_status', 'paid')
            ->select('u.id as seller_id', 'u.name as seller_name', DB::raw('SUM(oi.price * oi.quantity) as gross_sales'))
            ->groupBy('u.id', 'u.name')
            ->orderByDesc('gross_sales')
            ->get()
            ->map(function ($row) use ($commissionRate) {
                $row->commission = round($row->gross_sales * $commissionRate, 2);
                $row->net_earnings = round($row->gross_sales - $row->commission, 2);

                return $row;
            });

        $totalGrossSales = $sellerSales->sum('gross_sales');
        $totalCommission = $sellerSales->sum('commission');

        return view('admin.commission', compact('sellerSales', 'totalGrossSales', 'totalCommission', 'commissionRate'));
    }

    public function payoutRequests(Request $request)
    {
        $status = $request->input('status', 'pending');
        abort_unless(in_array($status, ['pending', 'approved', 'paid', 'rejected', 'all'], true), 404);

        $query = DB::table('payout_requests as pr')
            ->join('users as u', 'u.id', '=', 'pr.seller_id')
            ->select('pr.*', 'u.name as seller_name', 'u.email as seller_email');

        if ($status !== 'all') {
            $query->where('pr.status', $status);
        }

        $payouts = $query->orderByRaw("CASE pr.status WHEN 'pending' THEN 0 WHEN 'approved' THEN 1 ELSE 2 END")
            ->orderByDesc('pr.created_at')
            ->paginate(20)
            ->withQueryString();

        $pendingCount = DB::table('payout_requests')->where('status', 'pending')->count();
        $pendingAmount = DB::table('payout_requests')->where('status', 'pending')->sum('amount');
        $approvedAmount = DB::table('payout_requests')->where('status', 'approved')->sum('amount');
        $paidAmount = DB::table('payout_requests')->where('status', 'paid')->sum('amount');
        $confirmedWalletReceipts = DB::table('orders')
            ->whereIn('payment_method', ['gcash', 'maya', 'paymaya'])
            ->where('payment_status', 'paid')
            ->sum('total');
        $estimatedUnallocatedFunds = (float) $confirmedWalletReceipts
            - (float) $pendingAmount
            - (float) $approvedAmount
            - (float) $paidAmount;

        return view('admin.payout-requests', compact(
            'payouts', 'status', 'pendingCount', 'pendingAmount', 'approvedAmount', 'paidAmount',
            'confirmedWalletReceipts', 'estimatedUnallocatedFunds'
        ));
    }

    public function approvePayoutRequest(int $id)
    {
        $payout = DB::transaction(function () use ($id) {
            $payout = DB::table('payout_requests')->where('id', $id)->lockForUpdate()->first();
            abort_unless($payout && $payout->status === 'pending', 422, 'This payout request is no longer pending.');

            DB::table('payout_requests')->where('id', $id)->update([
                'status' => 'approved',
                'reviewed_by' => auth()->id(),
                'reviewed_at' => now(),
                'updated_at' => now(),
            ]);

            return $payout;
        });

        User::find($payout->seller_id)?->notify(new PayoutRequestStatusNotification((int) $id, 'approved', (float) $payout->amount));

        return redirect()->route('admin.payout-requests.index')->with('flash_success', 'Payout request approved. Send the transfer, then record it as paid.');
    }

    public function rejectPayoutRequest(Request $request, int $id)
    {
        $validated = $request->validate(['rejection_reason' => ['required', 'string', 'max:1000']]);

        $payout = DB::transaction(function () use ($id, $validated) {
            $payout = DB::table('payout_requests')->where('id', $id)->lockForUpdate()->first();
            abort_unless($payout && $payout->status === 'pending', 422, 'Only pending payout requests can be rejected.');

            DB::table('payout_requests')->where('id', $id)->update([
                'status' => 'rejected',
                'reviewed_by' => auth()->id(),
                'reviewed_at' => now(),
                'rejection_reason' => $validated['rejection_reason'],
                'updated_at' => now(),
            ]);

            return $payout;
        });

        User::find($payout->seller_id)?->notify(new PayoutRequestStatusNotification((int) $id, 'rejected', (float) $payout->amount, reason: $validated['rejection_reason']));

        return redirect()->route('admin.payout-requests.index')->with('flash_success', 'Payout request rejected. The reserved seller balance is released.');
    }

    public function markPayoutRequestPaid(Request $request, int $id)
    {
        $validated = $request->validate(['transfer_reference' => ['required', 'string', 'max:120']]);

        $payout = DB::transaction(function () use ($id, $validated) {
            $payout = DB::table('payout_requests')->where('id', $id)->lockForUpdate()->first();
            abort_unless($payout && $payout->status === 'approved', 422, 'Approve this request before marking it paid.');

            DB::table('payout_requests')->where('id', $id)->update([
                'status' => 'paid',
                'paid_at' => now(),
                'transfer_reference' => $validated['transfer_reference'],
                'updated_at' => now(),
            ]);

            return $payout;
        });

        User::find($payout->seller_id)?->notify(new PayoutRequestStatusNotification((int) $id, 'paid', (float) $payout->amount, transferReference: $validated['transfer_reference']));

        return redirect()->route('admin.payout-requests.index')->with('flash_success', 'Payout marked as paid and seller notified.');
    }

    /**
     * Turns the 'range' or 'start_date'/'end_date' query params into a
     * concrete [start, end] Carbon date pair. Custom dates win if both given.
     */
    private function resolveDateRange(Request $request): array
    {
        if ($request->filled('start_date') && $request->filled('end_date')) {
            $start = Carbon::parse($request->start_date)->startOfDay();
            $end = Carbon::parse($request->end_date)->endOfDay();
        } else {
            $days = (int) $request->input('range', 7);
            if ($days <= 0) {
                $days = 7;
            }
            $end = now()->endOfDay();
            $start = now()->subDays($days - 1)->startOfDay();
        }

        return [$start, $end];
    }

    public function salesSummaryPdf(Request $request)
    {
        [$start, $end] = $this->resolveDateRange($request);

        $totalSales = DB::table('order_items as oi')
            ->join('orders as o', 'o.id', '=', 'oi.order_id')
            ->where('o.payment_status', 'paid')
            ->whereBetween('o.created_at', [$start, $end])
            ->sum(DB::raw('oi.price * oi.quantity'));

        $totalOrders = DB::table('orders')
            ->where('payment_status', 'paid')
            ->whereBetween('created_at', [$start, $end])
            ->count();

        $avgOrderValue = $totalOrders > 0 ? $totalSales / $totalOrders : 0;

        $topProducts = DB::table('order_items as oi')
            ->join('orders as o', 'o.id', '=', 'oi.order_id')
            ->join('products as p', 'p.id', '=', 'oi.product_id')
            ->join('users as u', 'u.id', '=', 'p.seller_id')
            ->where('o.payment_status', 'paid')
            ->whereBetween('o.created_at', [$start, $end])
            ->select(
                'p.name as product_name',
                'u.name as seller_name',
                DB::raw('SUM(oi.quantity) as units_sold'),
                DB::raw('SUM(oi.price * oi.quantity) as revenue')
            )
            ->groupBy('p.id', 'p.name', 'u.name')
            ->orderByDesc('revenue')
            ->limit(10)
            ->get();

        $topSellers = DB::table('order_items as oi')
            ->join('orders as o', 'o.id', '=', 'oi.order_id')
            ->join('products as p', 'p.id', '=', 'oi.product_id')
            ->join('users as u', 'u.id', '=', 'p.seller_id')
            ->where('o.payment_status', 'paid')
            ->whereBetween('o.created_at', [$start, $end])
            ->select(
                'u.name as seller_name',
                DB::raw('COUNT(DISTINCT oi.order_id) as orders_count'),
                DB::raw('SUM(oi.price * oi.quantity) as revenue')
            )
            ->groupBy('u.id', 'u.name')
            ->orderByDesc('revenue')
            ->limit(10)
            ->get();

        $pdf = Pdf::loadView('admin.reports.sales-summary-pdf', compact(
            'totalSales', 'totalOrders', 'avgOrderValue', 'topProducts', 'topSellers', 'start', 'end'
        ));

        return $pdf->download('sales-summary-report-'.now()->format('Y-m-d').'.pdf');
    }

    public function commissionReportPdf(Request $request)
    {
        [$start, $end] = $this->resolveDateRange($request);
        $commissionRate = 0.10;

        $sellerSales = DB::table('order_items as oi')
            ->join('products as p', 'p.id', '=', 'oi.product_id')
            ->join('orders as o', 'o.id', '=', 'oi.order_id')
            ->join('users as u', 'u.id', '=', 'p.seller_id')
            ->where('o.payment_status', 'paid')
            ->whereBetween('o.created_at', [$start, $end])
            ->select('u.id as seller_id', 'u.name as seller_name', DB::raw('SUM(oi.price * oi.quantity) as gross_sales'))
            ->groupBy('u.id', 'u.name')
            ->orderByDesc('gross_sales')
            ->get()
            ->map(function ($row) use ($commissionRate) {
                $row->commission = round($row->gross_sales * $commissionRate, 2);
                $row->net_earnings = round($row->gross_sales - $row->commission, 2);

                return $row;
            });

        $totalGrossSales = $sellerSales->sum('gross_sales');
        $totalCommission = $sellerSales->sum('commission');
        $totalNet = $sellerSales->sum('net_earnings');

        $pdf = Pdf::loadView('admin.reports.commission-pdf', compact(
            'sellerSales', 'totalGrossSales', 'totalCommission', 'totalNet', 'commissionRate', 'start', 'end'
        ));

        return $pdf->download('commission-report-'.now()->format('Y-m-d').'.pdf');
    }

    private function ensureVouchersTableExists(): void
    {
        try {
            if (! Schema::hasTable('vouchers')) {
                Schema::create('vouchers', function (Blueprint $table) {
                    $table->id();
                    $table->string('code', 50)->unique();
                    $table->string('type', 20)->default('percent');
                    $table->decimal('value', 10, 2)->default(0);
                    $table->decimal('min_spend', 10, 2)->default(0);
                    $table->integer('usage_limit')->nullable();
                    $table->integer('used_count')->default(0);
                    $table->date('expires_at')->nullable();
                    $table->boolean('is_active')->default(true);
                    $table->timestamps();
                });
            }
        } catch (\Throwable $e) {
            // Ignore dynamic schema error
        }
    }

    public function vouchers()
    {
        $this->ensureVouchersTableExists();
        $vouchers = DB::table('vouchers')->orderByDesc('created_at')->get();

        return view('admin.vouchers', compact('vouchers'));
    }

    public function storeVoucher(Request $request)
    {
        $this->ensureVouchersTableExists();

        $validated = $request->validate([
            'code' => ['required', 'string', 'max:50'],
            'type' => ['required', 'in:percent,shipping'],
            'value' => ['nullable', 'numeric', 'min:0', 'max:100', 'required_if:type,percent'],
            'min_spend' => ['nullable', 'numeric', 'min:0'],
            'usage_limit' => ['nullable', 'integer', 'min:1'],
            'expires_at' => ['nullable', 'date'],
        ]);

        $code = strtoupper(trim($validated['code']));

        DB::table('vouchers')->updateOrInsert(
            ['code' => $code],
            [
                'type' => $validated['type'],
                'value' => $validated['type'] === 'shipping' ? 0 : (float) ($validated['value'] ?? 0),
                'min_spend' => (float) ($validated['min_spend'] ?? 0),
                'usage_limit' => $validated['usage_limit'] ?? null,
                'expires_at' => $validated['expires_at'] ?? null,
                'is_active' => true,
                'updated_at' => now(),
                'created_at' => now(),
            ]
        );

        return back()->with('flash_success', "Voucher {$code} saved successfully.");
    }

    public function toggleVoucher($id)
    {
        $this->ensureVouchersTableExists();
        $voucher = DB::table('vouchers')->where('id', $id)->first();
        if ($voucher) {
            DB::table('vouchers')->where('id', $id)->update([
                'is_active' => ! $voucher->is_active,
                'updated_at' => now(),
            ]);
        }

        return back()->with('flash_success', 'Voucher status updated.');
    }

    public function destroyVoucher($id)
    {
        $this->ensureVouchersTableExists();
        DB::table('vouchers')->where('id', $id)->delete();

        return back()->with('flash_success', 'Voucher removed.');
    }
}
