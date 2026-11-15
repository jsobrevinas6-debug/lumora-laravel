<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class UserStatusLog extends Model
{
    public const UPDATED_AT = null;

    protected $fillable = ['user_id', 'admin_id', 'action', 'reason', 'note', 'until', 'created_at'];

    protected $casts = ['until' => 'datetime', 'created_at' => 'datetime'];

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    public function admin(): BelongsTo
    {
        return $this->belongsTo(User::class, 'admin_id');
    }
}
