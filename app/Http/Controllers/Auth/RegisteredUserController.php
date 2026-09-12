<?php

namespace App\Http\Controllers\Auth;

use App\Http\Controllers\Controller;
use App\Models\User;
use Illuminate\Auth\Events\Registered;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Str;
use Illuminate\Validation\Rules;
use Illuminate\View\View;

class RegisteredUserController extends Controller
{
    public function create(Request $request): View
    {
        return view('auth.register', [
            'google' => $request->session()->get('google_onboarding'),
        ]);
    }

    public function store(Request $request): RedirectResponse
    {
        $google = $request->session()->get('google_onboarding');
        $isGoogleSignup = is_array($google);

        $rules = [
            'first_name' => ['required', 'string', 'max:100'],
            'last_name' => ['required', 'string', 'max:100'],
            'middle_initial' => ['nullable', 'string', 'max:4'],
            'sex' => ['required', 'in:male,female'],
            'contact_number' => ['required', 'string', 'max:20'],
            'date_of_birth' => ['required', 'date', 'before:today'],
            'province' => ['required', 'string', 'max:255'],
            'municipality' => ['required', 'string', 'max:255'],
            'barangay' => ['required', 'string', 'max:255'],
            'street' => ['nullable', 'string', 'max:255'],
            'house_number' => ['nullable', 'string', 'max:100'],
        ];

        if ($isGoogleSignup) {
            $rules['email'] = ['nullable', 'string', 'email'];
            $rules['password'] = ['exclude'];
            $rules['signup_type'] = ['in:buyer,seller'];
            $rules['business_name'] = ['required_if:signup_type,seller', 'nullable', 'string', 'max:255'];
            $rules['category'] = ['required_if:signup_type,seller', 'nullable', 'string', 'max:255'];
            $rules['id_document'] = ['required_if:signup_type,seller', 'nullable', 'file', 'mimes:jpg,jpeg,png,pdf', 'max:5120'];
            $rules['business_permit'] = ['required_if:signup_type,seller', 'nullable', 'file', 'mimes:jpg,jpeg,png,pdf', 'max:5120'];
        } else {
            $rules['email'] = ['required', 'string', 'email', 'max:255', 'unique:users'];
            $rules['password'] = ['required', 'confirmed', Rules\Password::defaults()];
            $rules['signup_type'] = ['in:buyer,seller'];
            $rules['business_name'] = ['required_if:signup_type,seller', 'nullable', 'string', 'max:255'];
            $rules['category'] = ['required_if:signup_type,seller', 'nullable', 'string', 'max:255'];
            $rules['id_document'] = ['required_if:signup_type,seller', 'nullable', 'file', 'mimes:jpg,jpeg,png,pdf', 'max:5120'];
            $rules['business_permit'] = ['required_if:signup_type,seller', 'nullable', 'file', 'mimes:jpg,jpeg,png,pdf', 'max:5120'];
        }

        $validated = $request->validate($rules);

        if ($isGoogleSignup) {
            $email = strtolower(trim((string) ($google['email'] ?? '')));
            $googleId = trim((string) ($google['google_id'] ?? ''));

            if ($email === '' || $googleId === '') {
                return redirect()
                    ->route('login')
                    ->withErrors(['email' => 'Your Google sign-up session expired. Please try again.']);
            }

            $existingUser = User::where('email', $email)
                ->orWhere('google_id', $googleId)
                ->first();

            if ($existingUser) {
                $existingUser->google_id ??= $googleId;
                $existingUser->provider ??= 'google';
                $existingUser->avatar ??= $google['avatar'] ?? null;
                $existingUser->email_verified_at ??= now();
                $existingUser->email_verified = 1;
                $existingUser->save();

                $request->session()->forget('google_onboarding');
                Auth::login($existingUser, true);
                $request->session()->regenerate();

                return redirect()->intended(route('shop.index'));
            }
        } else {
            // Never trust the frontend's "Verified" state; check the DB record directly.
            $emailVerified = DB::table('email_verification_codes')
                ->where('email', $request->email)
                ->where('verified', true)
                ->exists();

            if (! $emailVerified) {
                return back()->withErrors(['email' => 'Please verify your email before signing up.'])->withInput();
            }
        }

        $age = \Carbon\Carbon::parse($validated['date_of_birth'])->age;
        $signupType = $request->signup_type ?? 'buyer';
        $email = $isGoogleSignup ? strtolower(trim((string) $google['email'])) : $validated['email'];

        $user = User::create([
            'name' => trim($validated['first_name'] . ' ' . $validated['last_name']),
            'first_name' => $validated['first_name'],
            'last_name' => $validated['last_name'],
            'middle_initial' => $validated['middle_initial'] ?? null,
            'sex' => $validated['sex'],
            'contact_number' => $validated['contact_number'],
            'date_of_birth' => $validated['date_of_birth'],
            'age' => $age,
            'province' => $validated['province'],
            'municipality' => $validated['municipality'],
            'barangay' => $validated['barangay'],
            'street' => $validated['street'] ?? null,
            'house_number' => $validated['house_number'] ?? null,
            'email' => $email,
            'google_id' => $isGoogleSignup ? $google['google_id'] : null,
            'avatar' => $isGoogleSignup ? ($google['avatar'] ?? null) : null,
            'provider' => $isGoogleSignup ? 'google' : null,
            'email_verified' => $isGoogleSignup ? 1 : 0,
            'email_verified_at' => $isGoogleSignup ? now() : null,
            'password' => Hash::make($isGoogleSignup ? Str::random(48) : $validated['password']),
            'role' => 'buyer',
            'status' => 'active',
        ]);

        if ($signupType === 'seller') {
            $idDocumentPath = $request->file('id_document')?->store('seller_documents', 'public');
            $businessPermitPath = $request->file('business_permit')?->store('seller_documents', 'public');

            DB::table('seller_applications')->insert([
                'user_id' => $user->id,
                'business_name' => $request->business_name,
                'category' => $request->category,
                'id_document' => $idDocumentPath,
                'business_permit' => $businessPermitPath,
                'status' => 'pending',
                'created_at' => now(),
                'updated_at' => now(),
            ]);

            session()->flash('flash_success', 'Account created! Your seller application is pending admin approval.');
        } else {
            session()->flash('flash_success', $isGoogleSignup ? 'Google sign-up complete. Welcome to Lumora.' : 'Account created! You can now log in.');
        }

        event(new Registered($user));

        if ($isGoogleSignup) {
            $request->session()->forget('google_onboarding');
        } else {
            DB::table('email_verification_codes')->where('email', $request->email)->delete();
        }

        Auth::login($user);

        if ($signupType === 'seller') {
            return redirect()->route('seller.pending');
        }

        return redirect()->route('shop.index');
    }
}
