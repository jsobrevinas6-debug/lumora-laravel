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
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Str;
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
            'approval_status' => 'approved',
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

        if (in_array($type, ['email_change', 'profile_email'], true) && User::where('email', $email)->exists()) {
            return response()->json(['message' => 'That email address is already linked to another account.'], 422);
        }

        if (in_array($type, ['reset', 'password_reset', 'phone_change'], true) && ! User::where('email', $email)->exists()) {
            return response()->json(['message' => 'No Lumora account matches that email address.'], 422);
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

    public function resetPassword(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'email' => ['required', 'string', 'email'],
            'code' => ['required', 'string', 'size:6'],
            'password' => ['required', 'string', 'min:8'],
        ]);

        $email = strtolower(trim($validated['email']));
        $code = trim($validated['code']);

        $user = User::where('email', $email)->first();
        if (! $user) {
            return response()->json(['message' => 'Account not found.'], 404);
        }

        if (Schema::hasTable('email_verification_codes')) {
            $record = DB::table('email_verification_codes')
                ->where('email', $email)
                ->where('code', $code)
                ->first();

            if (! $record) {
                return response()->json(['message' => 'Incorrect or expired verification code.'], 422);
            }

            if (now()->greaterThan($record->expires_at)) {
                return response()->json(['message' => 'This code has expired. Please request a new one.'], 422);
            }

            DB::table('email_verification_codes')->where('email', $email)->delete();
        }

        $user->password = Hash::make($validated['password']);
        $user->save();

        // Invalidate existing tokens after password reset.
        $user->tokens()->delete();

        return response()->json(['message' => 'Password reset successfully.']);
    }

    public function updateProfile(Request $request): JsonResponse
    {
        $user = $request->user();

        $validated = $request->validate([
            'full_name' => ['nullable', 'string', 'max:255'],
            'name' => ['nullable', 'string', 'max:255'],
            'first_name' => ['nullable', 'string', 'max:100'],
            'last_name' => ['nullable', 'string', 'max:100'],
            'middle_initial' => ['nullable', 'string', 'max:10'],
            'sex' => ['nullable', 'string', 'max:30'],
            'contact_number' => ['nullable', 'string', 'max:30'],
            'date_of_birth' => ['nullable', 'date'],
            'province' => ['nullable', 'string', 'max:150'],
            'municipality' => ['nullable', 'string', 'max:150'],
            'barangay' => ['nullable', 'string', 'max:150'],
            'street' => ['nullable', 'string', 'max:255'],
            'house_number' => ['nullable', 'string', 'max:100'],
            'postal_code' => ['nullable', 'string', 'max:20'],
            'email' => ['nullable', 'string', 'email', 'max:255', Rule::unique('users', 'email')->ignore($user->id)],
            'otp_code' => ['nullable', 'string', 'size:6'],
        ]);

        if (! empty($validated['date_of_birth'])) {
            try {
                $dob = Carbon::parse($validated['date_of_birth']);
            } catch (\Throwable) {
                return response()->json(['message' => 'Please enter a valid date of birth (YYYY-MM-DD).'], 422);
            }

            if ($dob->isFuture()) {
                return response()->json(['message' => 'Date of birth cannot be in the future.'], 422);
            }

            $age = $dob->age;
            if ($age < 18) {
                return response()->json(['message' => 'Buyers must be at least 18 years old.'], 422);
            }

            $user->date_of_birth = $dob->toDateString();
            $user->age = $age;
        }

        $emailChanged = false;
        if (array_key_exists('email', $validated) && ! empty($validated['email'])) {
            $newEmail = strtolower(trim($validated['email']));
            if (strcasecmp($newEmail, (string) $user->email) !== 0) {
                $otpVerified = false;
                if (Schema::hasTable('email_verification_codes')) {
                    $query = DB::table('email_verification_codes')->where('email', $newEmail);
                    if (! empty($validated['otp_code'])) {
                        $record = (clone $query)->where('code', trim($validated['otp_code']))->first();
                        $otpVerified = $record && ! now()->greaterThan($record->expires_at);
                    } else {
                        $record = (clone $query)->where('verified', true)->first();
                        $otpVerified = $record && ! now()->greaterThan($record->expires_at);
                    }
                }

                if (! $otpVerified) {
                    return response()->json([
                        'message' => 'Please verify your new email address with a valid 6-digit OTP code before saving.',
                    ], 422);
                }

                $user->email = $newEmail;
                $user->email_verified = 1;
                $user->email_verified_at = now();
                DB::table('email_verification_codes')->where('email', $newEmail)->delete();
                $emailChanged = true;
            }
        }

        if (! $emailChanged && array_key_exists('contact_number', $validated)) {
            $existingNormPhone = self::normalizePhPhone($user->contact_number);
            $incomingNormPhone = self::normalizePhPhone($validated['contact_number']);
            if ($existingNormPhone !== '' && $incomingNormPhone !== '' && $incomingNormPhone !== $existingNormPhone) {
                $accountEmail = strtolower(trim((string) $user->email));
                $phoneOtpVerified = false;
                if (Schema::hasTable('email_verification_codes') && $accountEmail !== '') {
                    $query = DB::table('email_verification_codes')->where('email', $accountEmail);
                    if (! empty($validated['otp_code'])) {
                        $record = (clone $query)->where('code', trim($validated['otp_code']))->first();
                        $phoneOtpVerified = $record && ! now()->greaterThan($record->expires_at);
                    } else {
                        $record = (clone $query)->where('verified', true)->first();
                        $phoneOtpVerified = $record && ! now()->greaterThan($record->expires_at);
                    }
                }

                if (! $phoneOtpVerified) {
                    return response()->json([
                        'message' => 'Please verify the 6-digit security code sent to your email before changing your mobile number.',
                    ], 422);
                }

                DB::table('email_verification_codes')->where('email', $accountEmail)->delete();
            }
        }

        foreach ([
            'first_name',
            'last_name',
            'middle_initial',
            'sex',
            'contact_number',
            'province',
            'municipality',
            'barangay',
            'street',
            'house_number',
        ] as $field) {
            if (array_key_exists($field, $validated)) {
                $val = $validated[$field];
                $user->{$field} = ($val !== null && trim((string) $val) !== '') ? trim((string) $val) : null;
            }
        }

        if (array_key_exists('postal_code', $validated) && Schema::hasColumn('users', 'postal_code')) {
            $user->postal_code = $validated['postal_code'] ? trim((string) $validated['postal_code']) : null;
        }

        $explicitFullName = trim((string) ($validated['full_name'] ?? ($validated['name'] ?? '')));
        if ($explicitFullName !== '') {
            $user->name = $explicitFullName;
        } elseif (! empty($user->first_name) || ! empty($user->last_name)) {
            $user->name = trim(implode(' ', array_filter([$user->first_name, $user->middle_initial, $user->last_name])));
        }

        $user->save();

        return response()->json([
            'message' => 'Profile updated successfully.',
            'user' => self::userPayload($user->fresh()),
        ]);
    }

    public function updateAvatar(Request $request): JsonResponse
    {
        if ($request->boolean('remove')) {
            return $this->removeAvatar($request);
        }

        $user = $request->user();

        $request->validate([
            'avatar' => ['nullable', 'image', 'mimes:jpg,jpeg,png,webp', 'max:5120'],
            'avatar_data' => ['nullable', 'string'],
        ]);

        $rawBytes = null;
        $mimeType = 'image/jpeg';
        $extension = 'jpg';

        if ($file = $request->file('avatar')) {
            $rawBytes = file_get_contents($file->getRealPath());
            $detectedMime = strtolower((string) ($file->getMimeType() ?: 'image/jpeg'));
            $mimeType = in_array($detectedMime, ['image/jpg', 'image/pjpeg'], true) ? 'image/jpeg' : $detectedMime;
            $extension = match (strtolower((string) $file->getClientOriginalExtension())) {
                'png' => 'png',
                'webp' => 'webp',
                default => 'jpg',
            };
        } elseif ($request->filled('avatar_data')) {
            $dataUri = trim((string) $request->input('avatar_data'));
            if (preg_match('/^data:(image\/[a-zA-Z0-9.+-]+);base64,(.+)$/s', $dataUri, $matches)) {
                $detectedMime = strtolower($matches[1]);
                $mimeType = in_array($detectedMime, ['image/jpg', 'image/pjpeg'], true) ? 'image/jpeg' : $detectedMime;
                $decoded = base64_decode($matches[2], true);
                if ($decoded !== false && strlen($decoded) <= 5 * 1024 * 1024) {
                    $rawBytes = $decoded;
                    $extension = match ($mimeType) {
                        'image/png' => 'png',
                        'image/webp' => 'webp',
                        default => 'jpg',
                    };
                }
            }
        }

        if (! $rawBytes) {
            return response()->json(['message' => 'Please upload a valid JPG, PNG, or WEBP photo under 5 MB.'], 422);
        }

        $filename = Str::uuid()->toString().'.'.$extension;
        $relativePath = 'avatars/'.$filename;
        $directory = public_path('avatars');
        if (! is_dir($directory)) {
            @mkdir($directory, 0755, true);
        }
        @file_put_contents($directory.DIRECTORY_SEPARATOR.$filename, $rawBytes);

        try {
            if (! Schema::hasTable('uploaded_files')) {
                Schema::create('uploaded_files', function ($table) {
                    $table->id();
                    $table->string('path')->unique();
                    $table->string('mime_type', 100)->default('image/jpeg');
                    $table->longText('contents');
                    $table->timestamps();
                });
            }

            DB::table('uploaded_files')->updateOrInsert(
                ['path' => $relativePath],
                [
                    'mime_type' => $mimeType,
                    'contents' => base64_encode($rawBytes),
                    'updated_at' => now(),
                    'created_at' => now(),
                ]
            );
        } catch (\Throwable) {
            // Continue if public disk write succeeded
        }

        $previousAvatar = $user->avatar;
        $hostRoot = rtrim((string) $request->getSchemeAndHttpHost(), '/');
        $user->avatar = $hostRoot !== '' ? $hostRoot.'/avatars/'.$filename : url('/avatars/'.$filename);
        $user->save();
        self::clearStoredAvatarFiles($previousAvatar);

        return response()->json([
            'message' => 'Profile photo updated.',
            'avatar' => $user->avatar,
            'avatar_url' => $user->avatar,
            'user' => self::userPayload($user->fresh()),
        ]);
    }

    public function removeAvatar(Request $request): JsonResponse
    {
        $user = $request->user();
        self::clearStoredAvatarFiles($user->avatar);
        $user->avatar = null;
        $user->save();

        return response()->json([
            'message' => 'Profile photo removed.',
            'avatar' => null,
            'avatar_url' => null,
            'user' => self::userPayload($user->fresh()),
        ]);
    }

    public function updatePassword(Request $request): JsonResponse
    {
        $user = $request->user();

        $validated = $request->validate([
            'current_password' => ['required', 'string'],
            'new_password' => ['required', 'string', 'min:8'],
        ]);

        if (! Hash::check($validated['current_password'], (string) $user->password)) {
            return response()->json(['message' => 'Your current password is incorrect.'], 422);
        }

        if (Hash::check($validated['new_password'], (string) $user->password)) {
            return response()->json(['message' => 'Please choose a new password different from your current one.'], 422);
        }

        $user->password = Hash::make($validated['new_password']);
        $user->save();

        $currentTokenId = $user->currentAccessToken()?->id;
        $revokedCount = 0;
        if ($currentTokenId !== null) {
            $revokedCount = $user->tokens()->where('id', '!=', $currentTokenId)->delete();
        }

        return response()->json([
            'message' => 'Password updated successfully. Other active sessions were signed out.',
            'revoked_sessions' => $revokedCount,
        ]);
    }

    public function deleteProfile(Request $request): JsonResponse
    {
        $user = $request->user();

        $password = (string) ($request->input('password') ?? '');
        $confirmText = strtoupper(trim((string) ($request->input('confirm_text') ?? '')));
        $isGoogleWithoutPassword = ! empty($user->google_id) && $user->provider === 'google';

        if ($password !== '') {
            if (! Hash::check($password, (string) $user->password)) {
                return response()->json(['message' => 'Incorrect password. Account deletion cancelled.'], 422);
            }
        } elseif (! $isGoogleWithoutPassword || $confirmText !== 'DELETE') {
            return response()->json([
                'message' => 'Please enter your current password to permanently delete your account.',
            ], 422);
        }

        $email = $user->email;
        DB::transaction(function () use ($user, $email) {
            $user->tokens()->delete();
            if (Schema::hasTable('email_verification_codes')) {
                DB::table('email_verification_codes')->where('email', $email)->delete();
            }
            $user->delete();
        });

        return response()->json(['message' => 'Your Lumora account has been permanently deleted.']);
    }

    public function sessions(Request $request): JsonResponse
    {
        $user = $request->user();
        $currentTokenId = $user->currentAccessToken()?->id;

        $tokens = $user->tokens()
            ->orderByDesc('last_used_at')
            ->orderByDesc('created_at')
            ->get()
            ->map(fn ($t) => [
                'id' => (int) $t->id,
                'name' => (string) ($t->name ?: 'Lumora Device'),
                'is_current' => $currentTokenId !== null && (int) $t->id === (int) $currentTokenId,
                'last_used_at' => $t->last_used_at?->toIso8601String(),
                'created_at' => $t->created_at?->toIso8601String(),
            ])
            ->values();

        return response()->json(['data' => $tokens]);
    }

    public function revokeSession(Request $request, string $id): JsonResponse
    {
        $user = $request->user();
        $currentTokenId = $user->currentAccessToken()?->id;

        if ($id === 'others') {
            $revoked = $currentTokenId !== null
                ? $user->tokens()->where('id', '!=', $currentTokenId)->delete()
                : $user->tokens()->delete();

            return response()->json([
                'message' => $revoked > 0
                    ? "Signed out of {$revoked} other device(s)."
                    : 'No other active sessions found.',
                'revoked' => $revoked,
            ]);
        }

        if (! ctype_digit($id)) {
            return response()->json(['message' => 'Invalid session identifier.'], 422);
        }

        $token = $user->tokens()->where('id', (int) $id)->first();
        if (! $token) {
            return response()->json(['message' => 'Session not found.'], 404);
        }

        $token->delete();

        return response()->json(['message' => 'Session revoked successfully.']);
    }

    private static function normalizePhPhone(?string $raw): string
    {
        $digits = preg_replace('/\D+/', '', (string) $raw) ?? '';
        if ($digits === '') {
            return '';
        }
        if (str_starts_with($digits, '63') && strlen($digits) === 12) {
            return '0'.substr($digits, 2);
        }
        if (str_starts_with($digits, '9') && strlen($digits) === 10) {
            return '0'.$digits;
        }

        return $digits;
    }

    private static function clearStoredAvatarFiles(?string $avatarUrl): void
    {
        if (! $avatarUrl || ! preg_match('/\/avatars\/([A-Za-z0-9._-]+)$/', $avatarUrl, $m)) {
            return;
        }
        $filename = basename($m[1]);
        $diskPath = public_path('avatars/'.$filename);
        if (is_file($diskPath)) {
            @unlink($diskPath);
        }
        if (Schema::hasTable('uploaded_files')) {
            DB::table('uploaded_files')->where('path', 'avatars/'.$filename)->delete();
        }
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
            'approval_status' => $user->approval_status ?? 'approved',
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
