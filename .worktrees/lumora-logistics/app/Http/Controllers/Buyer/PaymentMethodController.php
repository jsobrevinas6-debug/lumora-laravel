<?php

namespace App\Http\Controllers\Buyer;

use App\Http\Controllers\Controller;
use App\Models\PaymentMethod;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\Rule;
use Illuminate\View\View;

class PaymentMethodController extends Controller
{
    private const WALLET_TYPES = ['gcash', 'maya', 'bank_transfer'];

    private const PROVIDER_LABELS = [
        'gcash' => 'GCash',
        'maya' => 'Maya',
        'bank_transfer' => 'Bank Account',
    ];

    public function index(Request $request): View
    {
        $this->authorizeBuyer($request);

        $paymentMethods = $request->user()
            ->paymentMethods()
            ->whereIn('type', self::WALLET_TYPES)
            ->orderByDesc('is_default')
            ->latest()
            ->get();

        return view('buyer.payment-methods.index', compact('paymentMethods'));
    }

    public function store(Request $request): RedirectResponse
    {
        $this->authorizeBuyer($request);

        $type = (string) $request->input('type');
        $identifierLabel = match ($type) {
            'gcash' => 'GCash Number',
            'maya' => 'Maya Number',
            'bank_transfer' => 'Bank Account Number',
            default => 'Wallet Number',
        };

        $identifierRules = ['required', 'string'];

        if (in_array($type, ['gcash', 'maya'], true)) {
            $identifierRules[] = 'max:20';
            $identifierRules[] = 'regex:/^09\d{9}$/';
        } elseif ($type === 'bank_transfer') {
            $identifierRules[] = 'max:50';
            $identifierRules[] = 'regex:/^[0-9\s-]+$/';
        } else {
            $identifierRules[] = 'max:255';
        }

        $validated = $request->validate([
            'type' => ['required', 'string', Rule::in(self::WALLET_TYPES)],
            'account_name' => ['required', 'string', 'max:255'],
            'account_identifier' => $identifierRules,
            'notes' => ['nullable', 'string', 'max:500'],
            'is_default' => ['nullable', 'boolean'],
        ], [
            'account_identifier.regex' => $type === 'bank_transfer'
                ? 'The Bank Account Number may only contain numbers, spaces, and dashes.'
                : "The {$identifierLabel} must use the 09XXXXXXXXX format.",
        ], [
            'account_name' => 'Full Name',
            'account_identifier' => $identifierLabel,
        ]);

        $validated['provider'] = self::PROVIDER_LABELS[$validated['type']];

        $makeDefault = (bool) ($validated['is_default'] ?? false)
            || ! $request->user()->paymentMethods()->whereIn('type', self::WALLET_TYPES)->exists();

        $validated['is_default'] = $makeDefault;

        DB::transaction(function () use ($request, $validated, $makeDefault) {
            if ($makeDefault) {
                $request->user()
                    ->paymentMethods()
                    ->whereIn('type', self::WALLET_TYPES)
                    ->update(['is_default' => false]);
            }

            $request->user()->paymentMethods()->create($validated);
        });

        return redirect()
            ->route('buyer.wallet.index')
            ->with('status', 'wallet-saved');
    }

    public function setDefault(Request $request, PaymentMethod $paymentMethod): RedirectResponse
    {
        $this->authorizeBuyer($request);

        abort_unless((int) $paymentMethod->user_id === (int) $request->user()->id, 403);
        abort_unless(in_array($paymentMethod->type, self::WALLET_TYPES, true), 404);

        DB::transaction(function () use ($request, $paymentMethod) {
            $request->user()
                ->paymentMethods()
                ->whereIn('type', self::WALLET_TYPES)
                ->update(['is_default' => false]);

            $paymentMethod->update(['is_default' => true]);
        });

        return redirect()
            ->route('buyer.wallet.index')
            ->with('status', 'wallet-default');
    }

    public function destroy(Request $request, PaymentMethod $paymentMethod): RedirectResponse
    {
        $this->authorizeBuyer($request);

        abort_unless((int) $paymentMethod->user_id === (int) $request->user()->id, 403);
        abort_unless(in_array($paymentMethod->type, self::WALLET_TYPES, true), 404);

        $wasDefault = $paymentMethod->is_default;
        $paymentMethod->delete();

        if ($wasDefault) {
            $request->user()
                ->paymentMethods()
                ->whereIn('type', self::WALLET_TYPES)
                ->latest()
                ->first()
                ?->update(['is_default' => true]);
        }

        return redirect()
            ->route('buyer.wallet.index')
            ->with('status', 'wallet-removed');
    }

    private function authorizeBuyer(Request $request): void
    {
        $user = $request->user();

        abort_unless(
            $user?->role === 'buyer'
                || ($user?->role === 'seller' && $request->session()->get('account_mode') === 'buyer'),
            403
        );
    }
}
