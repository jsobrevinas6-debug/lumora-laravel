<?php

namespace App\Notifications;

class UserDeactivatedNotification extends UserAccountStatusNotification
{
    protected function subject(): string { return 'Deactivated'; }
}
