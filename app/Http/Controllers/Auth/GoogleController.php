<?php

namespace App\Http\Controllers\Auth;

use App\Http\Controllers\Controller;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Log;
use Laravel\Socialite\Facades\Socialite;
use Throwable;

class GoogleController extends Controller
{
    public function redirect()
    {
        return Socialite::driver('google')->redirect();
    }

    public function callback(Request $request)
    {
        try {
            $googleUser = Socialite::driver('google')->user();
        } catch (Throwable $exception) {
            Log::warning('Google sign-in failed.', [
                'message' => $exception->getMessage(),
            ]);

            return redirect()
                ->route('login')
                ->withErrors(['email' => 'Google sign-in was cancelled or could not be completed.']);
        }

        $googleId = (string) $googleUser->getId();
        $email = strtolower(trim((string) $googleUser->getEmail()));
        $providerData = is_array($googleUser->user ?? null) ? $googleUser->user : [];
        $emailVerified = array_key_exists('email_verified', $providerData)
            ? (bool) $providerData['email_verified']
            : true;

        if ($googleId === '' || $email === '' || !$emailVerified) {
            return redirect()
                ->route('login')
                ->withErrors(['email' => 'Google did not provide a verified email for this account.']);
        }

        // Returning Google users can sign in immediately.
        $user = User::where('google_id', $googleId)->first();

        if ($user) {
            $user->provider ??= 'google';
            $user->avatar = $googleUser->getAvatar() ?: $user->avatar;
            $user->email_verified_at ??= now();
            $user->email_verified = 1;
            $user->save();

            Auth::login($user, true);
            $request->session()->regenerate();

            return redirect()->intended(route('shop.index'));
        }

        // A verified Google email can be linked to an existing Lumora account.
        $existingUser = User::where('email', $email)->first();

        if ($existingUser) {
            $existingUser->google_id = $googleId;
            $existingUser->provider ??= 'google';
            $existingUser->avatar = $googleUser->getAvatar() ?: $existingUser->avatar;
            $existingUser->email_verified_at ??= now();
            $existingUser->email_verified = 1;
            $existingUser->save();

            Auth::login($existingUser, true);
            $request->session()->regenerate();

            return redirect()->intended(route('shop.index'));
        }

        $fullName = trim((string) ($googleUser->getName() ?: $googleUser->getNickname() ?: 'Lumora Buyer'));
        $nameParts = preg_split('/\s+/', $fullName, 2);

        $request->session()->put('google_onboarding', [
            'google_id' => $googleId,
            'email' => $email,
            'first_name' => $nameParts[0] ?? '',
            'last_name' => $nameParts[1] ?? '',
            'avatar' => $googleUser->getAvatar(),
            'name' => $fullName,
            'provider' => 'google',
            'email_verified' => true,
            'email_verified_at' => now(),
        ]);

        return redirect()
            ->route('register')
            ->with('google_connected', true);
    }
}
