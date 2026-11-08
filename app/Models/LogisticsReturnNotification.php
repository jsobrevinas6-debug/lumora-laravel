<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class LogisticsReturnNotification extends Model
{
    public $timestamps = false;

    protected $fillable = ['status', 'processed_at'];

    protected $casts = ['created_at' => 'datetime', 'processed_at' => 'datetime'];

    public function returnRequest(): BelongsTo
    {
        return $this->belongsTo(ReturnRequest::class);
    }
}
