<?php

namespace App\Http\Controllers\Auth;

use App\Http\Controllers\Controller;
use App\Models\User;
use Illuminate\Auth\Events\Registered;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Hash;
use Illuminate\Validation\Rules;
use Illuminate\View\View;

class RegisteredUserController extends Controller
{
    public function create(): View
    {
        return view('auth.register');
    }

    public function store(Request $request): RedirectResponse
    {
        $request->validate([
            'first_name'      => ['required', 'string', 'max:100'],
            'last_name'       => ['required', 'string', 'max:100'],
            'middle_initial'  => ['nullable', 'string', 'max:4'],
            'sex'             => ['required', 'in:male,female'],
            'contact_number'  => ['required', 'string', 'max:20'],
            'date_of_birth'   => ['required', 'date', 'before:today'],
            'province'        => ['required', 'string', 'max:255'],
            'municipality'    => ['required', 'string', 'max:255'],
            'barangay'        => ['required', 'string', 'max:255'],
            'street'          => ['nullable', 'string', 'max:255'],
            'house_number'    => ['nullable', 'string', 'max:100'],
            'email'           => ['required', 'string', 'email', 'max:255', 'unique:users'],
            'password'        => ['required', 'confirmed', Rules\Password::defaults()],
            'signup_type'     => ['in:buyer,seller'],
            'business_name'   => ['required_if:signup_type,seller', 'nullable', 'string', 'max:255'],
            'category'        => ['required_if:signup_type,seller', 'nullable', 'string', 'max:255'],
            'id_document'     => ['required_if:signup_type,seller', 'nullable', 'file', 'mimes:jpg,jpeg,png,pdf', 'max:5120'],
            'business_permit' => ['required_if:signup_type,seller', 'nullable', 'file', 'mimes:jpg,jpeg,png,pdf', 'max:5120'],
        ]);

        // Never trust the frontend's "Verified" state — check the DB record directly.
        $emailVerified = \DB::table('email_verification_codes')
            ->where('email', $request->email)
            ->where('verified', true)
            ->exists();

        if (! $emailVerified) {
            return back()->withErrors(['email' => 'Please verify your email before signing up.'])->withInput();
        }

        // Compute age server-side from date_of_birth — never trust a client-submitted age value.
        $age = \Carbon\Carbon::parse($request->date_of_birth)->age;

        $signupType = $request->signup_type ?? 'buyer';

        $user = User::create([
            'name'           => $request->first_name . ' ' . $request->last_name,
            'first_name'     => $request->first_name,
            'last_name'      => $request->last_name,
            'middle_initial' => $request->middle_initial,
            'sex'            => $request->sex,
            'contact_number' => $request->contact_number,
            'date_of_birth'  => $request->date_of_birth,
            'age'            => $age,
            'province'       => $request->province,
            'municipality'   => $request->municipality,
            'barangay'       => $request->barangay,
            'street'         => $request->street,
            'house_number'   => $request->house_number,
            'email'          => $request->email,
            'password'       => Hash::make($request->password),
            'role'           => 'buyer',
            'status'         => 'active',
        ]);

        if ($signupType === 'seller') {
            $idDocumentPath = $request->file('id_document')?->store('seller_documents', 'public');
            $businessPermitPath = $request->file('business_permit')?->store('seller_documents', 'public');

            \DB::table('seller_applications')->insert([
                'user_id'         => $user->id,
                'business_name'   => $request->business_name,
                'category'        => $request->category,
                'id_document'     => $idDocumentPath,
                'business_permit' => $businessPermitPath,
                'status'          => 'pending',
                'created_at'      => now(),
                'updated_at'      => now(),
            ]);
            session()->flash('flash_success', 'Account created! Your seller application is pending admin approval.');
        } else {
            session()->flash('flash_success', 'Account created! You can now log in.');
        }

        event(new Registered($user));

        \DB::table('email_verification_codes')->where('email', $request->email)->delete();

        Auth::login($user);

        if ($signupType === 'seller') {
            return redirect()->route('seller.pending');
        }

        return redirect()->route('shop.index');
    }
}