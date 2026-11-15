<?php

namespace App\Services;

use App\Models\User;
use App\Models\UserStatusLog;
use App\Notifications\UserReactivatedNotification;
use Illuminate\Support\Facades\DB;

class UserAccountStatusService
{
    public function loginBlockMessage(User $user): string
    {
        $log = $user->statusLogs()->first();
        $message = $user->status === 'deactivated'
            ? 'This account has been deactivated.'
            : 'This account has been suspended.';

        if ($log?->reason) $message .= ' Reason: '.ucfirst(str_replace('_', ' ', $log->reason)).'.';
        if ($log?->note) $message .= ' '.$log->note;
        if ($user->status === 'suspended') {
            $message .= $user->suspended_until
                ? ' Access is expected to be restored on '.$user->suspended_until->format('M j, Y g:i A').'.'
                : ' Contact Lumora support for more information.';
        }

        return $message;
    }

    public function liftExpiredSuspensions(): int
    {
        return DB::transaction(function (): int {
            $expiredUsers = User::query()
                ->where('status', 'suspended')
                ->whereNotNull('suspended_until')
                ->where('suspended_until', '<=', now())
                ->lockForUpdate()
                ->get();

            foreach ($expiredUsers as $user) {
                $until = $user->suspended_until;
                $user->forceFill(['status' => 'active', 'suspended_until' => null])->save();
                UserStatusLog::create([
                    'user_id' => $user->id,
                    'admin_id' => null,
                    'action' => 'auto_lifted',
                    'reason' => 'Suspension period expired',
                    'until' => $until,
                    'created_at' => now(),
                ]);
                DB::afterCommit(fn () => $user->notify(new UserReactivatedNotification(
                    'Suspension period expired',
                    'Your temporary suspension period has ended, and your account is active again.',
                )));
            }

            return $expiredUsers->count();
        });
    }
}
