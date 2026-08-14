<?php

namespace App\Http\Controllers\Seller;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Hash;
use Illuminate\Validation\Rule;

class ProfileController extends Controller
{
    public function index()
    {
        $user = Auth::user();
        return view('seller.profile', compact('user'));
    }

    public function update(Request $request)
    {
        $user = Auth::user();

        $validated = $request->validate([
            'first_name'        => ['required', 'string', 'max:255'],
            'last_name'         => ['required', 'string', 'max:255'],
            'contact_number'    => ['required', 'string', 'max:20'],
            'email'             => ['required', 'email', 'max:255', Rule::unique('users', 'email')->ignore($user->id)],
            'shop_name'         => ['nullable', 'string', 'max:255'],
            'shop_description'  => ['nullable', 'string', 'max:2000'],
        ]);

        $emailChanged = $validated['email'] !== $user->email;

        $user->first_name = $validated['first_name'];
        $user->last_name = $validated['last_name'];
        $user->name = trim($validated['first_name'] . ' ' . $validated['last_name']);
        $user->contact_number = $validated['contact_number'];
        $user->shop_name = $validated['shop_name'] ?? null;
        $user->shop_description = $validated['shop_description'] ?? null;

        if ($emailChanged) {
            $user->email = $validated['email'];
            $user->email_verified = 0;
            $user->email_verified_at = null;
        }

        $user->save();

        if ($emailChanged) {
            return back()->with('success', 'Profile updated. Your new email is unverified.');
        }

        return back()->with('success', 'Profile updated.');
    }

    public function updatePassword(Request $request)
    {
        $request->validate([
            'current_password' => ['required', 'current_password'],
            'password'          => ['required', 'confirmed', 'min:8'],
        ]);

        $user = Auth::user();
        $user->password = Hash::make($request->password);
        $user->save();

        return back()->with('success', 'Password updated.');
    }
}