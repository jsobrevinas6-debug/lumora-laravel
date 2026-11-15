<?php

namespace App\Notifications;

class UserSuspendedNotification extends UserAccountStatusNotification
{
    protected function subject(): string { return 'Suspended'; }
}
