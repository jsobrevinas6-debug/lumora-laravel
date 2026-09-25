<?php

namespace App\Http\Controllers;

use App\Models\SellerApplication;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Illuminate\View\View;

class SellerApplicationController extends Controller
{
    public function create(Request $request): View|RedirectResponse
    {
        $eligibilityRedirect = $this->guardEligibility($request);

        if ($eligibilityRedirect) {
            return $eligibilityRedirect;
        }

        return view('seller.apply');
    }

    public function store(Request $request): RedirectResponse
    {
        $eligibilityRedirect = $this->guardEligibility($request);

        if ($eligibilityRedirect) {
            return $eligibilityRedirect;
        }

        $validated = $request->validate([
            'business_name' => ['required', 'string', 'max:255'],
            'reason' => ['nullable', 'string', 'max:2000'],
        ]);

        SellerApplication::create([
            'user_id' => $request->user()->id,
            'business_name' => $validated['business_name'],
            'reason' => $validated['reason'] ?? null,
            'status' => 'pending',
        ]);

        return redirect()
            ->route('seller.pending')
            ->with('success', 'Your seller application has been submitted for review.');
    }

    private function guardEligibility(Request $request): ?RedirectResponse
    {
        $user = $request->user();

        if (! $user) {
            return redirect()->route('login');
        }

        if ($user->role === 'seller') {
            return redirect()->route('seller.dashboard');
        }

        if ($user->role !== 'buyer' || $user->provider !== 'google') {
            return redirect()
                ->route('shop.index')
                ->with('error', 'Seller applications from this menu are currently available for Google buyer accounts only.');
        }

        $application = $user->sellerApplication;

        if (! $application) {
            return null;
        }

        if ($application->status === 'pending') {
            return redirect()->route('seller.pending');
        }

        if ($application->status === 'approved') {
            return redirect()
                ->route('shop.index')
                ->with('error', 'Your seller application is approved, but seller access is not active yet.');
        }

        return redirect()
            ->route('shop.index')
            ->with('error', 'Your seller application status is '.str_replace('_', ' ', $application->status).'.');
    }
}
