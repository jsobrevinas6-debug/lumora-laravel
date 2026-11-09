<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Support\Facades\DB;

class Order extends Model
{
    use HasFactory;

    protected $fillable = [
        'order_number',
        'user_id',
        'buyer_id',
        'seller_id',
        'status',
        'payment_status',
        'payment_method',
        'payment_method_id',
        'payment_proof_path',
        'payment_reference_last6',
        'subtotal',
        'shipping_fee',
        'discount',
        'voucher_code',
        'voucher_type',
        'voucher_discount',
        'shipping_discount',
        'total',
        'tracking_number',
        'courier',
        'estimated_delivery',
        'delivered_at',
        'cancelled_at',
        'notes',
    ];

    protected $casts = [
        'estimated_delivery' => 'datetime',
        'delivered_at' => 'datetime',
        'cancelled_at' => 'datetime',
        'subtotal' => 'decimal:2',
        'shipping_fee' => 'decimal:2',
        'discount' => 'decimal:2',
        'total' => 'decimal:2',
    ];

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    public function seller(): BelongsTo
    {
        return $this->belongsTo(User::class, 'seller_id');
    }

    public function paymentMethod(): BelongsTo
    {
        return $this->belongsTo(PaymentMethod::class);
    }

    public function items(): HasMany
    {
        return $this->hasMany(OrderItem::class);
    }

    public function statusHistories(): HasMany
    {
        return $this->hasMany(OrderStatusHistory::class)->orderByDesc('created_at')->orderByDesc('id');
    }

    /** Backwards-compatible relation name used by the mobile API. */
    public function statusHistory(): HasMany
    {
        return $this->statusHistories();
    }

    /**
     * Set the order's current status and append the matching tracking event atomically.
     * Extra event metadata may include tracking_status, tracking_label, courier_name, and changed_by.
     */
    public function updateStatus(string $status, ?string $note = null, ?string $location = null, array $event = []): self
    {
        return DB::transaction(function () use ($status, $note, $location, $event) {
            $order = static::query()->lockForUpdate()->findOrFail($this->getKey());
            $status = strtolower(trim($status));

            if ($order->status !== $status) {
                $order->status = $status;

                if ($status === 'delivered' && ! $order->delivered_at) {
                    $order->delivered_at = now();
                }
                if ($status === 'cancelled' && ! $order->cancelled_at) {
                    $order->cancelled_at = now();
                }

                $order->save();
            }

            $order->statusHistories()->create([
                'status' => $status,
                'note' => $note,
                'location' => $location,
                'tracking_status' => $event['tracking_status'] ?? null,
                'tracking_label' => $event['tracking_label'] ?? null,
                'courier_name' => $event['courier_name'] ?? null,
                'changed_by' => $event['changed_by'] ?? null,
            ]);

            $this->setRawAttributes($order->getAttributes(), true);

            return $this;
        });
    }

    /** Record a tracking event that does not change the order's lifecycle status (for example, a dispute). */
    public function recordStatusUpdate(string $status, ?string $note = null, ?string $location = null, array $event = []): OrderStatusHistory
    {
        return $this->statusHistories()->create([
            'status' => $status,
            'note' => $note,
            'location' => $location,
            'tracking_status' => $event['tracking_status'] ?? null,
            'tracking_label' => $event['tracking_label'] ?? null,
            'courier_name' => $event['courier_name'] ?? null,
            'changed_by' => $event['changed_by'] ?? null,
        ]);
    }

    public function returnRequest(): \Illuminate\Database\Eloquent\Relations\HasOne
    {
        return $this->hasOne(ReturnRequest::class);
    }

    public function isPending(): bool
    {
        return $this->status === 'pending';
    }

    public function isProcessing(): bool
    {
        return $this->status === 'processing';
    }

    public function isPacked(): bool
    {
        return $this->status === 'packed';
    }

    public function isShipped(): bool
    {
        return $this->status === 'shipped';
    }

    public function isOutForDelivery(): bool
    {
        return $this->status === 'out_for_delivery';
    }

    public function isDelivered(): bool
    {
        return $this->status === 'delivered';
    }

    public function isCancelled(): bool
    {
        return $this->status === 'cancelled';
    }

    public function isReturned(): bool
    {
        return $this->status === 'returned';
    }

    public function getStatusLabelAttribute(): string
    {
        return match ($this->status) {
            'pending' => 'Pending',
            'processing' => 'Processing',
            'packed' => 'Packed',
            'shipped' => 'Shipped',
            'out_for_delivery' => 'Out for Delivery',
            'delivered' => 'Delivered',
            'cancelled' => 'Cancelled',
            'returned' => 'Returned',
            default => ucfirst(str_replace('_', ' ', $this->status)),
        };
    }

    public function getStatusBadgeClassAttribute(): string
    {
        return match ($this->status) {
            'pending' => 'bg-[#F7EBDD] text-[#9A6A3A]',
            'processing' => 'bg-[#F6E3D8] text-[#9A5B3F]',
            'packed' => 'bg-[#EFE7DA] text-[#7A5C3E]',
            'shipped' => 'bg-[#EEEAF5] text-[#5E4B7A]',
            'out_for_delivery' => 'bg-[#F3E6EA] text-[#3B1E34]',
            'delivered' => 'bg-[#E8F0EA] text-[#6F8F78]',
            'cancelled' => 'bg-[#F6DDDD] text-[#A55252]',
            'returned' => 'bg-[#EAE3DD] text-[#8B7B78]',
            default => 'bg-[#EAE3DD] text-[#8B7B78]',
        };
    }
}
