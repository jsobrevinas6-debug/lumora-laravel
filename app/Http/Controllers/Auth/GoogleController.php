<?php

namespace App\Http\Controllers\Auth;

use App\Http\Controllers\Controller;
use App\Models\User;
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
            Auth::login($user, true);
            $request->session()->regenerate();

            return redirect()->intended(route('shop.index'));
        }

        // A verified Google email can be linked to an existing Lumora account.
        $existingUser = User::where('email', $email)->first();

        if ($existingUser) {
            $existingUser->google_id = $googleId;
            $existingUser->email_verified_at ??= now();
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
            'email_verified' => true,
        ]);

        return redirect()->route('google.complete');
    }

    public function showCompletion(Request $request)
    {
        $google = $request->session()->get('google_onboarding');

        if (!$google) {
            return redirect()
                ->route('login')
                ->withErrors(['email' => 'Please start Google sign-in again.']);
        }

        return view('auth.google-complete', compact('google'));
    }

    public function complete(Request $request)
    {
        $google = $request->session()->get('google_onboarding');

        if (!$google) {
            return redirect()
                ->route('login')
                ->withErrors(['email' => 'Your Google sign-in session expired. Please try again.']);
        }

        $validated = $request->validate([
            'first_name' => ['required', 'string', 'max:255'],
            'last_name' => ['required', 'string', 'max:255'],
            'middle_initial' => ['nullable', 'string', 'max:4'],
            'sex' => ['required', 'in:male,female'],
            'contact_number' => ['required', 'string', 'max:30'],
            'date_of_birth' => ['required', 'date', 'before:today'],
            'province' => ['required', 'string', 'max:255'],
            'municipality' => ['required', 'string', 'max:255'],
            'barangay' => ['required', 'string', 'max:255'],
            'street' => ['nullable', 'string', 'max:255'],
            'house_number' => ['nullable', 'string', 'max:100'],
        ]);

        $user = new User();
        $user->name = trim($validated['first_name'] . ' ' . ($validated['middle_initial'] ? $validated['middle_initial'] . ' ' : '') . $validated['last_name']);
        $user->first_name = $validated['first_name'];
        $user->last_name = $validated['last_name'];
        $user->middle_initial = $validated['middle_initial'] ?? null;
        $user->sex = $validated['sex'];
        $user->contact_number = $validated['contact_number'];
        $user->date_of_birth = $validated['date_of_birth'];
        $user->province = $validated['province'];
        $user->municipality = $validated['municipality'];
        $user->barangay = $validated['barangay'];
        $user->street = $validated['street'] ?? null;
        $user->house_number = $validated['house_number'] ?? null;
        $user->email = $google['email'];
        $user->google_id = $google['google_id'];
        $user->email_verified_at = now();
        $user->email_verified = 1;
        $user->role = 'buyer';
        $user->status = 'active';
        $user->password = Hash::make(Str::random(48));
        $user->save();

        $request->session()->forget('google_onboarding');
        Auth::login($user, true);
        $request->session()->regenerate();

        return redirect()
            ->intended(route('shop.index'))
            ->with('success', 'Welcome to Lumora. Your account is ready.');
    }
}
