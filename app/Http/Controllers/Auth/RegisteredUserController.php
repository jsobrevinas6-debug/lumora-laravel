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
            'first_name'     => ['required', 'string', 'max:100'],
            'last_name'      => ['required', 'string', 'max:100'],
            'contact_number' => ['required', 'string', 'max:20'],
            'date_of_birth'  => ['required', 'date'],
            'email'          => ['required', 'string', 'email', 'max:255', 'unique:users'],
            'password'       => ['required', 'confirmed', Rules\Password::defaults()],
            'signup_type'    => ['in:buyer,seller'],
            'business_name'  => ['required_if:signup_type,seller', 'nullable', 'string', 'max:255'],
        ]);

        $signupType = $request->signup_type ?? 'buyer';

        $user = User::create([
            'name'           => $request->first_name . ' ' . $request->last_name,
            'first_name'     => $request->first_name,
            'last_name'      => $request->last_name,
            'contact_number' => $request->contact_number,
            'date_of_birth'  => $request->date_of_birth,
            'email'          => $request->email,
            'password'       => Hash::make($request->password),
            'role'           => 'buyer',
            'status'         => 'active',
        ]);

        if ($signupType === 'seller') {
            \DB::table('seller_applications')->insert([
                'user_id'       => $user->id,
                'business_name' => $request->business_name,
                'status'        => 'pending',
                'created_at'    => now(),
                'updated_at'    => now(),
            ]);
            session()->flash('flash_success', 'Account created! Your seller application is pending admin approval.');
        } else {
            session()->flash('flash_success', 'Account created! You can now log in.');
        }

        event(new Registered($user));

        Auth::login($user);

        return redirect()->route('shop.index');
    }
}
