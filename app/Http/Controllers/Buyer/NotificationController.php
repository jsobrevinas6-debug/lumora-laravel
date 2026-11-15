<?php

namespace App\Http\Controllers\Buyer;

use App\Http\Controllers\Controller;
use Illuminate\Http\RedirectResponse;
use Illuminate\Support\Facades\Auth;

class NotificationController extends Controller
{
    public function markRead(string $notification): RedirectResponse
    {
        $ownedNotification = Auth::user()->notifications()->whereKey($notification)->firstOrFail();
        $ownedNotification->markAsRead();

        return back();
    }

    public function markAllRead(): RedirectResponse
    {
        Auth::user()->unreadNotifications()->update(['read_at' => now()]);

        return back();
    }
}
