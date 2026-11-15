<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\User;
use App\Models\UserStatusLog;
use App\Notifications\UserDeactivatedNotification;
use App\Notifications\UserReactivatedNotification;
use App\Notifications\UserSuspendedNotification;
use Illuminate\Database\Eloquent\Builder;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;
use Symfony\Component\HttpFoundation\StreamedResponse;

class UserController extends Controller
{
    private const ROLES = ['buyer', 'seller', 'admin'];
    private const STATUSES = ['active', 'email-unverified', 'suspended', 'deactivated'];
    private const SORTS = ['newest', 'oldest', 'name', 'last_active'];
    private const SUSPEND_REASONS = ['policy_violation', 'suspicious_activity', 'user_request', 'other'];
    private const DEACTIVATE_REASONS = ['fraud', 'terms_violation', 'user_request', 'other'];

    public function index(Request $request)
    {
        $filters = $this->filters($request);
        $groupedCounts = User::query()
            ->selectRaw('role, status, COUNT(*) as total')
            ->groupBy('role', 'status')
            ->get();
        $roleCounts = $groupedCounts->groupBy('role')->map->sum('total');
        $totalCount = (int) $groupedCounts->sum('total');
        $suspendedCount = (int) $groupedCounts->whereIn('status', ['suspended', 'banned'])->sum('total');
        $deactivatedCount = (int) $groupedCounts->where('status', 'deactivated')->sum('total');
        $stats = [
            'total' => $totalCount,
            'new_this_week' => User::query()->where('created_at', '>=', now()->startOfWeek())->count(),
            'buyers' => (int) $roleCounts->get('buyer', 0),
            'sellers' => (int) $groupedCounts->where('role', 'seller')->where('status', 'active')->sum('total'),
            'suspended_deactivated' => $suspendedCount + $deactivatedCount,
        ];

        $query = $this->filteredQuery($filters)
            ->withCount([
                'orders as orders_count',
                'soldOrders as sold_orders_count',
                'products as products_count',
                'products as live_products_count' => fn (Builder $products) => $products->where('status', 'active')->where('approval_status', 'approved'),
            ])
            ->withSum(['orders as total_spent' => fn (Builder $orders) => $orders->whereNotIn('status', ['cancelled', 'returned'])], 'total')
            ->withSum(['soldOrders as total_sales' => fn (Builder $orders) => $orders->whereNotIn('status', ['cancelled', 'returned'])], 'total')
            ->with(['statusLogs' => fn ($logs) => $logs->with('admin:id,name')->limit(8)]);

        $query = $this->applySort($query, $filters['sort']);
        $users = $query->paginate(15)->withQueryString();

        $duplicateNames = $this->duplicateKeys('name', "LOWER(REPLACE(REPLACE(REPLACE(TRIM(name), ' ', ''), '.', ''), '-', ''))");
        $duplicateStores = $this->duplicateKeys('shop_name', "LOWER(REPLACE(REPLACE(REPLACE(TRIM(shop_name), ' ', ''), '.', ''), '-', ''))");
        $duplicatePhones = $this->duplicateKeys('contact_number', "REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(contact_number, ' ', ''), '-', ''), '(', ''), ')', ''), '+', ''), '.', '')");

        return view('admin.users', [
            'users' => $users,
            'filters' => $filters,
            'stats' => $stats,
            'roleCounts' => $roleCounts,
            'duplicateNames' => $duplicateNames,
            'duplicateStores' => $duplicateStores,
            'duplicatePhones' => $duplicatePhones,
            'suspendReasons' => self::SUSPEND_REASONS,
            'deactivateReasons' => self::DEACTIVATE_REASONS,
        ]);
    }

    public function export(Request $request): StreamedResponse
    {
        $filters = $this->filters($request);
        $query = $this->applySort($this->filteredQuery($filters), $filters['sort']);

        return response()->streamDownload(function () use ($query) {
            $stream = fopen('php://output', 'w');
            fputcsv($stream, ['name', 'email', 'role', 'status', 'joined', 'last active', 'orders/products']);
            $query->withCount(['orders as orders_count', 'soldOrders as sold_orders_count', 'products as products_count'])
                ->orderBy('id')
                ->chunk(500, function ($users) use ($stream) {
                    foreach ($users as $user) {
                        fputcsv($stream, [
                            $user->name,
                            $user->email,
                            $user->role,
                            $this->displayStatus($user),
                            $user->created_at?->toDateTimeString(),
                            $user->last_login_at?->toDateTimeString(),
                            $user->role === 'seller' ? $user->products_count : $user->orders_count,
                        ]);
                    }
                });
            fclose($stream);
        }, 'lumora-users.csv', ['Content-Type' => 'text/csv; charset=UTF-8']);
    }

    public function suspend(Request $request, User $user)
    {
        $this->assertManageable($user);
        abort_if(in_array($user->status, ['suspended', 'banned', 'deactivated'], true), 422, 'This account cannot be suspended in its current state.');
        $validated = $request->validate([
            'reason' => ['required', 'string', 'in:'.implode(',', self::SUSPEND_REASONS)],
            'message' => ['required', 'string', 'max:2000'],
            'duration' => ['required', 'in:7,30,indefinite'],
        ]);
        $until = match ($validated['duration']) {
            '7' => now()->addDays(7),
            '30' => now()->addDays(30),
            default => null,
        };
        $this->recordStatusChange($user, 'suspended', 'suspended', $validated['reason'], $validated['message'], $until);
        $this->invalidateSessions($user);
        $user->notify(new UserSuspendedNotification($this->readableReason($validated['reason']), $validated['message'], $until));

        return $this->redirectSuccess($user, 'Account suspended.');
    }

    public function deactivate(Request $request, User $user)
    {
        $this->assertManageable($user);
        abort_if($user->status === 'deactivated', 422, 'This account is already deactivated.');
        $validated = $request->validate([
            'reason' => ['required', 'string', 'in:'.implode(',', self::DEACTIVATE_REASONS)],
            'message' => ['required', 'string', 'max:2000'],
            'confirmation' => ['required', 'in:DEACTIVATE'],
        ]);
        $this->recordStatusChange($user, 'deactivated', 'deactivated', $validated['reason'], $validated['message'], null);
        $this->invalidateSessions($user);
        $user->notify(new UserDeactivatedNotification($this->readableReason($validated['reason']), $validated['message']));

        return $this->redirectSuccess($user, 'Account deactivated. Open orders were left unchanged.');
    }

    public function reactivate(User $user)
    {
        $this->assertManageable($user);
        abort_unless(in_array($user->status, ['suspended', 'deactivated', 'banned'], true), 422, 'This account is already active.');
        $this->recordStatusChange($user, 'active', 'reactivated', 'admin_reactivation', 'Account access restored.', null);
        $user->notify(new UserReactivatedNotification('admin_reactivation', 'Your account access has been restored.'));

        return $this->redirectSuccess($user, 'Account reactivated.');
    }

    private function filters(Request $request): array
    {
        $role = $request->query('role', 'all');
        $status = $request->query('status', 'all');
        $sort = $request->query('sort', 'newest');
        $search = $request->query('q', '');

        return [
            'role' => in_array($role, ['all', ...self::ROLES], true) ? $role : 'all',
            'status' => in_array($status, ['all', ...self::STATUSES], true) ? $status : 'all',
            'sort' => in_array($sort, self::SORTS, true) ? $sort : 'newest',
            'q' => mb_substr(trim(is_scalar($search) ? (string) $search : ''), 0, 120),
        ];
    }

    private function filteredQuery(array $filters): Builder
    {
        $query = User::query()->select([
            'id', 'name', 'first_name', 'last_name', 'email', 'email_verified', 'email_verified_at',
            'contact_number', 'role', 'status', 'suspended_until', 'created_at', 'last_login_at',
            'shop_name', 'province', 'municipality', 'barangay',
        ]);
        if ($filters['role'] !== 'all') $query->where('role', $filters['role']);
        if ($filters['q'] !== '') {
            $term = '%'.$filters['q'].'%';
            $digits = preg_replace('/\D+/u', '', $filters['q']);
            $query->where(function (Builder $search) use ($term, $digits) {
                $search->where('name', 'like', $term)
                    ->orWhere('shop_name', 'like', $term)
                    ->orWhere('email', 'like', $term)
                    ->orWhere('contact_number', 'like', $term);
                if ($digits !== '') {
                    $normalizedPhone = "REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(contact_number, ' ', ''), '-', ''), '(', ''), ')', ''), '+', ''), '.', '')";
                    $search->orWhereRaw("{$normalizedPhone} LIKE ?", ['%'.$digits.'%']);
                }
            });
        }
        match ($filters['status']) {
            'active' => $query->whereIn('status', ['active', 'pending'])->where(fn (Builder $q) => $q->where('email_verified', 1)->orWhereNotNull('email_verified_at')),
            'email-unverified' => $query->whereIn('status', ['active', 'pending'])->where(fn (Builder $q) => $q->whereNull('email_verified')->orWhere('email_verified', '!=', 1))->whereNull('email_verified_at'),
            'suspended' => $query->whereIn('status', ['suspended', 'banned']),
            'deactivated' => $query->where('status', 'deactivated'),
            default => null,
        };

        return $query;
    }

    private function applySort(Builder $query, string $sort): Builder
    {
        return match ($sort) {
            'oldest' => $query->orderBy('created_at')->orderBy('id'),
            'name' => $query->orderByRaw('LOWER(name) ASC')->orderBy('id'),
            'last_active' => $query->orderByDesc('last_login_at')->orderByDesc('created_at'),
            default => $query->orderByDesc('created_at')->orderByDesc('id'),
        };
    }

    private function duplicateKeys(string $column, string $expression): array
    {
        return User::query()->whereNotNull($column)->where($column, '!=', '')
            ->selectRaw("{$expression} as normalized_value")
            ->groupBy('normalized_value')->havingRaw('COUNT(*) > 1')
            ->pluck('normalized_value')->all();
    }

    private function displayStatus(User $user): string
    {
        if (in_array($user->status, ['suspended', 'banned'], true)) return 'Suspended';
        if ($user->status === 'deactivated') return 'Deactivated';
        if (! $user->email_verified && ! $user->email_verified_at) return 'Email not verified';
        return 'Active';
    }

    private function assertManageable(User $user): void
    {
        abort_if($user->role === 'admin', 403, 'Administrator accounts cannot be changed here.');
        abort_if((int) $user->id === (int) Auth::id(), 403, 'You cannot suspend or deactivate your own account.');
    }

    private function readableReason(string $reason): string
    {
        return ucfirst(str_replace('_', ' ', $reason));
    }

    private function recordStatusChange(User $user, string $status, string $action, ?string $reason, ?string $note, $until): void
    {
        DB::transaction(function () use ($user, $status, $action, $reason, $note, $until) {
            $locked = User::query()->lockForUpdate()->findOrFail($user->id);
            $locked->forceFill(['status' => $status, 'suspended_until' => $status === 'suspended' ? $until : null])->save();
            UserStatusLog::create([
                'user_id' => $locked->id,
                'admin_id' => Auth::id(),
                'action' => $action,
                'reason' => $reason,
                'note' => $note,
                'until' => $until,
                'created_at' => now(),
            ]);
        });
    }

    private function invalidateSessions(User $user): void
    {
        if (config('session.driver') === 'database' && Schema::hasTable(config('session.table', 'sessions'))) {
            DB::table(config('session.table', 'sessions'))->where('user_id', $user->id)->delete();
        }
        if (Schema::hasTable('personal_access_tokens')) {
            DB::table('personal_access_tokens')->where('tokenable_type', $user->getMorphClass())->where('tokenable_id', $user->id)->delete();
        }
    }

    private function redirectSuccess(User $user, string $message)
    {
        return redirect()->route('admin.users', array_merge(request()->query(), ['user' => $user->id]))
            ->with('flash_success', $message);
    }
}
