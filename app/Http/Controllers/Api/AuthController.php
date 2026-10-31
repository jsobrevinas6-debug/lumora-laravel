<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Mail\VerificationCodeMail;
use App\Models\User;
use Carbon\Carbon;
use Illuminate\Auth\Events\Registered;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Mail;
use Illuminate\Support\Facades\RateLimiter;
use Illuminate\Support\Facades\Schema;
use Illuminate\Validation\Rule;

/**
 * Token-based authentication for the Lumora mobile app (Laravel Sanctum).
 */
class AuthController extends Controller
{
    /** Account statuses that are not allowed to sign in from the mobile app. */
    private const BLOCKED_STATUSES = ['banned', 'suspended', 'blocked', 'deactivated', 'inactive'];

    public function login(Request $request): JsonResponse
    {
        $credentials = $request->validate([
            'email' => ['required', 'string', 'email'],
            'password' => ['required', 'string'],
            'device_name' => ['nullable', 'string', 'max:100'],
        ]);

        $email = strtolower(trim($credentials['email']));
        $throttleKey = 'api-login|'.$email.'|'.$request->ip();

        if (RateLimiter::tooManyAttempts($throttleKey, 5)) {
            $seconds = RateLimiter::availableIn($throttleKey);

            return response()->json([
                'message' => "Too many login attempts. Please try again in {$seconds} seconds.",
            ], 429);
        }

        $user = User::where('email', $email)->first();

        if (! $user || blank($user->password) || ! Hash::check($credentials['password'], $user->password)) {
            RateLimiter::hit($throttleKey);

            return response()->json(['message' => trans('auth.failed')], 401);
        }

        RateLimiter::clear($throttleKey);

        if (in_array(strtolower((string) $user->status), self::BLOCKED_STATUSES, true)) {
            return response()->json([
                'message' => 'Your account is not active. Please contact Lumora support.',
            ], 403);
        }

        $token = $user->createToken($credentials['device_name'] ?? 'lumora-mobile')->plainTextToken;

        return response()->json([
            'message' => 'Logged in successfully.',
            'token' => $token,
            'token_type' => 'Bearer',
            'user' => self::userPayload($user),
        ]);
    }

    public function register(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'full_name' => ['nullable', 'string', 'max:120'],
            'first_name' => ['nullable', 'string', 'min:2', 'max:50'],
            'last_name' => ['nullable', 'string', 'min:2', 'max:50'],
            'middle_initial' => ['nullable', 'string', 'max:4'],
            'sex' => ['nullable', 'in:male,female'],
            'contact_number' => ['nullable', 'string', 'max:20'],
            'date_of_birth' => ['nullable', 'date'],
            'province' => ['nullable', 'string', 'max:255'],
            'municipality' => ['nullable', 'string', 'max:255'],
            'barangay' => ['nullable', 'string', 'max:255'],
            'street' => ['nullable', 'string', 'max:255'],
            'house_number' => ['nullable', 'string', 'max:100'],
            'postal_code' => ['nullable', 'string', 'max:10'],
            'email' => ['required', 'string', 'email', 'max:255', Rule::unique('users', 'email')],
            'password' => ['required', 'string', 'min:8'],
            'device_name' => ['nullable', 'string', 'max:100'],
        ]);

        $email = strtolower(trim($validated['email']));
        $fullName = trim((string) ($validated['full_name'] ?? ''));
        $firstName = trim((string) ($validated['first_name'] ?? ''));
        $lastName = trim((string) ($validated['last_name'] ?? ''));

        if ($firstName === '' && $fullName !== '') {
            $parts = preg_split('/\s+/', $fullName, 2) ?: [];
            $firstName = $parts[0] ?? $fullName;
            $lastName = $parts[1] ?? '';
        }

        if ($fullName === '') {
            $fullName = trim($firstName.' '.$lastName) ?: explode('@', $email)[0];
        }

        $age = null;
        if (! empty($validated['date_of_birth'])) {
            $age = Carbon::parse($validated['date_of_birth'])->age;
            if ($age < 18) {
                return response()->json(['message' => 'You must be at least 18 years old to sign up.'], 422);
            }
        }

        $emailVerified = false;
        if (Schema::hasTable('email_verification_codes')) {
            $emailVerified = DB::table('email_verification_codes')
                ->where('email', $email)
                ->where('verified', true)
                ->exists();
        }

        $userAttributes = [
            'name' => $fullName,
            'first_name' => $firstName ?: $fullName,
            'last_name' => $lastName ?: null,
            'middle_initial' => $validated['middle_initial'] ?? null,
            'sex' => $validated['sex'] ?? null,
            'contact_number' => $validated['contact_number'] ?? null,
            'date_of_birth' => $validated['date_of_birth'] ?? null,
            'age' => $age,
            'province' => $validated['province'] ?? null,
            'municipality' => $validated['municipality'] ?? null,
            'barangay' => $validated['barangay'] ?? null,
            'street' => $validated['street'] ?? null,
            'house_number' => $validated['house_number'] ?? null,
            'email' => $email,
            'email_verified' => $emailVerified ? 1 : 0,
            'email_verified_at' => $emailVerified ? now() : null,
            'password' => Hash::make($validated['password']),
            'role' => 'buyer',
            'status' => 'active',
        ];

        if (Schema::hasColumn('users', 'postal_code')) {
            $userAttributes['postal_code'] = $validated['postal_code'] ?? null;
        }

        $user = User::create($userAttributes);

        if (Schema::hasTable('email_verification_codes')) {
            DB::table('email_verification_codes')->where('email', $email)->delete();
        }

        event(new Registered($user));

        $token = $user->createToken($validated['device_name'] ?? 'lumora-mobile')->plainTextToken;

        return response()->json([
            'message' => 'Account created successfully.',
            'token' => $token,
            'token_type' => 'Bearer',
            'user' => self::userPayload($user),
        ], 201);
    }

    public function sendOtp(Request $request): JsonResponse
    {
        $email = strtolower(trim((string) ($request->input('email') ?: $request->input('target'))));

        if (! filter_var($email, FILTER_VALIDATE_EMAIL)) {
            return response()->json(['message' => 'Please enter a valid email address.'], 422);
        }

        $type = strtolower((string) $request->input('type', 'signup'));

        if ($type === 'signup' && User::where('email', $email)->exists()) {
            return response()->json(['message' => 'This email is already registered.'], 422);
        }

        $code = (string) random_int(100000, 999999);

        DB::table('email_verification_codes')->where('email', $email)->delete();
        DB::table('email_verification_codes')->insert([
            'email' => $email,
            'code' => $code,
            'verified' => false,
            'expires_at' => now()->addMinutes(10),
            'created_at' => now(),
            'updated_at' => now(),
        ]);

        try {
            Mail::mailer('smtp')->to($email)->send(new VerificationCodeMail($code));
        } catch (\Throwable) {
            try {
                Mail::mailer('gmail_ssl')->to($email)->send(new VerificationCodeMail($code));
            } catch (\Throwable $e) {
                return response()->json([
                    'message' => 'Unable to send verification email right now ('.$e->getMessage().').',
                ], 500);
            }
        }

        return response()->json(['message' => 'Verification code sent.']);
    }

    public function verifyOtp(Request $request): JsonResponse
    {
        $email = strtolower(trim((string) ($request->input('email') ?: $request->input('target'))));
        $code = trim((string) $request->input('code'));

        $record = DB::table('email_verification_codes')
            ->where('email', $email)
            ->where('code', $code)
            ->first();

        if (! $record) {
            return response()->json(['message' => 'Incorrect code.'], 422);
        }

        if (now()->greaterThan($record->expires_at)) {
            return response()->json(['message' => 'This code has expired. Please request a new one.'], 422);
        }

        DB::table('email_verification_codes')
            ->where('email', $email)
            ->update(['verified' => true, 'updated_at' => now()]);

        return response()->json(['message' => 'Email verified.']);
    }

    public function me(Request $request): JsonResponse
    {
        return response()->json(['user' => self::userPayload($request->user())]);
    }

    public function logout(Request $request): JsonResponse
    {
        $request->user()->currentAccessToken()?->delete();

        return response()->json(['message' => 'Logged out successfully.']);
    }

    public static function userPayload(User $user): array
    {
        return [
            'id' => $user->id,
            'name' => $user->name,
            'first_name' => $user->first_name,
            'last_name' => $user->last_name,
            'middle_initial' => $user->middle_initial,
            'sex' => $user->sex,
            'contact_number' => $user->contact_number,
            'date_of_birth' => $user->date_of_birth?->toDateString(),
            'age' => $user->age !== null ? (int) $user->age : null,
            'province' => $user->province,
            'municipality' => $user->municipality,
            'barangay' => $user->barangay,
            'street' => $user->street,
            'house_number' => $user->house_number,
            'postal_code' => $user->postal_code,
            'email' => $user->email,
            'role' => $user->role ?? 'buyer',
            'status' => $user->status ?? 'active',
            'provider' => $user->provider,
            'avatar' => $user->avatar,
            'shop_name' => $user->shop_name,
            'email_verified' => (bool) ($user->email_verified || $user->email_verified_at),
            'email_verified_at' => $user->email_verified_at?->toIso8601String(),
            'created_at' => $user->created_at?->toIso8601String(),
        ];
    }
}
