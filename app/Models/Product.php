<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

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
}
