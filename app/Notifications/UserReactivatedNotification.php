<?php

namespace App\Notifications;

class UserReactivatedNotification extends UserAccountStatusNotification
{
    protected function subject(): string { return 'Reactivated'; }
}
