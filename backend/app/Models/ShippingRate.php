<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class ShippingRate extends Model
{
    protected $fillable = [
        'wilaya_code',
        'wilaya_name',
        'wilaya_name_ar',
        'home_price',
        'desk_price',
        'is_active',
        'home_active',
        'desk_active',
    ];

    protected $casts = [
        'home_price' => 'float',
        'desk_price' => 'float',
        'is_active' => 'boolean',
        'home_active' => 'boolean',
        'desk_active' => 'boolean',
    ];

    public function communes(): \Illuminate\Database\Eloquent\Relations\HasMany
    {
        return $this->hasMany(Commune::class, 'shipping_rate_id');
    }
}
