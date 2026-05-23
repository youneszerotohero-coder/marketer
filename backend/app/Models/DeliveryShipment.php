<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class DeliveryShipment extends Model
{
    protected $fillable = [
        'order_id',
        'provider',
        'external_id',
        'tracking_number',
        'status',
        'payload',
        'last_synced_at',
    ];

    protected $casts = [
        'payload' => 'array',
        'last_synced_at' => 'datetime',
    ];

    public function order(): BelongsTo
    {
        return $this->belongsTo(Order::class);
    }
}
