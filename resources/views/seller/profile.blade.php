@extends('layouts.seller')

@section('title', 'Profile / Settings')

@section('content')
    @if (session('success'))
        <div class="alert-success">{{ session('success') }}</div>
    @endif

    @if ($errors->any())
        <div class="alert-error">
            <ul style="margin:0; padding-left:18px;">
                @foreach ($errors->all() as $error)
                    <li>{{ $error }}</li>
                @endforeach
            </ul>
        </div>
    @endif

    {{-- Basic Info --}}
    <div class="panel" style="margin-bottom:22px;">
        <h2>Basic Information</h2>
        <form action="{{ route('seller.profile.update') }}" method="POST" class="modal-form" style="max-width:520px;">
            @csrf
            @method('PATCH')

            <label style="font-size:13px; font-weight:600; color:var(--text-muted);">First Name</label>
            <input type="text" name="first_name" value="{{ old('first_name', $user->first_name) }}" required>

            <label style="font-size:13px; font-weight:600; color:var(--text-muted);">Last Name</label>
            <input type="text" name="last_name" value="{{ old('last_name', $user->last_name) }}" required>

            <label style="font-size:13px; font-weight:600; color:var(--text-muted);">Contact Number</label>
            <input type="text" name="contact_number" value="{{ old('contact_number', $user->contact_number) }}" required>

            <label style="font-size:13px; font-weight:600; color:var(--text-muted);">Email</label>
            <input type="email" name="email" value="{{ old('email', $user->email) }}" required>
            <div style="font-size:12.5px; color:var(--text-muted);">
                @if ($user->email_verified_at)
                    <span style="color:var(--sage-2);">✓ Verified</span>
                @else
                    <span style="color:var(--coral);">Not verified</span>
                @endif
                &nbsp;&mdash;&nbsp;changing your email will mark it as unverified again.
            </div>

            <hr style="border:none; border-top:1px solid var(--border); margin:6px 0;">

            <label style="font-size:13px; font-weight:600; color:var(--text-muted);">Shop / Store Name</label>
            <input type="text" name="shop_name" value="{{ old('shop_name', $user->shop_name) }}" placeholder="e.g. Skincare Products PH">

            <label style="font-size:13px; font-weight:600; color:var(--text-muted);">Shop Description</label>
            <textarea name="shop_description" rows="4" placeholder="Tell buyers about your shop">{{ old('shop_description', $user->shop_description) }}</textarea>

            <button type="submit" class="btn-solid" style="align-self:flex-start; margin-top:6px;">Save Changes</button>
        </form>
    </div>

    {{-- Password --}}
    <div class="panel">
        <h2>Change Password</h2>
        <form action="{{ route('seller.profile.updatePassword') }}" method="POST" class="modal-form" style="max-width:420px;">
            @csrf
            @method('PATCH')

            <label style="font-size:13px; font-weight:600; color:var(--text-muted);">Current Password</label>
            <input type="password" name="current_password" required>

            <label style="font-size:13px; font-weight:600; color:var(--text-muted);">New Password</label>
            <input type="password" name="password" required>

            <label style="font-size:13px; font-weight:600; color:var(--text-muted);">Confirm New Password</label>
            <input type="password" name="password_confirmation" required>

            <button type="submit" class="btn-solid" style="align-self:flex-start; margin-top:6px;">Update Password</button>
        </form>
    </div>
@endsection