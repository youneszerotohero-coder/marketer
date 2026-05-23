<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class WalletTransaction extends Model
{
    protected $fillable = [
        'marketer_id',
        'order_id',
        'amount',
        'type',
        'status',
        'payment_method',
        'payout_details',
        'notes',
    ];

    protected $casts = [
        'amount' => 'decimal:2',
        'payout_details' => 'array',
    ];

    public function marketer(): BelongsTo
    {
        return $this->belongsTo(User::class, 'marketer_id');
    }

    public function order(): BelongsTo
    {
        return $this->belongsTo(Order::class);
    }
}
