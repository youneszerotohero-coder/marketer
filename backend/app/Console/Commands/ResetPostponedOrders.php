<?php

namespace App\Console\Commands;

use App\Models\Order;
use Illuminate\Console\Command;
use Illuminate\Support\Facades\Log;

class ResetPostponedOrders extends Command
{
    protected $signature = 'orders:reset-postponed';

    protected $description = 'Reset postponed (reporté) orders back to pending when their postpone date has passed.';

    public function handle(): void
    {
        $count = Order::where('status', Order::STATUS_REPORTE)
            ->whereNotNull('postponed_until')
            ->where('postponed_until', '<=', now())
            ->update([
                'status' => Order::STATUS_PENDING,
                'postponed_until' => null,
            ]);

        Log::info("[ResetPostponedOrders] {$count} order(s) reset from 'reporte' to 'pending'.");
        $this->info("{$count} order(s) reset to pending.");
    }
}
