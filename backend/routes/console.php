<?php

use App\Console\Commands\ResetPostponedOrders;
use Illuminate\Foundation\Inspiring;
use Illuminate\Support\Facades\Artisan;
use Illuminate\Support\Facades\Schedule;

Artisan::command('inspire', function () {
    $this->comment(Inspiring::quote());
})->purpose('Display an inspiring quote');

// Every night at midnight: reset "reporté" orders back to pending
Schedule::command(ResetPostponedOrders::class)->dailyAt('00:00');
Artisan::command('tracking:sync', function () {
    $service = app()->make(App\Services\Delivery\DeliveryStatusService::class);
    $orders = App\Models\Order::whereNotNull('tracking_number')->get();
    foreach ($orders as $order) {
        try {
            $service->sync($order);
        } catch (\Exception $e) {
            $this->error("Failed to sync order {$order->id}: " . $e->getMessage());
        }
    }
    $this->info('Tracking sync completed for '.count($orders).' orders.');
})->purpose('Sync parcel tracking status with ZR Express');

// Schedule the command to run every minute for real-time tracking
Schedule::command('tracking:sync')->everyMinute();
