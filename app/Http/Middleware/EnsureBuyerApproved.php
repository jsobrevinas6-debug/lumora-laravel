<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

class EnsureBuyerApproved
{
    public function handle(Request $request, Closure $next): Response
    {
        $user = $request->user();

        if ($user && $user->role === 'buyer' && config('marketplace.require_buyer_approval', true)
            && $user->approval_status !== 'approved') {
            $message = $user->approval_status === 'rejected'
                ? 'Your application was not approved. '.($user->approval_rejection_reason ?: 'Please contact support or sign up again with correct details.')
                : "Your account is still awaiting admin approval. We'll email you once it's approved.";
            if ($request->expectsJson() || $request->is('api/*')) {
                $user->currentAccessToken()?->delete();

                return response()->json(['message' => $message], 403);
            }

            auth()->logout();
            $request->session()->invalidate();
            $request->session()->regenerateToken();

            return redirect()->route('login')->withErrors(['email' => $message]);
        }

        return $next($request);
    }
}
