<?php

namespace App\Http\Controllers;

use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;

class AccountModeController extends Controller
{
    /**
     * Allow a seller to shop using the buyer interface.
     *
     * The database role is not changed. The session only stores the active
     * interface mode for this login session.
     */
    public function switchToBuyer(Request $request): RedirectResponse
    {
        $user = Auth::user();

        if (! $user || $user->role !== 'seller') {
            return redirect()
                ->route('shop.index')
                ->with('error', 'Only seller accounts can switch account modes.');
        }

        $request->session()->put('account_mode', 'buyer');

        return redirect()
            ->route('shop.index')
            ->with('success', 'You are now shopping as a buyer.');
    }

    /**
     * Allow a seller who is currently using buyer mode to return to seller mode.
     *
     * Ordinary buyers are always rejected because their database role is not
     * seller, even if they manually submit this route.
     */
    public function switchToSeller(Request $request): RedirectResponse
    {
        $user = Auth::user();

        if (! $user || $user->role !== 'seller') {
            return redirect()
                ->route('shop.index')
                ->with('error', 'Only seller accounts can access the seller dashboard.');
        }

        $request->session()->put('account_mode', 'seller');

        return redirect()
            ->route('seller.dashboard')
            ->with('success', 'You are now using seller mode.');
    }
}
