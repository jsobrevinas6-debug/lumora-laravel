<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\Relations\HasOne;

class ReturnRequest extends Model
{
    protected $fillable = [
        'buyer_id',
        'reason',
        'preferred_solution',
        'details',
        'status',
        'dispute_status',
        'disputed_at',
        'dispute_notes',
        'admin_note',
        'reviewed_at',
        'resolved_by',
        'refund_amount',
        'refund_status',
        'refunded_at',
    ];

    protected $casts = [
        'reviewed_at' => 'datetime',
        'disputed_at' => 'datetime',
        'refunded_at' => 'datetime',
        'refund_amount' => 'decimal:2',
    ];

    public function order(): BelongsTo
    {
        return $this->belongsTo(Order::class);
    }

    public function buyer(): BelongsTo
    {
        return $this->belongsTo(User::class, 'buyer_id');
    }

    public function resolver(): BelongsTo
    {
        return $this->belongsTo(User::class, 'resolved_by');
    }

    public function evidence(): HasMany
    {
        return $this->hasMany(ReturnRequestEvidence::class);
    }

    public function logisticsNotification(): HasOne
    {
        return $this->hasOne(LogisticsReturnNotification::class);
    }
}
