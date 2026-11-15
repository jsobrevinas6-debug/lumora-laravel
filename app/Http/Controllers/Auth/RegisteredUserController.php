<?php

namespace App\Http\Controllers\Auth;

use App\Http\Controllers\Controller;
use App\Models\User;
use App\Support\SellerApplicationFields;
use Illuminate\Auth\Events\Registered;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Storage;
use Illuminate\View\View;

class RegisteredUserController extends Controller
{
    public function create(Request $request): View
    {
        $request->session()->forget('google_onboarding');

        return view('auth.register', [
            'google' => null,
        ]);
    }

    public function store(Request $request): RedirectResponse
    {
        $request->session()->forget('google_onboarding');

        $signupType = $request->input('signup_type', 'buyer');

        $rules = [
            'first_name' => ['required', 'string', 'min:2', 'max:50', 'not_regex:/\d/', 'regex:/^[A-Za-zñÑ\s]+$/u'],
            'last_name' => ['required', 'string', 'min:2', 'max:50', 'not_regex:/\d/', 'regex:/^[A-Za-zñÑ\s]+$/u'],
            'middle_initial' => ['nullable', 'string', 'max:4', 'not_regex:/\d/', 'regex:/^[A-Za-zñÑ\s]+$/u'],
            'sex' => ['required', 'in:male,female'],
            'contact_number' => ['required', 'string', 'regex:/^\d{1,11}$/'],
            'date_of_birth' => ['required', 'date', 'before_or_equal:' . now()->subYears(18)->toDateString()],
            'province' => ['required', 'string', 'max:255'],
            'municipality' => ['required', 'string', 'max:255'],
            'barangay' => ['required', 'string', 'max:255'],
            'street' => ['nullable', 'string', 'max:255'],
            'house_number' => ['nullable', 'string', 'max:100'],
            'postal_code' => ['nullable', 'string', 'max:4', 'regex:/^\d{1,4}$/'],
            'email' => ['required', 'string', 'email', 'max:255', 'unique:users'],
            'password' => ['required', 'confirmed', 'string', 'min:8', 'regex:/^(?=.*\p{Lu})(?=.*\pN)(?=.*[\p{P}\p{S}]).{8,}$/u'],
            'terms_accepted' => ['accepted'],
            'seller_terms_accepted' => ['accepted_if:signup_type,seller'],
            'marketing_opt_in' => ['sometimes', 'boolean'],
            'signup_type' => ['required', 'in:buyer,seller'],
            ...SellerApplicationFields::registrationRules(),
        ];

        $validated = $request->validate($rules, [
            'first_name.min' => 'First name must be between 2 and 50 characters.',
            'first_name.max' => 'First name must be between 2 and 50 characters.',
            'last_name.min' => 'Last name must be between 2 and 50 characters.',
            'last_name.max' => 'Last name must be between 2 and 50 characters.',
            'first_name.not_regex' => "You can't input a number in your name.",
            'last_name.not_regex' => "You can't input a number in your name.",
            'middle_initial.not_regex' => "You can't input a number in your name.",
            'first_name.regex' => "You can't input special characters in your name (only ñ and Ñ are allowed).",
            'last_name.regex' => "You can't input special characters in your name (only ñ and Ñ are allowed).",
            'middle_initial.regex' => "You can't input special characters in your name (only ñ and Ñ are allowed).",
            'date_of_birth.before_or_equal' => 'You must be at least 18 years old to sign up.',
            'terms_accepted.accepted' => 'Please accept the agreement to create your account.',
            'seller_terms_accepted.accepted_if' => 'Please accept the Seller Agreement to create a seller account.',
            'postal_code.max' => 'Postal code must be a maximum of 4 digits.',
            'postal_code.regex' => 'Postal code must contain numbers only (maximum 4 digits).',
            'contact_number.regex' => 'Contact number must contain digits only and be no more than 11 digits.',
            'password.min' => 'Password must be at least 8 characters long.',
            'password.uppercase' => 'Password must include at least one uppercase letter.',
            'password.numbers' => 'Password must include at least one number.',
            'password.regex' => 'Password must include at least one uppercase letter, one number, and one special character.',
            'id_document.mimes' => 'Valid ID must be a JPG, PNG, or PDF file only.',
            'id_document.max' => 'Valid ID file size must not exceed 5MB.',
            'business_permit.mimes' => 'Business Permit must be a JPG, PNG, or PDF file only.',
            'business_permit.max' => 'Business Permit file size must not exceed 5MB.',
        ]);

        $age = \Carbon\Carbon::parse($validated['date_of_birth'])->age;

        if ($age < 18) {
            return back()->withErrors(['date_of_birth' => 'You must be at least 18 years old to sign up.'])->withInput();
        }

        // Never trust the frontend's "Verified" state; check the DB record directly.
        $emailVerified = DB::table('email_verification_codes')
            ->where('email', $request->email)
            ->where('verified', true)
            ->exists();

        if (! $emailVerified) {
            return back()->withErrors(['email' => 'Please verify your email before signing up.'])->withInput();
        }

        $email = $validated['email'];

        $consentAcceptedAt = now();

        $userAttributes = [
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
            'email_verified' => 1,
            'email_verified_at' => now(),
            'password' => Hash::make($validated['password']),
            'role' => 'buyer',
            'status' => 'active',
            'terms_accepted_at' => $consentAcceptedAt,
            'terms_version' => config('legal.terms_version'),
            'privacy_notice_acknowledged_at' => $consentAcceptedAt,
            'privacy_notice_version' => config('legal.privacy_notice_version'),
            'seller_terms_accepted_at' => $signupType === 'seller' ? now() : null,
            'marketing_opt_in' => $request->boolean('marketing_opt_in'),
            'approval_status' => 'approved',
        ];

        if (\Illuminate\Support\Facades\Schema::hasColumn('users', 'postal_code')) {
            $userAttributes['postal_code'] = $validated['postal_code'] ?? null;
        }

        $user = User::create($userAttributes);

        if ($signupType === 'seller') {
            SellerApplicationFields::createFromRequest($request, $user->id);

            session()->flash('flash_success', 'Account created! Your seller application is pending admin approval.');
        } else {
            session()->flash('flash_success', 'Account created!');
        }

        event(new Registered($user));

        DB::table('email_verification_codes')->where('email', $request->email)->delete();

        Auth::login($user);

        if ($signupType === 'seller') {
            return redirect()->route('seller.pending');
        }

        return redirect()->route('dashboard');
    }
}
