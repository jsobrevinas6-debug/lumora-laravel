<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Str;

class Product extends Model
{
    use HasFactory;

    public const PLACEHOLDER_IMAGE_PATH = 'images/product-placeholder.png';

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

    public static function placeholderImageUrl(): string
    {
        return asset(self::PLACEHOLDER_IMAGE_PATH);
    }

    public static function normalizeImagePath(?string $value): ?string
    {
        if (blank($value)) {
            return null;
        }

        $path = trim(str_replace('\\', '/', $value));

        if (Str::startsWith($path, ['http://', 'https://'])) {
            if (! self::isAppUrl($path)) {
                return null;
            }

            $path = parse_url($path, PHP_URL_PATH) ?: '';
        }

        $path = ltrim($path, '/');

        foreach (['storage/app/public/', 'public/storage/', 'storage/'] as $prefix) {
            $position = stripos($path, $prefix);

            if ($position !== false) {
                $path = substr($path, $position + strlen($prefix));
                break;
            }
        }

        if (preg_match('/^[A-Za-z]:\//', $path) || Str::startsWith($path, ['//', '../'])) {
            return null;
        }

        return blank($path) ? null : $path;
    }

    public function getImageUrlAttribute(): string
    {
        if (blank($this->image)) {
            return self::placeholderImageUrl();
        }

        $value = trim((string) $this->image);

        if (Str::startsWith($value, ['http://', 'https://']) && ! self::isAppUrl($value)) {
            return $value;
        }

        $path = self::normalizeImagePath($value);

        if ($path && Storage::disk('public')->exists($path)) {
            $url = Storage::disk('public')->url($path);

            return Str::startsWith($url, ['http://', 'https://'])
                ? $url
                : asset($url);
        }

        $publicCandidates = array_filter(array_unique([
            ltrim($value, '/'),
            $path,
            $path ? 'storage/'.$path : null,
        ]));

        foreach ($publicCandidates as $publicPath) {
            if (file_exists(public_path($publicPath))) {
                return asset($publicPath);
            }
        }

        return self::placeholderImageUrl();
    }

    public function imageDiskPath(): ?string
    {
        $path = self::normalizeImagePath($this->image);

        return $path ? Storage::disk('public')->path($path) : null;
    }

    public function imageExists(): bool
    {
        $path = self::normalizeImagePath($this->image);

        return (bool) $path
            && (Storage::disk('public')->exists($path) || file_exists(public_path('storage/'.$path)));
    }

    private static function isAppUrl(string $url): bool
    {
        $host = parse_url($url, PHP_URL_HOST);

        if (! $host) {
            return false;
        }

        $appHost = parse_url((string) config('app.url'), PHP_URL_HOST);
        $requestHost = request()?->getHost();

        return in_array($host, array_filter([
            'localhost',
            '127.0.0.1',
            '::1',
            $appHost,
            $requestHost,
        ]), true);
    }

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
