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
