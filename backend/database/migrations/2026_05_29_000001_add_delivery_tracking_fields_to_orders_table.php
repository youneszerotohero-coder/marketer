<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('orders', function (Blueprint $table) {
            $table->string('delivery_current_location')->nullable()->after('delivery_status');
            $table->timestamp('delivery_last_synced_at')->nullable()->after('delivery_current_location');
        });
    }

    public function down(): void
    {
        Schema::table('orders', function (Blueprint $table) {
            $table->dropColumn(['delivery_current_location', 'delivery_last_synced_at']);
        });
    }
};
