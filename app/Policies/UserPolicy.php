<?php

namespace App\Policies;

use App\Models\User;

class UserPolicy
{
    public function viewIdentityDocument(User $admin, User $subject): bool
    {
        return $admin->role === 'admin' && $subject->role === 'buyer';
    }
}
