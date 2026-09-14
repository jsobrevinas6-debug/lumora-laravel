<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

class Product extends Model
{
    use HasFactory;

    protected $fillable = [
        'seller_id',
        'name',
        'category',
        'description',
        'price',
        'discount_percent',
        'sales_count',
        'rating',
        'stock',
        'variant_type',
        'image',
        'status',
        'category',
    ];

    protected $casts = [
        'price' => 'decimal:2',
        'discount_percent' => 'decimal:1',
        'stock' => 'integer',
        'sales_count' => 'integer',
        'rating' => 'decimal:2',
    ];

    public function seller(): BelongsTo
    {
        return $this->belongsTo(User::class, 'seller_id');
    }

    public function reviews(): HasMany
    {
        return $this->hasMany(ProductReview::class);
    }

    public function getAverageRatingAttribute(): float
    {
        $rating = $this->reviews_avg_rating ?? $this->reviews()->avg('rating');

        return round((float) $rating, 1);
    }

    public function getReviewCountAttribute(): int
    {
        return (int) ($this->reviews_count ?? $this->reviews()->count());
    }
}
