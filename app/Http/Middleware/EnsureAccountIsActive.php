<?php

namespace App\Http\Middleware;

use App\Services\UserAccountStatusService;
use Closure;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Symfony\Component\HttpFoundation\Response;

class EnsureAccountIsActive
{
    public function handle(Request $request, Closure $next): Response
    {
        $user = Auth::guard('web')->user();
        if ($user && in_array($user->status, ['suspended', 'deactivated', 'banned'], true)) {
            $message = app(UserAccountStatusService::class)->loginBlockMessage($user);
            Auth::guard('web')->logout();
            $request->session()->invalidate();
            $request->session()->regenerateToken();

            return redirect()->route('login')->withErrors(['email' => $message]);
        }

        return $next($request);
    }
}
