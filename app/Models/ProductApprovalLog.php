<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class ProductApprovalLog extends Model
{
    public $timestamps = false;

    protected $fillable = ['product_id', 'admin_id', 'action', 'note', 'created_at'];

    protected $casts = ['created_at' => 'datetime'];

    public function product(): BelongsTo { return $this->belongsTo(Product::class); }

    public function admin(): BelongsTo { return $this->belongsTo(User::class, 'admin_id'); }
}
