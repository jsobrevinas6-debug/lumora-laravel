<?php

namespace App\Http\Controllers\Auth;

use App\Http\Controllers\Controller;
use App\Models\User;
use Illuminate\Auth\Events\Registered;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Str;
use Laravel\Socialite\Facades\Socialite;
use Throwable;

class GoogleController extends Controller
{
    public function redirect()
    {
        $clientId = config('services.google.client_id');
        $clientSecret = config('services.google.client_secret');
        $redirectUri = config('services.google.redirect');

        if (blank($clientId) || blank($clientSecret) || blank($redirectUri)) {
            Log::warning('Google sign-in is not configured.', [
                'client_id_configured' => filled($clientId),
                'client_secret_configured' => filled($clientSecret),
                'redirect_uri_configured' => filled($redirectUri),
            ]);

            return redirect()
                ->route('login')
                ->withErrors(['email' => 'Google sign-in is not configured yet. Please try again later.']);
        }

        return Socialite::driver('google')
            ->redirectUrl($redirectUri)
            ->redirect();
    }

    public function callback(Request $request)
    {
        try {
            $googleUser = Socialite::driver('google')
                ->redirectUrl(config('services.google.redirect'))
                ->user();
        } catch (Throwable $exception) {
            Log::warning('Google sign-in failed.', [
                'message' => $exception->getMessage(),
            ]);

            return redirect()
                ->route('login')
                ->withErrors(['email' => 'Google sign-in could not be completed. Please try again.']);
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

        $user = User::where('google_id', $googleId)
            ->orWhere('email', $email)
            ->first();

        if ($user) {
            if (filled($user->google_id) && $user->google_id !== $googleId) {
                Log::warning('Google sign-in email matched a user already linked to a different Google account.', [
                    'user_id' => $user->id,
                ]);

                return redirect()
                    ->route('login')
                    ->withErrors(['email' => 'This email is already linked to another Google account.']);
            }

            $user->google_id ??= $googleId;
            $user->provider ??= 'google';
            $user->avatar ??= $googleUser->getAvatar();
            $user->email_verified_at ??= now();
            $user->email_verified = 1;
            $user->save();

            Auth::login($user, true);
            $request->session()->regenerate();

            return redirect()->intended(route('shop.index'));
        }

        $fullName = trim((string) ($googleUser->getName() ?: $googleUser->getNickname() ?: 'Lumora Buyer'));
        $nameParts = preg_split('/\s+/', $fullName, 2);

        $user = User::create([
            'name' => $fullName,
            'first_name' => $nameParts[0] ?? null,
            'last_name' => $nameParts[1] ?? null,
            'email' => $email,
            'google_id' => $googleId,
            'avatar' => $googleUser->getAvatar(),
            'provider' => 'google',
            'email_verified' => 1,
            'email_verified_at' => now(),
            'password' => Hash::make(Str::random(40)),
            'role' => 'buyer',
            'status' => 'active',
        ]);

        event(new Registered($user));

        Auth::login($user, true);
        $request->session()->regenerate();

        return redirect()->intended(route('shop.index'));
    }
}
