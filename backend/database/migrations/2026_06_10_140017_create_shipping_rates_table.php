<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        Schema::create('shipping_rates', function (Blueprint $table) {
            $table->id();
            $table->string('wilaya_code')->unique();
            $table->string('wilaya_name');
            $table->string('wilaya_name_ar');
            $table->decimal('home_price', 12, 2)->default(0);
            $table->decimal('desk_price', 12, 2)->default(0);
            $table->boolean('is_active')->default(true);
            $table->boolean('home_active')->default(true);
            $table->boolean('desk_active')->default(true);
            $table->timestamps();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('shipping_rates');
    }
};
