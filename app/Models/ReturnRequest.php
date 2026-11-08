<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\Relations\HasOne;

class ReturnRequest extends Model
{
    protected $fillable = ['buyer_id', 'reason', 'details', 'status'];

    public function order(): BelongsTo
    {
        return $this->belongsTo(Order::class);
    }

    public function buyer(): BelongsTo
    {
        return $this->belongsTo(User::class, 'buyer_id');
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
