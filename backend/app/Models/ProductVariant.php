<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\BelongsToMany;

class ProductVariant extends Model
{
    protected $fillable = [
        'product_id',
        'sku',
        'purchase_price',
        'sale_price',
        'commission_value',
        'commission_type',
        'stock',
        'image_path',
        'status',
    ];

    protected $casts = [
        'purchase_price' => 'decimal:2',
        'sale_price' => 'decimal:2',
        'commission_value' => 'decimal:2',
    ];

    public function product(): BelongsTo
    {
        return $this->belongsTo(Product::class);
    }

    public function values(): BelongsToMany
    {
        return $this->belongsToMany(AttributeValue::class, 'product_variant_values');
    }

    public function commissionFor(int $quantity): float
    {
        $value = (float) $this->commission_value;
        $unit = $this->commission_type === 'percent'
            ? ((float) $this->sale_price * $value / 100)
            : $value;

        return round($unit * $quantity, 2);
    }
}
