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
    public function index(Request $request): View
    {
        $paymentMethods = $request->user()
            ->paymentMethods()
            ->orderByDesc('is_default')
            ->latest()
            ->get();

        return view('buyer.payment-methods.index', compact('paymentMethods'));
    }

    public function store(Request $request): RedirectResponse
    {
        $validated = $request->validate([
            'type' => ['required', 'string', Rule::in(['cod', 'gcash', 'maya', 'bank_transfer', 'card_reference'])],
            'provider' => ['nullable', 'string', 'max:100'],
            'account_name' => ['nullable', 'string', 'max:255'],
            'account_identifier' => ['nullable', 'string', 'max:255'],
            'last_four' => ['nullable', 'string', 'max:4'],
            'notes' => ['nullable', 'string', 'max:500'],
            'is_default' => ['nullable', 'boolean'],
        ]);

        if ($validated['type'] === 'card_reference') {
            $lastFour = $validated['last_four'] ?? ($validated['account_identifier'] ?? null);

            if ($lastFour !== null && (strlen($lastFour) > 4 || ! preg_match('/^\d{1,4}$/', $lastFour))) {
                return back()
                    ->withErrors(['last_four' => 'Only enter the last 4 digits for a card reference.'])
                    ->withInput();
            }

            $validated['last_four'] = $lastFour;
            $validated['account_identifier'] = null;
        }

        if ($validated['type'] === 'cod' && blank($validated['provider'] ?? null)) {
            $validated['provider'] = 'Cash on Delivery';
        }

        $makeDefault = (bool) ($validated['is_default'] ?? false)
            || ! $request->user()->paymentMethods()->exists();

        $validated['is_default'] = $makeDefault;

        DB::transaction(function () use ($request, $validated, $makeDefault) {
            if ($makeDefault) {
                $request->user()->paymentMethods()->update(['is_default' => false]);
            }

            $request->user()->paymentMethods()->create($validated);
        });

        return redirect()
            ->route('buyer.payment-methods.index')
            ->with('status', 'payment-method-saved');
    }

    public function setDefault(Request $request, PaymentMethod $paymentMethod): RedirectResponse
    {
        abort_unless((int) $paymentMethod->user_id === (int) $request->user()->id, 403);

        DB::transaction(function () use ($request, $paymentMethod) {
            $request->user()->paymentMethods()->update(['is_default' => false]);
            $paymentMethod->update(['is_default' => true]);
        });

        return redirect()
            ->route('buyer.payment-methods.index')
            ->with('status', 'payment-method-default');
    }

    public function destroy(Request $request, PaymentMethod $paymentMethod): RedirectResponse
    {
        abort_unless((int) $paymentMethod->user_id === (int) $request->user()->id, 403);

        $wasDefault = $paymentMethod->is_default;
        $paymentMethod->delete();

        if ($wasDefault) {
            $request->user()
                ->paymentMethods()
                ->latest()
                ->first()
                ?->update(['is_default' => true]);
        }

        return redirect()
            ->route('buyer.payment-methods.index')
            ->with('status', 'payment-method-removed');
    }
}
