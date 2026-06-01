<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\Relations\HasOne;

class Order extends Model
{
    public const STATUS_PENDING = 'pending';
    public const STATUS_CONFIRMED = 'confirmed';
    public const STATUS_SHIPPED = 'shipped';
    public const STATUS_DELIVERED = 'delivered';
    public const STATUS_FAILED = 'failed';
    public const STATUS_CANCELLED = 'cancelled';

    protected $fillable = [
        'reference',
        'marketer_id',
        'confirmatrice_id',
        'client_name',
        'client_phone',
        'wilaya',
        'commune',
        'address',
        'subtotal',
        'shipping_fee',
        'shipping_deduction',
        'total',
        'marketer_commission',
        'status',
        'delivery_type',
        'delivery_status',
        'delivery_current_location',
        'delivery_last_synced_at',
        'tracking_number',
        'is_duplicate',
        'notes',
        'confirmed_at',
        'shipped_at',
        'delivered_at',
        'failed_at',
    ];

    protected $casts = [
        'subtotal' => 'decimal:2',
        'shipping_fee' => 'decimal:2',
        'shipping_deduction' => 'decimal:2',
        'total' => 'decimal:2',
        'marketer_commission' => 'decimal:2',
        'is_duplicate' => 'boolean',
        'confirmed_at' => 'datetime',
        'shipped_at' => 'datetime',
        'delivered_at' => 'datetime',
        'failed_at' => 'datetime',
        'delivery_last_synced_at' => 'datetime',
    ];

    public function marketer(): BelongsTo
    {
        return $this->belongsTo(User::class, 'marketer_id');
    }

    public function confirmatrice(): BelongsTo
    {
        return $this->belongsTo(User::class, 'confirmatrice_id');
    }

    public function items(): HasMany
    {
        return $this->hasMany(OrderItem::class);
    }

    public function commissionTransaction(): HasOne
    {
        return $this->hasOne(WalletTransaction::class)->where('type', 'commission');
    }

    public function returnFeeTransaction(): HasOne
    {
        return $this->hasOne(WalletTransaction::class)->where('type', 'return_fee');
    }

    public function deliveryShipment(): HasOne
    {
        return $this->hasOne(DeliveryShipment::class)->latestOfMany();
    }

    public function walletTransactions(): HasMany
    {
        return $this->hasMany(WalletTransaction::class);
    }

    protected static function booted()
    {
        static::updated(function (Order $order) {
            $inactiveStatuses = [self::STATUS_CANCELLED, self::STATUS_FAILED];
            
            if ($order->isDirty('status')) {
                $oldStatus = $order->getOriginal('status');
                $newStatus = $order->status;
                
                $wasInactive = in_array($oldStatus, $inactiveStatuses);
                $isInactive = in_array($newStatus, $inactiveStatuses);
                
                if (!$wasInactive && $isInactive) {
                    foreach ($order->items as $item) {
                        if ($item->variant) {
                            $item->variant->increment('stock', $item->quantity);
                        }
                    }
                } elseif ($wasInactive && !$isInactive) {
                    foreach ($order->items as $item) {
                        if ($item->variant) {
                            $item->variant->decrement('stock', $item->quantity);
                        }
                    }
                }
            }
        });
    }
}
